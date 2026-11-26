# ============================================================================
# STEP 7: Did railways manage dividends to keep trustee status?
# ----------------------------------------------------------------------------
# If boards valued eligibility, a company whose record over the previous nine
# years is intact ("at stake") should avoid paying just under 3% this year,
# because one such year removes its senior stocks from the trustee list for a
# decade. Among company-years with a dividend within half a point of 3%:
#
#   Pr(div_ct >= 3) = F( a + b1 * AtStake_ct + b2 * Post_t + b3 * AtStake_ct x Post_t
#                        + b4 * div_c,t-1 )
#
# b3 is the extra pull toward 3% once the rule exists (difference-in-differences
# relative to 1879-1887, when 3% had no legal meaning). Dividend persistence would
# produce b1 > 0 in both regimes; it is absorbed by b1 and by the lagged dividend.
# Placebo: the same test at 2%, 4% and 5%, thresholds with no legal meaning.
#
# Table: table7_dividend_management.tex
# ============================================================================

source("scripts/00_utils.R")
use_output("results")
print_header("STEP 7: DIVIDEND MANAGEMENT AT THE THRESHOLD")

cy <- readRDS(file.path(DERIVED_DIR, "company_year.rds"))[excluded == FALSE & !is.na(div) & !is.na(min9)]
cy <- cy[year %in% c(PRE_YEARS, POST_YEARS)]
cy[, post := as.integer(year %in% POST_YEARS)]

make_sample <- function(k, width = 0.5) {
  s <- cy[div >= k - width & div < k + width]
  s[, `:=`(above = as.integer(div >= k), at_stake = as.integer(min9 >= k))]
  s[!is.na(div_lag1)]
}
s3 <- make_sample(CUTOFF)

lpm   <- feols(above ~ at_stake * post + div_lag1, s3, cluster = ~company)
lpmfe <- feols(above ~ at_stake * post + div_lag1 | company, s3, cluster = ~company)
logit <- feglm(above ~ at_stake * post + div_lag1, s3, family = binomial("logit"), cluster = ~company)
probit<- feglm(above ~ at_stake * post + div_lag1, s3, family = binomial("probit"), cluster = ~company)
plac  <- lapply(c(2, 4, 5), function(k) feols(above ~ at_stake * post + div_lag1, make_sample(k), cluster = ~company))

models <- c(list(lpm, lpmfe, logit, probit), plac)
cell <- function(m, v) if (v %in% names(coef(m))) c(paste0(fmt(coef(m)[v], 3), stars(pvalue(m)[v])),
                                                    paste0("(", fmt(se(m)[v], 3), ")")) else c("", "")
rows <- c(`At stake $\\times$ post-1893` = "at_stake:post", `At stake` = "at_stake", `Post-1893` = "post",
          `Dividend in $t-1$` = "div_lag1")
body <- do.call(rbind, lapply(names(rows), function(r) {
  cc <- sapply(models, cell, v = rows[[r]]); rbind(c(r, cc[1, ]), c("", cc[2, ]))
}))
body <- rbind(body,
  c("Threshold $k$ (\\%)", "3", "3", "3", "3", "2", "4", "5"),
  c("Estimator", "LPM", "LPM", "Logit", "Probit", "LPM", "LPM", "LPM"),
  c("Company fixed effects", "No", "Yes", "No", "No", "No", "No", "No"),
  c("Company-years", sapply(models, function(m) fmti(nobs(m)))),
  c("Companies", fmti(uniqueN(s3$company)), fmti(uniqueN(s3$company)), fmti(uniqueN(s3$company)),
    fmti(uniqueN(s3$company)), sapply(c(2, 4, 5), function(k) fmti(uniqueN(make_sample(k)$company)))))
write_tex_table(body, c("", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)"), "table7_dividend_management.tex",
                align = "lccccccc",
                notes = paste("Company-years with an ordinary dividend within 0.5 points of threshold $k$, in 1879--1887",
                              "and 1894--1913. Dependent variable: 1[dividend $\\ge k$]. At stake: the company paid at",
                              "least $k$\\% in each of the previous nine years, so paying less now breaks a ten-year record.",
                              "Only $k = 3$ has legal meaning (Trustee Act 1893). Standard errors clustered by company.",
                              "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."))

# Predicted probabilities from the logit (post-1893, at the sample mean lagged dividend)
nd <- data.table(at_stake = c(1, 0), post = 1, div_lag1 = mean(s3$div_lag1))
pp <- predict(logit, newdata = nd)
exact_stake <- s3[post == 1 & at_stake == 1, mean(div == 3)]
exact_not   <- s3[post == 1 & at_stake == 0, mean(div == 3)]
below_stake <- s3[post == 1 & at_stake == 1, sum(div < 3)]
n_stake     <- s3[post == 1 & at_stake == 1, .N]

cat("Table 7 written. LPM interaction:", fmt(coef(lpm)["at_stake:post"], 3), "(", fmt(se(lpm)["at_stake:post"], 3), ")",
    "| P(>=3) at stake vs not, post:", fmt(pp[1], 2), fmt(pp[2], 2), "\n")
set_macro("lpmInt", fmt(coef(lpm)["at_stake:post"], 2)); set_macro("lpmIntSE", fmt(se(lpm)["at_stake:post"], 2))
set_macro("lpmfeInt", fmt(coef(lpmfe)["at_stake:post"], 2)); set_macro("lpmfeIntSE", fmt(se(lpmfe)["at_stake:post"], 2))
set_macro("logitInt", fmt(coef(logit)["at_stake:post"], 2)); set_macro("probitInt", fmt(coef(probit)["at_stake:post"], 2))
set_macro("ppStake", fmt(100 * pp[1], 0)); set_macro("ppNot", fmt(100 * pp[2], 0))
set_macro("exactStake", fmt(100 * exact_stake, 0)); set_macro("exactNot", fmt(100 * exact_not, 0))
set_macro("belowStake", below_stake); set_macro("nStake", n_stake)
set_macro("placTwo", fmt(coef(plac[[1]])["at_stake:post"], 2)); set_macro("placFour", fmt(coef(plac[[2]])["at_stake:post"], 2))
set_macro("placFive", fmt(coef(plac[[3]])["at_stake:post"], 2))
write_macros("divmgmt")
cat("\nStep 7 complete.\n")
