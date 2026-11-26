# ============================================================================
# STEP 6: Within-security panel estimates and measurement error (IV)
# ----------------------------------------------------------------------------
# (a) Panel fixed effects. Companies gain and lose eligibility as dividends move,
#     so security fixed effects compare the same security in eligible and
#     ineligible years:
#         rel_bp_it = alpha_i + gamma_t + beta * eligible_ct + controls + e_it
# (b) Measurement error. Eligibility is built from transcribed dividends, so it is
#     misclassified for some company-years, which attenuates estimates. A second,
#     independently transcribed measure - the dividend implied by the IMM's own
#     printed yield and the price - is used as an instrument: a fuzzy RD on the
#     yield-implied running variable, and FE-2SLS. (The dated-payment measure
#     reuses the same printed rates, so it cannot serve as an instrument.)
#     With binary misclassified regressors IV is not exactly consistent (Black,
#     Berger and Scott 2000), but it bounds the attenuation from above.
#
# Table: table6_panel_iv.tex
# ============================================================================

source("scripts/00_utils.R")
use_output("results")
print_header("STEP 6: PANEL FIXED EFFECTS AND IV")

senior <- readRDS(file.path(DERIVED_DIR, "analysis_senior.rds"))
post   <- senior[period == "post"]

# ============================================================================
# 1. HOW OFTEN DO THE TWO MEASURES DISAGREE?
# ============================================================================

cy <- unique(post[, .(company, year, eligible, eligible_dated, eligible_yld, X, X_yld)])
agree_dated <- cy[!is.na(eligible_dated), mean(eligible == eligible_dated)]
agree       <- cy[!is.na(eligible_yld), mean(eligible == eligible_yld)]
agree_near  <- cy[!is.na(eligible_yld) & abs(X) <= 1, mean(eligible == eligible_yld)]
cat("Eligibility agreement - slot vs dated:", fmt(agree_dated, 3), "| slot vs yield-implied:", fmt(agree, 3),
    "| within |X| <= 1:", fmt(agree_near, 3), "\n")
set_macro("agreeDated", fmt(100 * agree_dated, 1))
set_macro("agreeAll", fmt(100 * agree, 0)); set_macro("agreeNear", fmt(100 * agree_near, 0))
set_macro("corrXyld", fmt(cy[!is.na(X_yld), cor(X, X_yld)], 2))

n_switch_sec <- post[, uniqueN(eligible), by = id][V1 > 1, .N]
n_switch_co  <- post[, uniqueN(eligible), by = company][V1 > 1, .N]
set_macro("nSwitchSec", n_switch_sec); set_macro("nSwitchCo", n_switch_co)

# ============================================================================
# 2. ESTIMATES
# ============================================================================

m1 <- feols(rel_bp ~ eligible | id + year, post, cluster = ~company)
m2 <- feols(rel_bp ~ eligible + div_lag1 + mean10 | id + year, post, cluster = ~company)
m3 <- feols(rel_bp ~ eligible + div_lag1 + mean10 | id + year, post, cluster = ~company + year)

# Fuzzy RD: yield-implied running variable, slot-based eligibility as the treatment
fz <- post[!is.na(X_yld) & abs(X_yld) <= 1]
fz[, z := as.integer(X_yld >= 0)]
fs <- feols(eligible ~ z + X_yld + z:X_yld | year + sec_class, fz, cluster = ~company)
iv <- feols(rel_bp ~ X_yld + z:X_yld | year + sec_class | eligible ~ z, fz, cluster = ~company)
f_fuzzy <- fitstat(iv, "ivwald1")[[1]]$stat

# Panel FE-2SLS: slot eligibility instrumented with yield-implied eligibility
pv  <- post[!is.na(eligible_yld)]
iv2 <- feols(rel_bp ~ div_lag1 + mean10 | id + year | eligible ~ eligible_yld, pv, cluster = ~company)
f_fe <- fitstat(iv2, "ivwald1")[[1]]$stat
n_switch_iv <- pv[, uniqueN(eligible), by = company][V1 > 1, .N]
set_macro("nSwitchIV", n_switch_iv)

g <- function(m, v = "eligible") c(fmt(coef(m)[v], 1), paste0("(", fmt(se(m)[v], 1), ")"))
gfs <- function(m, v) c(fmt(coef(m)[v], 3), paste0("(", fmt(se(m)[v], 3), ")"))
body <- rbind(
  c("Trustee eligible", g(m1)[1], g(m2)[1], g(m3)[1], "", g(iv, "fit_eligible")[1], g(iv2, "fit_eligible")[1]),
  c("", g(m1)[2], g(m2)[2], g(m3)[2], "", g(iv, "fit_eligible")[2], g(iv2, "fit_eligible")[2]),
  c("Instrument (yield-implied measure eligible)", "", "", "", gfs(fs, "z")[1], "", ""),
  c("", "", "", "", gfs(fs, "z")[2], "", ""),
  c("First-stage $F$ (cluster-robust Wald)", "", "", "", "", fmt(f_fuzzy, 1), fmt(f_fe, 1)),
  c("Dividend controls", "No", "Yes", "Yes", "No", "No", "Yes"),
  c("Fixed effects", "Security, year", "Security, year", "Security, year", "Year, class", "Year, class", "Security, year"),
  c("Companies switching eligibility", n_switch_co, n_switch_co, n_switch_co, "--", "--", n_switch_iv),
  c("Clustering", "Company", "Company", "Company, year", "Company", "Company", "Company"),
  c("Observations", fmti(nobs(m1)), fmti(nobs(m2)), fmti(nobs(m3)), fmti(nobs(fs)), fmti(nobs(iv)), fmti(nobs(iv2))))
write_tex_table(body, c("", "(1) FE", "(2) FE", "(3) FE", "(4) First stage", "(5) Fuzzy RD", "(6) FE-2SLS"),
                "table6_panel_iv.tex", align = "lcccccc",
                notes = paste("Senior railway security-years, 1894--1913. Dependent variable: yield relative to the market",
                              "median (bp), except column (4), where it is slot-measured eligibility. Columns (1)--(3) use",
                              "within-security variation as companies gain or lose eligibility; dividend controls are the",
                              "previous year's ordinary dividend and the ten-year mean. Columns (4)--(5) are a fuzzy RD with",
                              "the running variable rebuilt from the dividend implied by the IMM's printed yield and price",
                              "($|X^{yld}| \\le 1$), instrumenting slot-measured eligibility with yield-implied eligibility.",
                              "Column (6) uses the same instrument in the fixed-effects model. Within-security estimates are",
                              "identified only from the few companies whose eligibility changes, so their clustered standard",
                              "errors are unreliable."))
cat("Table 6 written. FE:", fmt(coef(m1)["eligible"], 1), "| fuzzy RD 2SLS:", fmt(coef(iv)["fit_eligible"], 1),
    "F =", fmt(f_fuzzy, 1), "| FE-2SLS:", fmt(coef(iv2)["fit_eligible"], 1), "F =", fmt(f_fe, 1), "\n")

set_macro("feTau", fmt(coef(m2)["eligible"], 1)); set_macro("feSE", fmt(se(m2)["eligible"], 1))
set_macro("fzTau", fmt(coef(iv)["fit_eligible"], 1)); set_macro("fzSE", fmt(se(iv)["fit_eligible"], 1))
set_macro("fzF", fmt(f_fuzzy, 0)); set_macro("fsCoef", fmt(coef(fs)["z"], 2))
set_macro("feivTau", fmt(coef(iv2)["fit_eligible"], 1)); set_macro("feivSE", fmt(se(iv2)["fit_eligible"], 1))
set_macro("feivF", fmt(f_fe, 0))
write_macros("panel")
cat("\nStep 6 complete.\n")
