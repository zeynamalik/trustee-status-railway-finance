# ============================================================================
# STEP 2: Ordinary dividends and the trustee-eligibility running variable
# ----------------------------------------------------------------------------
# Trustee Act 1893, s.1(g): trustees may invest in the debenture, rentcharge,
# guaranteed or preference stock of a British or Irish railway company that has
# "during each of the ten years last past ... paid a dividend at the rate of not
# less than three per centum per annum on its ordinary stock".
#
# Running variable (company c, year t):
#     X_ct = min{ D_c,t-10, ..., D_c,t-1 } - 3
# where D_cs is the annual dividend rate on the company's ordinary stock paid in
# calendar year s. Senior securities are trustee-eligible in year t iff X_ct >= 0.
#
# Three measures of D_cs are built, for the measurement-error analysis:
#   (a) SLOT measure  - the IMM prints the last four dividend payments; in the
#       latest autumn/December issue of year s, the two most recent slots are the
#       payments made during s.  Available for every year 1869-1929. MAIN MEASURE.
#   (b) DATED measure - every payment carries a date from 1883 on; collect all
#       dated payments across monthly issues, take the modal rate per payment,
#       and average the payments made in calendar year s. Reuses the printed
#       rates, so it checks the timing of (a), not its transcription.
#   (c) YIELD-IMPLIED measure - see section 1 below; transcribed independently,
#       so it serves as the instrument in step 6.
#
# Output: data/derived/company_year.rds
# ============================================================================

source("scripts/00_utils.R")
print_header("STEP 2: DIVIDENDS AND RUNNING VARIABLE")

br <- setDT(readRDS(file.path(DERIVED_DIR, "sec_month.rds")))

# ============================================================================
# 1. PARSE THE FOUR DIVIDEND SLOTS
# ============================================================================

for (k in 1:4) {
  rate <- to_num(br[[paste0("dvdlastfourratepercentannum", k)]])
  note <- tolower(trimws(br[[paste0("ndvdlastfour", k)]]))
  rate[is.na(rate) & grepl("^nil", note)] <- 0          # "nil" = dividend passed
  rate[rate < 0 | rate > 40] <- NA
  set(br, j = paste0("r", k), value = rate)
}
br[, freq := tolower(trimws(dvdlastfourfrequency))]
br[, `:=`(m4 = rowMeans(cbind(r1, r2, r3, r4), na.rm = TRUE), m2 = rowMeans(cbind(r3, r4), na.rm = TRUE))]
br[, div_slot_rec := fifelse(freq %in% "qa", m4, fifelse(freq %in% c("yl", "an"), r4, m2))]
br[is.nan(div_slot_rec), div_slot_rec := NA]

# Slot measure: the latest October-December issue of each year
slot <- br[month >= 10 & !is.na(div_slot_rec)][order(id, year, -month)]
slot <- slot[, .SD[1], by = .(id, year)][, .(id, year, div_slot = div_slot_rec)]

# (c) YIELD-IMPLIED measure: the IMM also printed its own "yield on investment"
#     for each stock, computed by its editors from the current annual dividend and
#     the price. Dividend = yield x price / amount paid. The yield column was
#     transcribed separately from the dividend columns, so its errors are
#     independent of those in (a) and (b).
yl <- br[month >= 10 & !is.na(yield_imm) & price > 0 & to_num(capitalpaid) > 0][order(id, year, -month)]
yl <- yl[, .SD[1], by = .(id, year)][, .(id, year, div_yld = yield_imm * price / to_num(capitalpaid))]
yl[div_yld > 25, div_yld := NA]
# The yield is printed to the nearest penny, so yield x price recovers the dividend
# only to about +/-0.02 points (3.00% comes back as 2.99%). Dividends were
# declared in eighths of a percent, so round to the nearest 1/8.
yl[, div_yld := round(div_yld * 8) / 8]

# ============================================================================
# 2. DATED PAYMENTS (1883 ON)
# ============================================================================

mon_lookup <- setNames(1:12, c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"))
pays <- rbindlist(lapply(1:4, function(k) {
  x <- br[, .(id, rate = get(paste0("r", k)), dmy = get(paste0("dvdlastfourdmy", k)))]
  m <- regmatches(x$dmy, regexec("^\\s*\\d{0,2}\\s*([A-Za-z]{3})[a-z]*\\.?\\s*(\\d{4})\\s*$", x$dmy))
  x[, pay_month := mon_lookup[tolower(vapply(m, function(v) if (length(v)) v[2] else NA_character_, ""))]]
  x[, pay_year := as.integer(vapply(m, function(v) if (length(v)) v[3] else NA_character_, ""))]
  x[!is.na(rate) & !is.na(pay_month) & pay_year %between% c(1860, 1930)]
}))
modal <- function(v) as.numeric(names(which.max(table(v))))
pays <- pays[, .(rate = modal(rate)), by = .(id, pay_year, pay_month)]
dated <- pays[, .(div_dated = mean(rate), n_pay = .N), by = .(id, year = pay_year)]

# ============================================================================
# 3. THE COMPANY'S ORDINARY STOCK IN EACH YEAR
# ============================================================================
# Undivided ordinary stock: the ordinary-class security with the largest nominal
# capital in the year. Where a company quotes only split stock (preferred and
# deferred ordinary created 1:1 from the old ordinary), the dividend on the
# undivided stock equals the sum of the two rates.

secinfo <- br[, .(capital = suppressWarnings(max(capital, na.rm = TRUE)), months = .N),
              by = .(company, id, year, sec_class)]
secinfo[!is.finite(capital), capital := 0]
pick_largest <- function(cls) {
  x <- merge(secinfo[sec_class == cls], slot, by = c("id", "year"))
  x[order(company, year, -capital, -months)][, .SD[1], by = .(company, year)]
}
ord  <- pick_largest("ordinary")[,      .(company, year, ord_id = id, ord_capital = capital, div_slot_ord = div_slot)]
pord <- pick_largest("pref_ordinary")[, .(company, year, div_pref_ord = div_slot)]
dord <- pick_largest("deferred")[,      .(company, year, div_def_ord = div_slot)]

cy <- Reduce(function(a, b) merge(a, b, by = c("company", "year"), all = TRUE), list(ord, pord, dord))
# Split stock was created 1:1 (GBP 100 ordinary -> GBP 100 preferred + GBP 100 deferred
# ordinary); e.g. Caledonian 1895: Consolidated 5% = preferred 3% + deferred 2%.
#   (i)  undivided line quoted alongside a deferred line  -> use the undivided line
#   (ii) "ordinary" line paying no more than the preferred half, no separate deferred
#        line -> the "ordinary" line is the deferred half (North British 1895-1910)
#   (iii) only the two halves quoted                       -> preferred + deferred
cy[, ord_is_deferred := !is.na(div_slot_ord) & is.na(div_def_ord) & !is.na(div_pref_ord) &
                        div_slot_ord <= div_pref_ord]
cy[ord_is_deferred == TRUE, `:=`(div_def_ord = div_slot_ord, div_slot_ord = NA_real_)]
cy[, split_stock := is.na(div_slot_ord) & !is.na(div_pref_ord) & !is.na(div_def_ord)]
cy[, div := fifelse(split_stock, div_pref_ord + div_def_ord, div_slot_ord)]
cy[, company_split := any(split_stock), by = company]
cy <- merge(cy, dated[, .(ord_id = id, year, div_dated)], by = c("ord_id", "year"), all.x = TRUE)
cy <- merge(cy, yl[, .(ord_id = id, year, div_yld)], by = c("ord_id", "year"), all.x = TRUE)
cy[split_stock == TRUE, `:=`(div_dated = NA, div_yld = NA)]
cy <- cy[!is.na(div)]

# Leased lines and fixed-rent stocks pay a constant dividend and qualify through
# s.1(h) of the Act, not the dividend test, so they are flagged and excluded
cy[, `:=`(n_years = .N, sd_div = sd(div), mean_div = mean(div)), by = company]
cy[, fixed_dividend := n_years >= 10 & sd_div < 1e-8 & mean_div > 0]

cat("Company-years with an ordinary dividend:", fmti(nrow(cy)), "| companies:", uniqueN(cy$company), "\n")
cat("  of which split-stock company-years:", cy[split_stock == TRUE, .N],
    "| fixed-dividend (leased) companies:", cy[fixed_dividend == TRUE, uniqueN(company)], "\n")
cat("Agreement of slot and yield-implied measures (|diff| <= 0.25pp):",
    round(cy[!is.na(div_yld), mean(abs(div - div_yld) <= 0.25)], 3),
    "| correlation:", round(cy[!is.na(div_yld), cor(div, div_yld)], 3), "\n")
cat("Agreement of slot and dated measures (|diff| <= 0.25pp):",
    round(cy[!is.na(div_dated), mean(abs(div - div_dated) <= 0.25)], 3),
    "| correlation:", round(cy[!is.na(div_dated), cor(div, div_dated)], 3), "\n")

# ============================================================================
# 4. RUNNING VARIABLE: TEN-YEAR MINIMUM DIVIDEND
# ============================================================================

panel <- CJ(company = unique(cy$company), year = 1869:1929)
panel <- merge(panel, cy[, .(company, year, div, div_dated, div_yld, ord_id, ord_capital, split_stock, company_split, fixed_dividend)],
               by = c("company", "year"), all.x = TRUE)
setorder(panel, company, year)

roll_stat <- function(v, k, f, need) {
  n <- length(v); out <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    if (i <= k) next
    w <- v[(i - k):(i - 1)]
    if (sum(!is.na(w)) >= need) out[i] <- f(w[!is.na(w)])
  }
  out
}
panel[, `:=`(
  min10       = roll_stat(div, WINDOW_YEARS, min, MIN_OBS_YEARS),
  min10_full  = roll_stat(div, WINDOW_YEARS, min, WINDOW_YEARS),         # all ten years observed
  min10_dated = roll_stat(div_dated, WINDOW_YEARS, min, MIN_OBS_YEARS),
  min10_yld   = roll_stat(div_yld, WINDOW_YEARS, min, MIN_OBS_YEARS),
  mean10      = roll_stat(div, WINDOW_YEARS, mean, MIN_OBS_YEARS),
  sd10        = roll_stat(div, WINDOW_YEARS, sd, MIN_OBS_YEARS),
  min9        = roll_stat(div, WINDOW_YEARS - 1, min, WINDOW_YEARS - 2),  # record over the last 9 years
  nobs10      = roll_stat(div, WINDOW_YEARS, length, 1),
  div_lag1    = shift(div, 1)
), by = company]
panel[, fixed_dividend := any(fixed_dividend %in% TRUE), by = company]

# Hand-coded exclusions (foreign lines registered in London; leased, jointly owned or
# guaranteed lines whose senior stocks qualify, if at all, under s.1(h) not s.1(g))
excl <- fread("config/company_exclusions.csv")
panel[, excluded := company %in% excl$company | fixed_dividend]
cat("Excluded companies (hand-coded list + fixed dividend):", panel[excluded == TRUE, uniqueN(company)], "\n")
panel[, `:=`(X = min10 - CUTOFF, eligible = as.integer(min10 >= CUTOFF),
             X_dated = min10_dated - CUTOFF, eligible_dated = as.integer(min10_dated >= CUTOFF),
             X_yld = min10_yld - CUTOFF, eligible_yld = as.integer(min10_yld >= CUTOFF))]

saveRDS(panel, file.path(DERIVED_DIR, "company_year.rds"))

rv <- panel[!is.na(X) & excluded == FALSE]
cat("\nCompany-years with a running variable:", fmti(nrow(rv)), "| companies:", uniqueN(rv$company), "\n")
for (h in c(0.5, 1, 1.5)) {
  s <- rv[abs(X) <= h & year %in% POST_YEARS]
  cat(sprintf("  post-1893, |X| <= %.1f: %d company-years, %d companies (%d eligible, %d not)\n",
              h, nrow(s), uniqueN(s$company), s[eligible == 1, .N], s[eligible == 0, .N]))
}
cat("\nStep 2 complete.\n")
