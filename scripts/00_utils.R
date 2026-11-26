# ============================================================================
# Trustee Status and the Cost of Railway Capital: Shared Helpers
# Sourced by every script in the pipeline. Defines paths, constants, the
# figure theme, and small formatting / table-writing functions.
# ============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
  library(ggplot2)
})

# ============================================================================
# PATHS (all relative to the project root)
# ============================================================================

RAW_RAILWAYS  <- "data/raw/Railways_new.csv"   # IMM original railway records
RAW_TOTAL     <- "data/raw/Totaldata.csv"      # IMM cleaned subset (names, ISO, gov. bonds)
DERIVED_DIR   <- "data/derived"
dir.create(DERIVED_DIR, showWarnings = FALSE, recursive = TRUE)

# Outputs are split as in the paper: descriptive exhibits vs. regression results.
# Each output-writing script calls use_output("exhibits") or use_output("results").
TABLE_DIR  <- "output/exhibits/tables"
FIGURE_DIR <- "output/exhibits/figures"
use_output <- function(section = c("exhibits", "results")) {
  section <- match.arg(section)
  TABLE_DIR  <<- file.path("output", section, "tables")
  FIGURE_DIR <<- file.path("output", section, "figures")
  for (d in c(TABLE_DIR, FIGURE_DIR)) dir.create(d, showWarnings = FALSE, recursive = TRUE)
  invisible(section)
}

# ============================================================================
# INSTITUTIONAL CONSTANTS
# ============================================================================

CUTOFF        <- 3      # Trustee Act 1893 s.1(g): >= 3% p.a. on ordinary stock ...
WINDOW_YEARS  <- 10     # ... in each of the ten years before the investment
MIN_OBS_YEARS <- 8      # years of dividend data required to compute the running variable

PRE_YEARS     <- 1879:1887   # before the 1888-89 trustee-investment reforms (placebo regime)
POST_YEARS    <- 1894:1913   # after the Trustee Act 1893, before wartime state control
SENIOR_CLASSES <- c("debenture", "rentcharge", "guaranteed", "preference")

# ============================================================================
# SMALL HELPERS
# ============================================================================

to_num <- function(x) suppressWarnings(as.numeric(x))

print_header <- function(text, char = "=") {
  cat("\n", strrep(char, 78), "\n", text, "\n", strrep(char, 78), "\n", sep = "")
}

# Format numbers for LaTeX tables
fmt  <- function(x, d = 2) ifelse(is.na(x), "", formatC(x, format = "f", digits = d, big.mark = ","))
fmti <- function(x) ifelse(is.na(x), "", formatC(x, format = "d", big.mark = ","))
stars <- function(p) fcase(is.na(p), "", p < 0.01, "$^{***}$", p < 0.05, "$^{**}$", p < 0.10, "$^{*}$", default = "")

# Write a LaTeX tabular fragment (booktabs) from a character matrix; notes -> <file>_notes.tex
write_tex_table <- function(body, header, file, align = NULL, notes = NULL) {
  ncol <- length(header)
  if (is.null(align)) align <- paste0("l", strrep("c", ncol - 1))
  lines <- c(sprintf("\\begin{tabular}{%s}", align), "\\toprule",
             paste(paste(header, collapse = " & "), "\\\\"), "\\midrule")
  for (i in seq_len(nrow(body))) {
    row <- body[i, ]
    if (identical(row[1], "\\midrule")) { lines <- c(lines, "\\midrule"); next }
    lines <- c(lines, paste(paste(row, collapse = " & "), "\\\\"))
  }
  lines <- c(lines, "\\bottomrule", "\\end{tabular}")
  writeLines(lines, file.path(TABLE_DIR, file))
  # Notes go in a companion file so a wide tabular can be scaled without the notes
  if (!is.null(notes)) writeLines(notes, file.path(TABLE_DIR, sub("\\.tex$", "_notes.tex", file)))
  invisible(lines)
}

# ============================================================================
# FIGURE THEME (consistent across all figures; colorblind-safe palette)
# ============================================================================

PAL <- c(navy = "#1F3B73", orange = "#D55E00", teal = "#009E73",
         grey = "#7F7F7F", sky = "#56B4E9", purple = "#8E5EA2")

theme_paper <- function(base = 10) {
  theme_minimal(base_size = base) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = "grey90", linewidth = 0.3),
          axis.line = element_line(colour = "grey30", linewidth = 0.3),
          axis.ticks = element_line(colour = "grey30", linewidth = 0.3),
          legend.position = "bottom", legend.title = element_blank(),
          plot.title = element_blank(), strip.text = element_text(face = "bold"))
}

save_fig <- function(p, name, w = 6.5, h = 4) {
  ggsave(file.path(FIGURE_DIR, paste0(name, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(FIGURE_DIR, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
}

# ============================================================================
# WILD CLUSTER BOOTSTRAP (restricted, Webb six-point weights)
# ----------------------------------------------------------------------------
# With roughly 10-25 company clusters near the cutoff, cluster-robust t-tests
# over-reject (Cameron, Gelbach & Miller 2008). This imposes H0: beta_j = 0,
# resamples residuals with cluster-level Webb weights, and returns the bootstrap
# p-value of the CR1 t-statistic. `X` must include the intercept/fixed-effect
# dummies; `j` is the column of the tested coefficient.
# ============================================================================

wild_cluster_p <- function(y, X, cluster, j, B = 999, seed = 117) {
  set.seed(seed)
  keep <- complete.cases(y, X, cluster); y <- y[keep]; X <- X[keep, , drop = FALSE]; cl <- as.factor(cluster[keep])
  X <- X[, qr(X)$pivot[seq_len(qr(X)$rank)], drop = FALSE]            # drop collinear dummies
  if (!(j %in% colnames(X))) return(NA_real_)
  t_stat <- function(yy) {
    fit <- lm.fit(X, yy); e <- fit$residuals
    XtXi <- chol2inv(qr.R(qr(X)))
    S <- rowsum(X * e, cl); G <- nlevels(cl); n <- nrow(X); k <- ncol(X)
    V <- XtXi %*% crossprod(S) %*% XtXi * (G / (G - 1)) * ((n - 1) / (n - k))
    jj <- match(j, colnames(X))
    fit$coefficients[jj] / sqrt(V[jj, jj])
  }
  t0 <- t_stat(y)
  Xr <- X[, colnames(X) != j, drop = FALSE]
  fr <- lm.fit(Xr, y); yhat_r <- y - fr$residuals; e_r <- fr$residuals
  webb <- c(-sqrt(1.5), -1, -sqrt(0.5), sqrt(0.5), 1, sqrt(1.5))
  tb <- replicate(B, { w <- sample(webb, nlevels(cl), replace = TRUE)[as.integer(cl)]; t_stat(yhat_r + e_r * w) })
  mean(abs(tb) >= abs(t0))
}

# ============================================================================
# NUMBERS FOR THE PAPER
# ----------------------------------------------------------------------------
# Each script writes the statistics quoted in the text as LaTeX macros
# (output/tables/macros_<step>.tex), so no number in the paper is typed by hand.
# ============================================================================

macro_env <- new.env()
set_macro <- function(name, value) assign(name, value, envir = macro_env)
write_macros <- function(step) {
  nm <- ls(macro_env)
  lines <- sprintf("\\newcommand{\\%s}{%s}", nm, vapply(nm, function(n) as.character(get(n, envir = macro_env)), ""))
  writeLines(lines, file.path(TABLE_DIR, paste0("macros_", step, ".tex")))
  rm(list = nm, envir = macro_env)
}
