# ============================================================================
# STEP 5: Regression-discontinuity estimates
# ----------------------------------------------------------------------------
# Does trustee eligibility lower the yield on a railway's senior securities?
#
#   rel_bp_ict = a + tau * 1[X_ct >= 0] + b1 * X_ct + b2 * X_ct * 1[X_ct >= 0]
#                + year FE + security-class FE + e_ict,         |X_ct| <= h
#
# i = security, c = company, t = year; X = ten-year minimum ordinary dividend - 3.
# Inference: clustered by company, plus wild-cluster bootstrap p-values (few
# clusters) and rdrobust's robust bias-corrected intervals.
#
# Tables : table3_rd_main, table4_rd_validity, table5_rd_by_class
# Figures: fig5_rd_plot, fig6_bandwidth, fig7_placebo_cutoffs
# ============================================================================

source("scripts/00_utils.R")
suppressPackageStartupMessages({ library(rdrobust); library(rddensity) })
print_header("STEP 5: REGRESSION DISCONTINUITY")

senior   <- readRDS(file.path(DERIVED_DIR, "analysis_senior.rds"))
ordinary <- readRDS(file.path(DERIVED_DIR, "analysis_ordinary.rds"))
cy       <- readRDS(file.path(DERIVED_DIR, "company_year.rds"))
post <- senior[period == "post"]
pre  <- senior[period == "pre"]
B_BOOT <- 999

# ============================================================================
# HELPERS
# ============================================================================

# Local linear RD with year and class fixed effects
ll_rd <- function(d, h, y = "rel_bp", donut = 0, fe = "year + sec_class", boot = TRUE) {
  s <- d[abs(X) <= h & !(X >= 0 & X < donut) & !is.na(get(y))]
  f <- as.formula(sprintf("%s ~ eligible + X + eligible:X | %s", y, fe))
  m <- feols(f, s, cluster = ~company)
  p_wb <- NA_real_
  if (boot) {
    Xm <- model.matrix(as.formula(sprintf("~ eligible + X + eligible:X + %s",
                                          gsub("year", "factor(year)", fe))), s)
    p_wb <- wild_cluster_p(s[[y]], Xm, s$company, "eligible", B = B_BOOT)
  }
  list(b = unname(coef(m)["eligible"]), se = unname(se(m)["eligible"]), p = unname(pvalue(m)["eligible"]),
       p_wb = p_wb, n = nobs(m), h = h, gl = s[X < 0, uniqueN(company)], gr = s[X >= 0, uniqueN(company)],
       model = m, data = s)
}

# Residualise the outcome on year and class effects (for plots)
resid_fe <- function(d, y = "rel_bp") {
  m <- feols(as.formula(sprintf("%s ~ 1 | year + sec_class", y)), d)
  d[obs(m), r := resid(m)]
  d
}

# ============================================================================
# TABLE 3: MAIN ESTIMATES, 1894-1913
# ============================================================================

covs <- model.matrix(~ factor(year) + sec_class, post)[, -1]
rdr  <- rdrobust(post$rel_bp, post$X, c = 0, cluster = post$company, covs = covs,
                 kernel = "triangular", bwselect = "mserd")
h_opt <- rdr$bws[1, 1]
rdr_cl <- c(post[X < 0 & X >= -h_opt, uniqueN(company)], post[X >= 0 & X <= h_opt, uniqueN(company)])

fits <- list(ll_rd(post, 0.5), ll_rd(post, 1.0), ll_rd(post, 1.5), ll_rd(post, 1.0, donut = 0.125))
# One observation per company-year: capital-weighted mean of its senior securities
cyp <- post[!is.na(rel_bp), .(rel_bp = weighted.mean(rel_bp, fcoalesce(capital, 1)), X = first(X),
                               eligible = first(eligible)), by = .(company, year)]
fits[[5]] <- ll_rd(cyp, 1.0, fe = "year")

col <- function(f) c(fmt(f$b, 1), paste0("(", fmt(f$se, 1), ")"), fmt(f$p_wb, 3),
                     sprintf("[%s, %s]", fmt(f$b - 1.96 * f$se, 1), fmt(f$b + 1.96 * f$se, 1)),
                     fmt(f$h, 2), fmti(f$n), sprintf("%d / %d", f$gl, f$gr))
c1 <- c(fmt(rdr$coef[1], 1), paste0("(", fmt(rdr$se[3], 1), ")"), fmt(rdr$pv[3], 3),
        sprintf("[%s, %s]", fmt(rdr$ci[3, 1], 1), fmt(rdr$ci[3, 2], 1)), fmt(h_opt, 2),
        fmti(sum(rdr$N_h)), sprintf("%d / %d", rdr_cl[1], rdr_cl[2]))
body <- cbind(c("Trustee eligible", "", "$p$-value", "95\\% confidence interval", "Bandwidth $h$",
                "Observations", "Companies (left / right)"),
              c1, sapply(fits, col))
body <- rbind(body, c("Sample", "Security", "Security", "Security", "Security", "Security, donut", "Company-year"))
write_tex_table(body, c("", "(1) rdrobust", "(2)", "(3)", "(4)", "(5)", "(6)"), "table3_rd_main.tex",
                align = "lcccccc",
                notes = paste("Dependent variable: senior security yield relative to the market median, in basis points.",
                              "Sample: 1894--1913. Column (1): local linear, triangular kernel, MSE-optimal bandwidth,",
                              "year and security-class covariates; standard error, $p$-value and interval are robust",
                              "bias-corrected (Calonico, Cattaneo and Titiunik 2014). Columns (2)--(6): local linear",
                              "regression with separate slopes, uniform kernel, year and class fixed effects; standard errors",
                              "clustered by company; $p$-values from a restricted wild-cluster bootstrap with Webb weights",
                              "(999 replications). Column (5) drops company-years with a ten-year minimum of exactly 3.00",
                              "($0 \\le X < 0.125$). Column (6) averages each company's senior securities, weighted by",
                              "nominal amount, and has year fixed effects only."))
cat("Table 3 written. rdrobust:", fmt(rdr$coef[1], 1), "robust CI", fmt(rdr$ci[3, 1], 1), fmt(rdr$ci[3, 2], 1), "\n")

set_macro("rdTau",   fmt(rdr$coef[1], 1));  set_macro("rdCIlo", fmt(rdr$ci[3, 1], 1))
set_macro("rdCIhi",  fmt(rdr$ci[3, 2], 1)); set_macro("rdH",    fmt(h_opt, 2))
set_macro("rdTauHone", fmt(fits[[2]]$b, 1)); set_macro("rdSEHone", fmt(fits[[2]]$se, 1))
set_macro("rdPwbHone", fmt(fits[[2]]$p_wb, 2))
set_macro("rdCIloHone", fmt(fits[[2]]$b - 1.96 * fits[[2]]$se, 1))
set_macro("rdCIhiHone", fmt(fits[[2]]$b + 1.96 * fits[[2]]$se, 1))
set_macro("rdNHone", fmti(fits[[2]]$n)); set_macro("rdGlHone", fits[[2]]$gl); set_macro("rdGrHone", fits[[2]]$gr)
set_macro("rdTauDonut", fmt(fits[[4]]$b, 1)); set_macro("rdSEDonut", fmt(fits[[4]]$se, 1))
set_macro("rdTauCY", fmt(fits[[5]]$b, 1)); set_macro("rdSECY", fmt(fits[[5]]$se, 1))
set_macro("sdRelBand", fmt(post[abs(X) <= 1, sd(rel_bp, na.rm = TRUE)], 0))
set_macro("meanSpreadNotElig", fmt(post[abs(X) <= 1 & eligible == 0, mean(spread_bp, na.rm = TRUE)], 0))

# ============================================================================
# TABLE 4: VALIDITY - BALANCE, DENSITY, PLACEBO CUTOFFS, PRE-PERIOD, DIFF-IN-DISC
# ============================================================================

post[, `:=`(is_pref = as.integer(sec_class == "preference"),
            is_deb  = as.integer(sec_class %in% c("debenture", "rentcharge")))]
balance_vars <- c(coupon = "Coupon / fixed dividend (\\%)", log_capital = "Log nominal amount",
                  log_ord_cap = "Log ordinary capital of company", irish = "Irish company",
                  is_pref = "Preference stock", is_deb = "Debenture or rentcharge")
bal <- lapply(names(balance_vars), function(v)
  ll_rd(post, 1.0, y = v, fe = if (v %in% c("is_pref", "is_deb")) "year" else "year + sec_class"))

# Density of the running variable (company-years; McCrary-type test, Cattaneo-Jansson-Ma)
dens_x <- cy[excluded == FALSE & !is.na(X) & year %in% POST_YEARS, X]
dens   <- rddensity(dens_x, c = 0)
dens_p <- dens$test$p_jk
mass0  <- mean(dens_x == 0)

# Placebo cutoffs on one side of the true threshold
placebo <- rbindlist(lapply(c(-1, -0.5, 0.5, 1), function(c0) {
  side <- if (c0 < 0) post[X < 0] else post[X >= 0]
  side <- copy(side)[, `:=`(X = X - c0, eligible = as.integer(X - c0 >= 0))]
  f <- ll_rd(side, 0.5)
  data.table(cut = c0, b = f$b, se = f$se, p_wb = f$p_wb, n = f$n)
}))

# Pre-period and difference-in-discontinuities
pre_fit <- ll_rd(pre, 1.0)
both <- rbind(post, pre, fill = TRUE)[abs(X) <= 1]
both[, post_reg := as.integer(period == "post")]
did <- feols(rel_bp ~ eligible * X * post_reg | year + sec_class, both, cluster = ~company)
Xm  <- model.matrix(~ eligible * X * post_reg + factor(year) + sec_class, both)
did_wb <- wild_cluster_p(both$rel_bp, Xm, both$company, "eligible:post_reg", B = B_BOOT)

rowf <- function(lab, f) c(lab, fmt(f$b, 2 - (abs(f$b) > 5)), paste0("(", fmt(f$se, 2 - (abs(f$b) > 5)), ")"),
                           fmt(f$p_wb, 3), fmti(f$n))
body <- rbind(
  c("\\textit{A. Covariate balance at the cutoff ($h = 1$)}", "", "", "", ""),
  do.call(rbind, Map(rowf, paste0("\\quad ", balance_vars), bal)),
  c("\\textit{B. Density of the running variable}", "", "", "", ""),
  c("\\quad Density test (Cattaneo--Jansson--Ma), $p$-value", "", "", fmt(dens_p, 3), fmti(length(dens_x))),
  c("\\quad Share of company-years at exactly $X = 0$", fmt(mass0, 3), "", "", ""),
  c("\\textit{C. Placebo cutoffs ($h = 0.5$, one side of the true cutoff)}", "", "", "", ""),
  do.call(rbind, lapply(seq_len(nrow(placebo)), function(i)
    c(sprintf("\\quad $X = %+.1f$", placebo$cut[i]), fmt(placebo$b[i], 1), paste0("(", fmt(placebo$se[i], 1), ")"),
      fmt(placebo$p_wb[i], 3), fmti(placebo$n[i])))),
  c("\\textit{D. Before the trustee rules}", "", "", "", ""),
  rowf("\\quad RD estimate, 1879--1887 ($h = 1$)", pre_fit),
  c("\\quad Difference-in-discontinuities (1894--1913 minus 1879--1887)",
    fmt(coef(did)["eligible:post_reg"], 1), paste0("(", fmt(se(did)["eligible:post_reg"], 1), ")"),
    fmt(did_wb, 3), fmti(nobs(did))))
write_tex_table(body, c("", "Estimate", "S.E.", "$p$-value", "N"), "table4_rd_validity.tex", align = "lcccc",
                notes = paste("Panel A: local linear RD estimates ($h = 1$) with each pre-determined characteristic as the",
                              "outcome; class shares use year fixed effects only. Panel B: test of continuity of the density of",
                              "$X$ across company-years, 1894--1913; the running variable has mass points, so the test is",
                              "indicative. Panel C: the threshold is moved to a placebo value using only observations on one",
                              "side of the true cutoff. Panel D: the same specification before the 1888--1893 trustee reforms,",
                              "and the pooled difference between regimes (within $|X| \\le 1$). Standard errors clustered by",
                              "company; $p$-values from a wild-cluster bootstrap (999 replications)."))
cat("Table 4 written. Density p =", fmt(dens_p, 3), "| pre RD", fmt(pre_fit$b, 1), "| diff-in-disc",
    fmt(coef(did)["eligible:post_reg"], 1), "\n")
set_macro("densP", fmt(dens_p, 2)); set_macro("massZero", fmt(100 * mass0, 0))
set_macro("preTau", fmt(pre_fit$b, 1)); set_macro("preSE", fmt(pre_fit$se, 1))
set_macro("didTau", fmt(coef(did)["eligible:post_reg"], 1)); set_macro("didSE", fmt(se(did)["eligible:post_reg"], 1))
set_macro("didPwb", fmt(did_wb, 2))

# ============================================================================
# TABLE 5: BY SECURITY CLASS, WITH MULTIPLE-TESTING CORRECTIONS
# ============================================================================
# Family of four outcomes: three senior classes plus the ordinary-stock placebo.
# Holm (1979) step-down and Romano-Wolf (2005) step-down max-t with a pairs
# cluster bootstrap that resamples companies jointly across outcomes.

ordinary[, sec_class := factor("ordinary")]
outs <- list(`Debenture and rentcharge stock` = post[sec_class %in% c("debenture", "rentcharge")],
             `Preference stock` = post[sec_class == "preference"],
             `Guaranteed stock` = post[sec_class == "guaranteed"],
             `Ordinary stock (placebo)` = ordinary[period == "post"])
outs <- lapply(outs, function(d) d[abs(X) <= 1 & !is.na(rel_bp)])
cls_fits <- lapply(outs, function(d) ll_rd(d, 1.0, fe = "year"))
t_obs <- sapply(cls_fits, function(f) f$b / f$se)
p_cl  <- sapply(cls_fits, `[[`, "p")
p_holm <- p.adjust(p_cl, "holm")

set.seed(2026)
B_RW <- 499
comp_all <- unique(unlist(lapply(outs, `[[`, "company")))
split_outs <- lapply(outs, function(d) split(d, by = "company", keep.by = TRUE))
t_boot <- matrix(NA_real_, B_RW, length(outs))
for (b in seq_len(B_RW)) {
  draw <- sample(comp_all, length(comp_all), replace = TRUE)
  for (k in seq_along(outs)) {
    blocks <- split_outs[[k]][draw[draw %in% names(split_outs[[k]])]]
    if (length(blocks) < 4) next
    db <- rbindlist(lapply(seq_along(blocks), function(i) blocks[[i]][, company := paste0("c", i)]))
    mb <- tryCatch(feols(rel_bp ~ eligible + X + eligible:X | year, db, cluster = ~company, warn = FALSE, notes = FALSE),
                   error = function(e) NULL)
    if (!is.null(mb) && "eligible" %in% names(coef(mb)))
      t_boot[b, k] <- (coef(mb)["eligible"] - cls_fits[[k]]$b) / se(mb)["eligible"]
  }
}
# Step-down max-t
ord_k <- order(abs(t_obs), decreasing = TRUE); p_rw <- numeric(length(t_obs))
for (s in seq_along(ord_k)) {
  rem <- ord_k[s:length(ord_k)]
  maxt <- apply(abs(t_boot[, rem, drop = FALSE]), 1, max, na.rm = TRUE)
  p_rw[ord_k[s]] <- mean(maxt >= abs(t_obs[ord_k[s]]))
}
for (s in 2:length(ord_k)) p_rw[ord_k[s]] <- max(p_rw[ord_k[s]], p_rw[ord_k[s - 1]])

body <- do.call(rbind, lapply(seq_along(cls_fits), function(k) {
  f <- cls_fits[[k]]
  c(names(cls_fits)[k], fmt(f$b, 1), paste0("(", fmt(f$se, 1), ")"), fmt(p_cl[k], 3), fmt(f$p_wb, 3),
    fmt(p_holm[k], 3), fmt(p_rw[k], 3), fmti(f$n), sprintf("%d / %d", f$gl, f$gr))
}))
write_tex_table(body, c("", "Estimate", "S.E.", "$p$ (cluster)", "$p$ (wild)", "$p$ (Holm)", "$p$ (R--W)", "N",
                        "Companies"),
                "table5_rd_by_class.tex", align = "lcccccccc",
                notes = paste("Local linear RD ($h = 1$) with year fixed effects, estimated separately by security class,",
                              "1894--1913. Ordinary stock is never trustee-eligible under s.1(g), so it is a placebo; its yield",
                              "is also mechanically tied to the dividend that defines $X$. Holm and Romano--Wolf $p$-values",
                              "control the family-wise error rate across the four outcomes; Romano--Wolf uses 499 pairs",
                              "cluster-bootstrap draws of companies, common across outcomes."))
cat("Table 5 written.\n"); print(data.table(cls = names(cls_fits), b = sapply(cls_fits, `[[`, "b"), p_holm, p_rw))
set_macro("ordTau", fmt(cls_fits[[4]]$b, 0)); set_macro("ordSE", fmt(cls_fits[[4]]$se, 0))
set_macro("ordPrw", fmt(p_rw[4], 2))

# ============================================================================
# FIGURE 5: RD PLOTS (1894-1913 AND 1879-1887)
# ============================================================================

plot_dat <- rbindlist(lapply(list(post = post, pre = pre), function(d) {
  d <- resid_fe(copy(d)[abs(X) <= 1.5])
  d[, bin := floor(X / 0.125) * 0.125 + 0.0625]
  d
}), idcol = "regime", fill = TRUE)
plot_dat[, regime := factor(fifelse(regime == "post", "1894-1913: 3% rule in force", "1879-1887: before the rules"),
                            levels = c("1894-1913: 3% rule in force", "1879-1887: before the rules"))]
bins <- plot_dat[!is.na(r), .(r = mean(r), n = .N), by = .(regime, bin)]
fitl <- plot_dat[abs(X) <= 1 & !is.na(r)]
p5 <- ggplot() +
  geom_vline(xintercept = 0, linetype = "dashed", colour = PAL["orange"], linewidth = 0.4) +
  geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
  geom_point(data = bins, aes(bin, r, size = n), colour = PAL["navy"], alpha = 0.8) +
  geom_smooth(data = fitl[X < 0], aes(X, r), method = "lm", formula = y ~ x, colour = PAL["orange"],
              fill = PAL["orange"], alpha = 0.15, linewidth = 0.6) +
  geom_smooth(data = fitl[X >= 0], aes(X, r), method = "lm", formula = y ~ x, colour = PAL["orange"],
              fill = PAL["orange"], alpha = 0.15, linewidth = 0.6) +
  facet_wrap(~regime) + scale_size_continuous(range = c(0.8, 3), guide = "none") +
  coord_cartesian(ylim = c(-40, 40)) +
  labs(x = "X: ten-year minimum ordinary dividend minus 3 (percentage points)",
       y = "Senior yield relative to market (bp),\nnet of year and class effects") + theme_paper(9)
save_fig(p5, "fig5_rd_plot", w = 7, h = 3.4)

# ============================================================================
# FIGURE 6: BANDWIDTH SENSITIVITY / FIGURE 7: PLACEBO CUTOFFS
# ============================================================================

bw <- rbindlist(lapply(seq(0.5, 2, by = 0.125), function(h) {
  f <- ll_rd(post, h, boot = FALSE); data.table(h = h, b = f$b, lo = f$b - 1.96 * f$se, hi = f$b + 1.96 * f$se)
}))
p6 <- ggplot(bw, aes(h, b)) + geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = PAL["sky"], alpha = 0.25) +
  geom_line(colour = PAL["navy"], linewidth = 0.6) + geom_point(colour = PAL["navy"], size = 1.2) +
  labs(x = "Bandwidth h (percentage points of dividend)", y = "RD estimate (bp) and 95% CI") + theme_paper(9)
save_fig(p6, "fig6_bandwidth", w = 6, h = 3.2)

pc <- rbindlist(lapply(seq(-1.5, 1.5, by = 0.25), function(c0) {
  if (c0 == 0) { f <- ll_rd(post, 0.5, boot = FALSE) } else {
    side <- if (c0 < 0) post[X < 0] else post[X >= 0]
    side <- copy(side)[, `:=`(X = X - c0, eligible = as.integer(X - c0 >= 0))]
    f <- tryCatch(ll_rd(side, 0.5, boot = FALSE), error = function(e) NULL)
    if (is.null(f)) return(NULL)
  }
  data.table(cut = c0, b = f$b, lo = f$b - 1.96 * f$se, hi = f$b + 1.96 * f$se, true = c0 == 0)
}))
p7 <- ggplot(pc, aes(cut, b, colour = true)) + geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_pointrange(aes(ymin = lo, ymax = hi), size = 0.3) +
  scale_colour_manual(values = c(`FALSE` = unname(PAL["grey"]), `TRUE` = unname(PAL["orange"])), guide = "none") +
  labs(x = "Cutoff, relative to the true 3% threshold (percentage points)", y = "RD estimate (bp), h = 0.5") +
  theme_paper(9)
save_fig(p7, "fig7_placebo_cutoffs", w = 6, h = 3.2)

saveRDS(list(rdr = rdr, fits = lapply(fits, `[`, c("b", "se", "p_wb", "n", "h", "gl", "gr")), placebo = placebo,
             pre = pre_fit[c("b", "se", "p_wb")], bw = bw), file.path(DERIVED_DIR, "rd_results.rds"))
write_macros("rd")
cat("\nStep 5 complete.\n")
