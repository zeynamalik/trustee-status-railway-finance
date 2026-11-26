# ============================================================================
# STEP 4: Descriptive exhibits
# ----------------------------------------------------------------------------
# Tables : table1_sample_flow.tex, table2_summary_stats.tex, table_a1_yield_gap_nw.tex
# Figures: fig1_dividend_histories, fig2_dividend_bunching, fig3_running_variable,
#          fig4_yield_gap
# ============================================================================

source("scripts/00_utils.R")
use_output("exhibits")
suppressPackageStartupMessages(library(sandwich))
print_header("STEP 4: DESCRIPTIVE EXHIBITS")

senior <- readRDS(file.path(DERIVED_DIR, "analysis_senior.rds"))
cy     <- readRDS(file.path(DERIVED_DIR, "company_year.rds"))
flow   <- readRDS(file.path(DERIVED_DIR, "sample_flow.rds"))
cy[, at_stake := as.integer(!is.na(min9) & min9 >= CUTOFF)]
cyx <- cy[excluded == FALSE]

# ============================================================================
# TABLE 1: SAMPLE CONSTRUCTION
# ============================================================================

lg <- flow$log
top <- data.table(step = c("IMM railway security-months, 1869-1929",
                           "British and Irish railway security-months",
                           "Security-years (all security types)"),
                  N = c(lg$raw_records, lg$british_records, lg$sec_years),
                  companies = c(NA, lg$british_companies, NA))
t1 <- rbind(top, flow$flow)
body <- cbind(gsub("^  ", "\\\\quad ", t1$step), fmti(t1$N), fmti(t1$companies))
write_tex_table(body, c("Sample restriction", "Observations", "Companies"), "table1_sample_flow.tex",
                align = "lrr",
                notes = paste("Observations are security-months in the first two rows and security-years thereafter.",
                              "Senior securities are debenture, rentcharge, guaranteed and preference stock.",
                              "Excluded companies are foreign lines registered in London, the Isle of Man, and lines",
                              "leased, jointly owned or worked under a guarantee (config/company\\_exclusions.csv)."))
cat("Table 1 written.\n")

# ============================================================================
# TABLE 2: SUMMARY STATISTICS, POST-1893 REGIME
# ============================================================================

post <- senior[period == "post"]
groups <- list(`All` = post, `Eligible` = post[eligible == 1], `Not eligible` = post[eligible == 0],
               `Eligible, |X|$\\le$1` = post[eligible == 1 & abs(X) <= 1],
               `Not eligible, |X|$\\le$1` = post[eligible == 0 & abs(X) <= 1])
stat_rows <- list(
  "Current yield (\\%)"                    = function(d) fmt(mean(d$yield, na.rm = TRUE)),
  "Yield relative to market (bp)"          = function(d) fmt(mean(d$rel_bp, na.rm = TRUE), 1),
  "\\quad (standard deviation)"            = function(d) fmt(sd(d$rel_bp, na.rm = TRUE), 1),
  "Coupon / fixed dividend (\\%)"          = function(d) fmt(mean(d$coupon, na.rm = TRUE)),
  "Nominal amount (GBP m)"                 = function(d) fmt(mean(d$capital, na.rm = TRUE) / 1e6),
  "Share debenture or rentcharge"          = function(d) fmt(mean(d$sec_class %in% c("debenture", "rentcharge"))),
  "Share preference"                       = function(d) fmt(mean(d$sec_class == "preference")),
  "Share guaranteed"                       = function(d) fmt(mean(d$sec_class == "guaranteed")),
  "Irish company"                          = function(d) fmt(mean(d$irish)),
  "Ordinary dividend, year $t-1$ (\\%)"    = function(d) fmt(mean(d$div_lag1, na.rm = TRUE)),
  "Ten-year minimum dividend (\\%)"        = function(d) fmt(mean(d$min10, na.rm = TRUE)),
  "Security-years"                         = function(d) fmti(nrow(d)),
  "Securities"                             = function(d) fmti(uniqueN(d$id)),
  "Companies"                              = function(d) fmti(uniqueN(d$company)))
body <- do.call(rbind, lapply(names(stat_rows), function(r) c(r, sapply(groups, stat_rows[[r]]))))
write_tex_table(body, c("", names(groups)), "table2_summary_stats.tex", align = "lccccc",
                notes = paste("Senior railway security-years, 1894--1913. Eligible: the company paid at least 3\\% on its",
                              "ordinary stock in each of the previous ten years. $X$ is the ten-year minimum dividend minus 3.",
                              "Yield relative to market is the security's current yield minus the median current yield of all",
                              "British senior railway securities in the same month, in basis points, averaged over the year."))
cat("Table 2 written.\n")

# ============================================================================
# FIGURE 1: DIVIDEND HISTORIES AND TRUSTEE ELIGIBILITY FOR SIX COMPANIES
# ============================================================================

show <- c("Caledonian Railway Co. Inc.", "Great Eastern Railway Co.", "North Staffordshire Railway Co.",
          "South-Eastern Railway", "Metropolitan Railways Co. Ltd.", "Glasgow and South-Western Railway")
f1 <- cy[company %in% show & year %between% c(1879, 1922)]
f1[, label := factor(sub(" (Railways?|Co\\.|Ltd\\.|Inc\\.).*$", "", company), levels = sub(" (Railways?|Co\\.|Ltd\\.|Inc\\.).*$", "", show))]
p1 <- ggplot(f1, aes(year)) +
  geom_rect(data = f1[eligible == 1], aes(xmin = year - 0.5, xmax = year + 0.5, ymin = -Inf, ymax = Inf),
            fill = PAL["sky"], alpha = 0.18, inherit.aes = FALSE) +
  geom_hline(yintercept = CUTOFF, linetype = "dashed", colour = PAL["orange"], linewidth = 0.4) +
  geom_step(aes(y = div), colour = PAL["navy"], linewidth = 0.5, direction = "mid", na.rm = TRUE) +
  geom_line(aes(y = min10), colour = PAL["grey"], linewidth = 0.4, linetype = "longdash", na.rm = TRUE) +
  facet_wrap(~label, ncol = 3) +
  labs(x = NULL, y = "Dividend on ordinary stock (% p.a.)") + theme_paper(9)
save_fig(p1, "fig1_dividend_histories", w = 7, h = 4.2)
cat("Figure 1 written.\n")

# ============================================================================
# FIGURE 2: DIVIDEND BUNCHING AT 3% WHEN THE TRUSTEE RECORD IS AT STAKE
# ============================================================================

f2 <- cyx[!is.na(div) & !is.na(min9) & div >= 1.5 & div < 5 &
          (year %in% POST_YEARS | year %in% PRE_YEARS)]
f2[, regime := factor(fifelse(year %in% POST_YEARS, "1894-1913 (3% rule in force)", "1879-1887 (no rule)"),
                      levels = c("1879-1887 (no rule)", "1894-1913 (3% rule in force)"))]
f2[, stake := factor(fifelse(at_stake == 1, "Record at stake", "Record already broken"),
                     levels = c("Record already broken", "Record at stake"))]
f2[, bin := floor(div * 4) / 4]
p2 <- ggplot(f2[, .N, by = .(regime, stake, bin)], aes(bin + 0.125, N, fill = bin >= CUTOFF)) +
  geom_col(width = 0.23) +
  geom_vline(xintercept = CUTOFF, linetype = "dashed", colour = PAL["orange"], linewidth = 0.4) +
  scale_fill_manual(values = c(`FALSE` = unname(PAL["grey"]), `TRUE` = unname(PAL["navy"])), guide = "none") +
  facet_grid(stake ~ regime, scales = "free_y") +
  labs(x = "Dividend paid on ordinary stock in year t (% p.a., 0.25-point bins)", y = "Company-years") +
  theme_paper(9)
save_fig(p2, "fig2_dividend_bunching", w = 7, h = 4.6)
cat("Figure 2 written.\n")

# ============================================================================
# FIGURE 3: DISTRIBUTION OF THE RUNNING VARIABLE
# ============================================================================

f3 <- cyx[!is.na(X) & year %in% POST_YEARS & abs(X) <= 2]
p3 <- ggplot(f3, aes(X, fill = X >= 0)) +
  geom_histogram(binwidth = 0.125, boundary = 0, colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = PAL["orange"], linewidth = 0.4) +
  scale_fill_manual(values = c(`FALSE` = unname(PAL["grey"]), `TRUE` = unname(PAL["navy"])), guide = "none") +
  labs(x = "Running variable X: ten-year minimum ordinary dividend minus 3 (percentage points)",
       y = "Company-years, 1894-1913") + theme_paper(9)
save_fig(p3, "fig3_running_variable", w = 6.5, h = 3.4)
cat("Figure 3 written.\n")

# ============================================================================
# FIGURE 4 + TABLE A1: ELIGIBLE-MINUS-INELIGIBLE YIELD GAP OVER TIME
# ============================================================================
# Annual mean relative yield of senior securities of eligible vs ineligible
# companies. The gap mixes credit quality with trustee status, so it is
# descriptive; Table A1 tests for a break after the 1888-93 reforms with
# Newey-West standard errors (the gap is serially correlated).

gap <- senior[year %between% c(1879, 1913), .(rel = mean(rel_bp, na.rm = TRUE)), by = .(year, eligible)]
gapw <- dcast(gap, year ~ eligible, value.var = "rel")
setnames(gapw, c("0", "1"), c("ineligible", "eligible"))
gapw[, gap := eligible - ineligible]
p4 <- ggplot(melt(gapw, id.vars = "year", measure.vars = c("eligible", "ineligible")),
             aes(year, value, colour = variable)) +
  annotate("rect", xmin = 1887.5, xmax = 1893.5, ymin = -Inf, ymax = Inf, alpha = 0.12, fill = PAL["orange"]) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_line(linewidth = 0.6) + geom_point(size = 1) +
  scale_colour_manual(values = c(eligible = unname(PAL["navy"]), ineligible = unname(PAL["orange"])),
                      labels = c("Eligible companies (record >= 3%)", "Ineligible companies")) +
  labs(x = NULL, y = "Senior yield relative to market (bp)") + theme_paper(9)
save_fig(p4, "fig4_yield_gap", w = 6.5, h = 3.4)

gapw[, `:=`(post1893 = as.integer(year >= 1894), transition = as.integer(year %between% c(1888, 1893)))]
ts1 <- lm(gap ~ post1893 + transition, data = gapw)
nw  <- sqrt(diag(NeweyWest(ts1, lag = 2, prewhite = FALSE)))
ols <- sqrt(diag(vcov(ts1)))
tab <- data.table(term = c("Constant (1879--1887 mean gap)", "1894--1913", "1888--1893 (transition)"),
                  b = coef(ts1), se_ols = ols, se_nw = nw)
body <- cbind(tab$term, fmt(tab$b, 1), paste0("(", fmt(tab$se_ols, 1), ")"), paste0("[", fmt(tab$se_nw, 1), "]"))
body <- rbind(body, c("Years", fmti(nobs(ts1)), "", ""))
write_tex_table(body, c("", "Coefficient", "OLS s.e.", "Newey--West s.e."), "table_a1_yield_gap_nw.tex",
                align = "lccc",
                notes = paste("Dependent variable: annual eligible-minus-ineligible gap in mean senior yields relative to",
                              "market (bp), 1879--1913. Newey--West standard errors use two lags."))
saveRDS(list(gap = gapw, ts = tab), file.path(DERIVED_DIR, "yield_gap.rds"))
cat("Figure 4 and Table A1 written. Gap pre:", fmt(coef(ts1)[1], 1), "| change post-1893:",
    fmt(coef(ts1)[2], 1), "(NW s.e.", fmt(nw[2], 1), ")\n")
# Numbers quoted in the text
set_macro("nRaw", fmti(lg$raw_records)); set_macro("nBritRec", fmti(lg$british_records))
set_macro("nBritCos", fmti(lg$british_companies)); set_macro("nReassigned", fmti(lg$reassigned_records))
set_macro("nPostObs", fmti(nrow(post))); set_macro("nPostCos", uniqueN(post$company))
set_macro("nPostSecs", uniqueN(post$id)); set_macro("nNearObs", fmti(post[abs(X) <= 1, .N]))
set_macro("nNearCos", post[abs(X) <= 1, uniqueN(company)])
set_macro("nPreObs", fmti(senior[period == "pre", .N])); set_macro("nPreCos", senior[period == "pre", uniqueN(company)])
set_macro("nRVcos", cyx[!is.na(X), uniqueN(company)])
set_macro("gapPre", fmt(coef(ts1)[1], 0)); set_macro("gapChange", fmt(coef(ts1)[2], 0))
set_macro("gapNW", fmt(nw[2], 1))
set_macro("relSDelig", fmt(post[eligible == 1, sd(rel_bp, na.rm = TRUE)], 0))
write_macros("descriptives")
cat("\nStep 4 complete.\n")
