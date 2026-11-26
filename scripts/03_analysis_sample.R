# ============================================================================
# STEP 3: Analysis samples
# ----------------------------------------------------------------------------
# Merges each security-year onto its company's running variable and defines the
# samples used in the analysis:
#   senior  : debenture, rentcharge, guaranteed and preference stock (the claims
#             that s.1(g) makes trustee-eligible), 1879-1913
#   ordinary: the company's main ordinary stock (placebo: never trustee-eligible)
# Output: data/derived/analysis_senior.rds, analysis_ordinary.rds, sample_flow.rds
# ============================================================================

source("scripts/00_utils.R")
print_header("STEP 3: ANALYSIS SAMPLES")

sec_year <- readRDS(file.path(DERIVED_DIR, "sec_year.rds"))
cy       <- readRDS(file.path(DERIVED_DIR, "company_year.rds"))
cy[, at_stake := as.integer(!is.na(min9) & min9 >= CUTOFF)]
log_n    <- readRDS(file.path(DERIVED_DIR, "build_log.rds"))

rv_cols <- c("company", "year", "div", "div_lag1", "min10", "min10_full", "min10_dated", "min9", "mean10",
             "sd10", "nobs10", "X", "eligible", "X_dated", "eligible_dated", "X_yld", "eligible_yld", "ord_id", "ord_capital",
             "split_stock", "company_split", "excluded", "at_stake")
d <- merge(sec_year, cy[, ..rv_cols], by = c("company", "year"), all.x = TRUE)

# Company characteristics used as balance covariates. Country codes mislabel some
# Irish lines (e.g. the Midland Great Western of Ireland is coded GBR), so Irish
# companies are identified from their names.
IRISH_RX <- paste0("Ireland|Irish|Dublin|Belfast|Cork|Waterford|Midland Great Western|Great Southern & Western|",
                   "Limerick|Londonderry|Sligo|Tralee|Clogher|Donegal|Athenry|Ulster|Armagh|Newry|Finn Valley|",
                   "Banbridge|Kingstown|Bandon|Macroom|Tramore|Wexford|Meath|Drogheda|Portadown")
d[, irish := as.integer(grepl(IRISH_RX, company) | ISO == "IRL")]
d[, log_ord_cap := log(ord_capital)]
d[, log_capital := log(capital)]
d[, period := fcase(year %in% PRE_YEARS, "pre", year %in% POST_YEARS, "post",
                    year %between% c(1888, 1893), "transition", year >= 1914, "war_and_after", default = NA_character_)]

# ============================================================================
# SAMPLE FLOW (senior securities)
# ============================================================================

flow <- list()
s <- d[sec_class %in% SENIOR_CLASSES];               flow[["Senior railway security-years (all years)"]] <- c(nrow(s), uniqueN(s$company))
s <- s[!is.na(yield) & n_months >= 3];              flow[["  with a yield in at least 3 months"]]        <- c(nrow(s), uniqueN(s$company))
s <- s[excluded %in% FALSE];                         flow[["  company not foreign, leased or jointly owned"]] <- c(nrow(s), uniqueN(s$company))
s <- s[!is.na(X)];                                   flow[["  ten-year dividend record observed"]]        <- c(nrow(s), uniqueN(s$company))
s <- s[year %in% c(PRE_YEARS, POST_YEARS)];          flow[["  in 1879-1887 or 1894-1913"]]                <- c(nrow(s), uniqueN(s$company))
s_post <- s[period == "post"];                       flow[["  post-1893 regime (main RD sample)"]]        <- c(nrow(s_post), uniqueN(s_post$company))
s_pre  <- s[period == "pre"];                        flow[["  pre-1888 regime (placebo sample)"]]         <- c(nrow(s_pre), uniqueN(s_pre$company))

flow_dt <- data.table(step = names(flow), N = sapply(flow, `[`, 1), companies = sapply(flow, `[`, 2))
print(flow_dt)

senior <- d[sec_class %in% SENIOR_CLASSES & !is.na(yield) & n_months >= 3 & excluded %in% FALSE & !is.na(X)]
senior[, sec_class := factor(sec_class, levels = SENIOR_CLASSES)]
ordinary <- d[id == ord_id & !is.na(yield) & n_months >= 3 & excluded %in% FALSE & !is.na(X)]

saveRDS(senior, file.path(DERIVED_DIR, "analysis_senior.rds"))
saveRDS(ordinary, file.path(DERIVED_DIR, "analysis_ordinary.rds"))
saveRDS(list(flow = flow_dt, log = log_n), file.path(DERIVED_DIR, "sample_flow.rds"))

cat("\nSenior security-years, post regime:", senior[period == "post", .N],
    "| within 1pp of cutoff:", senior[period == "post" & abs(X) <= 1, .N],
    "| companies:", senior[period == "post" & abs(X) <= 1, uniqueN(company)], "\n")
cat("Step 3 complete.\n")
