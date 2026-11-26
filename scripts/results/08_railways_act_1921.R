# ============================================================================
# STEP 8: The Railways Act 1921 - trustee status by statute
# ----------------------------------------------------------------------------
# Section 15 of the Railways Act 1921 deemed each of the four amalgamated
# companies to have paid at least 3% on its ordinary stock in each of the ten
# preceding years, so every amalgamated company's stocks became trustee
# securities. Holders of senior stocks in constituent companies that had *not*
# qualified were therefore promised trustee-eligible paper; holders in
# companies that already qualified were not. Difference-in-differences on the
# monthly yields of senior stocks, 1919-1922:
#
#   rel_bp_it = alpha_i + delta_month + beta * Treat_c x Post_t + e_it
#
# Treat_c = 1 if company c failed the ten-year 3% test in 1921.
# Events: White Paper Cmd. 787 (end of June 1920); royal assent 19 Aug 1921;
# amalgamation 1 Jan 1923. Constituent securities stop trading at conversion.
#
# Caveat: the same Act pooled weak and strong companies, and exchange terms were
# negotiated on market values, so beta bundles trustee status with any credit
# effect of amalgamation.
#
# Table : table8_railways_act.tex      Figure: fig8_event_study
# ============================================================================

source("scripts/00_utils.R")
use_output("results")
print_header("STEP 8: RAILWAYS ACT 1921")

br <- readRDS(file.path(DERIVED_DIR, "sec_month.rds"))
cy <- readRDS(file.path(DERIVED_DIR, "company_year.rds"))

IRISH_RX <- paste0("Ireland|Irish|Dublin|Belfast|Cork|Waterford|Midland Great Western|Great Southern & Western|",
                   "Limerick|Londonderry|Sligo|Tralee|Clogher|Donegal|Athenry|Ulster|Armagh|Newry|Finn Valley|",
                   "Banbridge|Kingstown|Bandon|Macroom|Tramore|Wexford|Meath|Drogheda|Portadown")

# Companies amalgamated under the Act: British, last quoted 1921-1923
last_q <- br[, .(last_year = max(year)), by = company]
status <- cy[year == 1921 & excluded == FALSE & !is.na(X), .(company, X21 = X, elig21 = eligible)]
status <- merge(status, last_q, by = "company")
status <- status[last_year %between% c(1921, 1923) & !grepl(IRISH_RX, company)]
cat("Amalgamated companies with a 1921 dividend record:", nrow(status),
    "| not trustee-eligible in 1921:", status[elig21 == 0, .N], "\n")

m <- br[year %between% c(1919, 1922) & sec_class %in% SENIOR_CLASSES & !is.na(rel_bp)]
m <- merge(m, status, by = "company")
m[, `:=`(treat = 1L - elig21,
         ym = year * 12 + month,
         q  = (year - 1919) * 4 + (month - 1) %/% 3 + 1)]
m[, `:=`(announce = as.integer(ym >= 1920 * 12 + 7 & ym < 1921 * 12 + 8),   # Jul 1920 - Jul 1921
         act      = as.integer(ym >= 1921 * 12 + 8))]                          # Aug 1921 onward
REF_Q <- 6   # 1920Q2, the quarter before the White Paper became public

# ============================================================================
# 1. EVENT STUDY (QUARTERS)
# ============================================================================

es <- feols(rel_bp ~ i(q, treat, ref = REF_Q) | id + year^month, m, cluster = ~company)
ct <- as.data.table(coeftable(es), keep.rownames = "term")
ct[, q := as.integer(sub("q::([0-9]+):treat", "\\1", term))]
ct <- rbind(ct[, .(q, b = Estimate, se = `Std. Error`)], data.table(q = REF_Q, b = 0, se = 0))
ct[, date := 1919 + (q - 1) / 4 + 0.125]
p8 <- ggplot(ct, aes(date, b)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
  geom_vline(xintercept = 1920 + 5.9 / 12, linetype = "dashed", colour = PAL["grey"], linewidth = 0.4) +
  geom_vline(xintercept = 1921 + 7.6 / 12, linetype = "dashed", colour = PAL["orange"], linewidth = 0.4) +
  annotate("text", x = 1920 + 5.9 / 12, y = Inf, label = "White Paper\n(June 1920)", vjust = 1.2, hjust = 1.05, size = 2.7) +
  annotate("text", x = 1921 + 7.6 / 12, y = Inf, label = "Royal assent\n(Aug 1921)", vjust = 1.2, hjust = -0.05, size = 2.7) +
  geom_pointrange(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), colour = PAL["navy"], size = 0.3) +
  labs(x = NULL, y = "Treated minus control senior yield (bp)\nrelative to 1920Q2") + theme_paper(9)
save_fig(p8, "fig8_event_study", w = 6.5, h = 3.4)

# ============================================================================
# 2. DIFFERENCE-IN-DIFFERENCES
# ============================================================================

d1 <- feols(rel_bp ~ treat:act | id + year^month, m, cluster = ~company)
d2 <- feols(rel_bp ~ treat:announce + treat:act | id + year^month, m, cluster = ~company)
# Wild-cluster bootstrap for (1): explicit dummies for security and month
Xm <- model.matrix(~ treat:act + factor(id) + factor(ym), m)
colnames(Xm)[colnames(Xm) == "treat:act"] <- "treat_act"
p_wb <- wild_cluster_p(m$rel_bp, Xm, m$company, "treat_act", B = 999)

# Matched controls: each treated security is paired with the control security of
# the same class whose 1919 mean relative yield is closest (with replacement)
pre19 <- m[year == 1919, .(pre = mean(rel_bp)), by = .(id, treat, sec_class)]
tr <- pre19[treat == 1]; co <- pre19[treat == 0]
pairs <- rbindlist(lapply(seq_len(nrow(tr)), function(i) {
  cand <- co[sec_class == tr$sec_class[i]]
  if (!nrow(cand)) return(NULL)
  j <- which.min(abs(cand$pre - tr$pre[i]))
  data.table(pair = i, id = c(tr$id[i], cand$id[j]), gap = abs(cand$pre[j] - tr$pre[i]))
}))
mm <- merge(m, pairs[, .(id, pair)], by = "id", allow.cartesian = TRUE)
d3 <- feols(rel_bp ~ treat:act | id^pair + pair^year^month, mm, cluster = ~company)
bal_before <- pre19[, mean(pre), by = treat][order(treat)]$V1
bal_after  <- merge(pre19, pairs[, .(id, pair)], by = "id")[, mean(pre), by = treat][order(treat)]$V1

est <- function(mod, v) if (v %in% names(coef(mod))) fmt(coef(mod)[v], 1) else ""
sdv <- function(mod, v) if (v %in% names(coef(mod))) paste0("(", fmt(se(mod)[v], 1), ")") else ""
n_co <- function(d) sprintf("%d / %d", d[treat == 1, uniqueN(company)], d[treat == 0, uniqueN(company)])
mods <- list(d1, d2, d3)
body <- rbind(
  c("Not eligible in 1921 $\\times$ after royal assent",           sapply(mods, est, "treat:act")),
  c("",                                                            sapply(mods, sdv, "treat:act")),
  c("Not eligible in 1921 $\\times$ White Paper to assent",          sapply(mods, est, "treat:announce")),
  c("",                                                            sapply(mods, sdv, "treat:announce")),
  c("Wild-cluster bootstrap $p$ (first row)",                     fmt(p_wb, 3), "", ""),
  c("1919 relative yield, treated $-$ control (bp)",              fmt(bal_before[2] - bal_before[1], 1), "",
                                                                   fmt(bal_after[2] - bal_after[1], 1)),
  c("Sample",                                                      "All", "All", "Matched"),
  c("Observations (security-months)",                              sapply(mods, function(x) fmti(nobs(x)))),
  c("Companies (treated / control)",                               n_co(m), n_co(m), n_co(mm)))
write_tex_table(body, c("", "(1)", "(2)", "(3)"), "table8_railways_act.tex", align = "lccc",
                notes = paste("Monthly senior-security yields relative to the market median (bp), January 1919 to December",
                              "1922, for British companies amalgamated under the Railways Act 1921. Treated: the company had",
                              "not paid 3\\% in each of the ten years to 1920, so its senior stocks gained trustee status only",
                              "through s.15 of the Act. All columns include security and calendar-month fixed effects (column",
                              "(3): pair-specific). Column (3) matches each treated security to the control security of the",
                              "same class with the closest 1919 mean yield. Standard errors clustered by company."))
cat("Table 8 written. DiD:", fmt(coef(d1)["treat:act"], 1), "(", fmt(se(d1)["treat:act"], 1), ") wild p",
    fmt(p_wb, 3), "| matched:", fmt(coef(d3)["treat:act"], 1), "\n")

set_macro("actTau", fmt(coef(d1)["treat:act"], 1)); set_macro("actSE", fmt(se(d1)["treat:act"], 1))
set_macro("actPwb", fmt(p_wb, 2)); set_macro("actAnn", fmt(coef(d2)["treat:announce"], 1))
set_macro("actAnnSE", fmt(se(d2)["treat:announce"], 1))
set_macro("actMatched", fmt(coef(d3)["treat:act"], 1)); set_macro("actMatchedSE", fmt(se(d3)["treat:act"], 1))
set_macro("actNtreat", m[treat == 1, uniqueN(company)]); set_macro("actNctrl", m[treat == 0, uniqueN(company)])
set_macro("actCILo", fmt(coef(d1)["treat:act"] - 1.96 * se(d1)["treat:act"], 1))
set_macro("actCIHi", fmt(coef(d1)["treat:act"] + 1.96 * se(d1)["treat:act"], 1))
set_macro("esPeak", fmt(max(ct$b), 0))
set_macro("esLate", fmt(mean(ct[q >= 15, b]), 0))
set_macro("esPre", fmt(max(abs(ct[q < REF_Q, b])), 0))
write_macros("act1921")
cat("\nStep 8 complete.\n")
