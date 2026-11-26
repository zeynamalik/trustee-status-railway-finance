# ============================================================================
# STEP 1: Build the security-month and security-year panels
# ----------------------------------------------------------------------------
# Input : IMM railway records (Railways_new.csv) and the IMM cleaned file
#         (Totaldata.csv; used for company names, country codes, and consols)
# Output: data/derived/sec_month.rds   British & Irish railway securities, monthly
#         data/derived/sec_year.rds    same, collapsed to security-year
#         data/derived/consols.rds     monthly consol yield (risk-free benchmark)
#         data/derived/build_log.rds   counts for the sample-construction table
#
# Design notes
#   * Security type is classified from the raw IMM description *in each month*
#     (not from Totaldata's static label, which is occasionally wrong: e.g.
#     id 33044 is labelled a "Sheffield & Rotherham Branch Ordinary" but is the
#     Midland's Consolidated Ordinary Stock from 1883 on).
#   * Company identity comes from the stem of Totaldata's harmonised security
#     name (e.g. "Caledonian Railway Co. Inc. 4% Debenture" -> "Caledonian
#     Railway Co. Inc."), which is stable across the 1883 change in page layout.
# ============================================================================

source("scripts/00_utils.R")
print_header("STEP 1: BUILD SECURITY PANELS")

clean_txt <- function(x) { x <- gsub("[\r\n]+", " ", x); x <- gsub("\\s+", " ", x); trimws(x) }

# ============================================================================
# 1. LOAD RAW DATA
# ============================================================================

keep_cols <- c("id", "year", "month", "page", "onpage", "region", "compsecdes", "secdes", "percentfrmsecdes",
               "capitalsubscribed", "capitalpaid", "pricemonthlate", "pricemonthhigh", "pricemonthlow",
               "yieldinvtlatepricepound", "yieldinvtlatepriceshilling", "yieldinvtlatepricepence",
               paste0("dvdlastfourratepercentannum", 1:4), paste0("ndvdlastfour", 1:4),
               paste0("dvdlastfourdmy", 1:4), "dvdlastfourfrequency")

rw <- fread(RAW_RAILWAYS, encoding = "Latin-1", select = keep_cols, colClasses = "character",
            showProgress = FALSE)
rw[, c("id", "year", "month", "page", "onpage") := lapply(.SD, as.integer), .SDcols = c("id", "year", "month", "page", "onpage")]
rw[, `:=`(region = toupper(clean_txt(region)), compsecdes = clean_txt(compsecdes),
          secdes = clean_txt(secdes))]
log_n <- list(raw_records = nrow(rw), raw_securities = uniqueN(rw$id))
cat("Raw IMM railway records:", fmti(nrow(rw)), "| securities:", fmti(uniqueN(rw$id)), "\n")

td <- fread(RAW_TOTAL, showProgress = FALSE,
            select = c("NewID", "OldID", "Name", "Year", "Month", "ISO", "Industry", "Type", "PriceMonthLate"))

# ============================================================================
# 2. COMPANY NAMES AND COUNTRY FROM THE CLEANED FILE
# ============================================================================

tdr <- unique(td[Industry == 3], by = c("OldID", "Year", "Month"))
tdr[, Name := gsub('^"|"$', "", gsub('""', '"', Name))]

company_stem <- function(n) {
  m <- regmatches(n, regexpr(paste0("^.*?\\b(Railways?|Subway|Railroad|Tramways?)\\b",
                                   "(\\s+(Joint Committee|Co\\.\\s*Ltd\\.|Co\\.\\s*Inc\\.|Co\\.|Company|Ltd\\.|Inc\\.))?"),
                             n, perl = TRUE))
  out <- rep(NA_character_, length(n)); out[regexpr("^.*?\\b(Railways?|Subway|Railroad|Tramways?)\\b", n, perl = TRUE) > 0] <- m
  out
}
names_dt <- unique(tdr[, .(NewID, Name)], by = "NewID")
names_dt[, company := trimws(company_stem(Name))]
names_dt[is.na(company), company := trimws(sub("\\s+[0-9].*$", "", Name))]   # rare unmatched names
names_dt[, name_suffix := trimws(substr(Name, nchar(company) + 1, nchar(Name)))]

dt <- merge(rw, tdr[, .(id = OldID, year = Year, month = Month, NewID, ISO, td_type = Type)],
            by = c("id", "year", "month"), all.x = TRUE)
dt <- merge(dt, names_dt, by = "NewID", all.x = TRUE)
log_n$matched_records <- dt[!is.na(NewID), .N]

# On the printed page every security of a company sits in one block headed by the
# same first line (compsecdes). A few harmonised names put a security under the
# wrong company, so each block takes the majority company of its members.
mode_chr <- function(x) { x <- x[!is.na(x)]; if (!length(x)) NA_character_ else names(which.max(table(x))) }
dt[, block_company := mode_chr(company), by = .(year, month, page, compsecdes)]
log_n$reassigned_records <- dt[!is.na(company) & company != block_company, .N]
cat("Records reassigned to their page block's company:", fmti(log_n$reassigned_records), "\n")
dt[!is.na(block_company), company := block_company]

# ============================================================================
# 3. RESTRICT TO RAILWAYS LOCATED IN GREAT BRITAIN AND IRELAND
# ============================================================================
# The Trustee Act applies to railway companies "in Great Britain or Ireland".
# Some foreign lines are registered in London (ISO = GBR), so we also drop any
# company listed mainly under a foreign, colonial, American or Indian heading.

dt[, foreign_heading := grepl("FOREIGN|COLONIAL|AMERICAN|INDIAN|DOMINION|POSS", region) &
                        !grepl("BRITISH,|BRITISH RAILWAYS|GREAT BRITAIN|GT\\. BRITAIN", region)]
# (headings occasionally spill across page breaks, so use the majority heading)
foreign_cos <- dt[!is.na(company), .(share_foreign = mean(foreign_heading)), by = company][share_foreign > 0.5, company]
br <- dt[ISO %in% c("GBR", "IRL") & !is.na(company) & !(company %in% foreign_cos)]
log_n$british_records <- nrow(br); log_n$british_securities <- uniqueN(br$id)
log_n$british_companies <- uniqueN(br$company)
cat("British & Irish railway records:", fmti(nrow(br)), "| companies:", uniqueN(br$company), "\n")

# ============================================================================
# 4. CLASSIFY EACH SECURITY-MONTH FROM ITS RAW DESCRIPTION
# ============================================================================

br[, desc := fifelse(is.na(secdes) | secdes %in% c("", "NA", "NULL"), compsecdes, secdes)]
br[, desc := sub("^(do|ditto)\\b\\.?\\s*", "", desc, ignore.case = TRUE)]
# A second ditto ("Do do 4 % (C)", transcribed as "? ? 4 % (C)") means "same kind of
# security as the line above"; such lines inherit the previous line's class below
br[, is_ditto := grepl("^(\\?|do\\b|ditto\\b|\"|'')", desc, ignore.case = TRUE)]

classify_security <- function(d) {
  d <- tolower(d)
  fcase(
    grepl("leased|rental|at [0-9 /]+ ?% ?p\\.? ?a|guar(anteed|\\.)? by|worked by", d), "leased",
    grepl("right|scrip|allot|new shares|half.?shares|quarter|contingent|warrant|instal", d), "other",
    grepl("rent.?ch|rent.?charge", d), "rentcharge",
    grepl("\\bdeb\\b|deb\\.|debenture|\\bdebs\\b|mortgage|\\bloan|\\bbonds?\\b", d), "debenture",
    grepl("guar|annuit|\\blien\\b", d), "guaranteed",
    grepl("pref(erred)?\\.?,? ?(conv|ord)|preferred ord|pref\\. ?ord|pref(erred)?\\.? converted|ord(inary)?\\.? pref", d), "pref_ordinary",
    grepl("defer|\\bdef\\b|def\\.", d), "deferred",
    grepl("pref|accum|cumul", d), "preference",
    grepl("\\bord|consols|cons(olidated)?\\.? ?st(oc)?k|original st|\\bcons(olidated)?\\.?\"?$|capital (expended|raised)", d), "ordinary",
    default = "other")
}
br[, sec_class := classify_security(desc)]

# Ditto lines inherit the class of the preceding line on the same page block
setorder(br, year, month, page, onpage, id)
class_levels <- c("leased", "other", "rentcharge", "debenture", "guaranteed", "pref_ordinary",
                  "deferred", "preference", "ordinary")
br[, cls_code := match(sec_class, class_levels)]
br[is_ditto == TRUE & sec_class == "other", cls_code := NA_integer_]
br[, cls_code := nafill(cls_code, type = "locf"), by = .(company, year, month)]
br[, sec_class := fifelse(is.na(cls_code), sec_class, class_levels[cls_code])]
br[, cls_code := NULL]

# Remaining unclassified fixed-income lines ("6 per cent. perpetual", "4 1/2 % minimum")
# take the security type recorded in the cleaned file
br[sec_class == "other" & td_type == "Preferred Stock", sec_class := "preference"]
br[sec_class == "other" & td_type == "Corporate Bond",
   sec_class := fifelse(grepl("guar|annuit|minimum", tolower(paste(desc, Name))), "guaranteed", "debenture")]

# Sub-line ordinary stocks (branches, pre-amalgamation constituent stocks) are not the
# company's ordinary capital for the dividend test
sub_line <- "branch|extension|division|\\bline\\b|section|york|leeds|berwick|malton|stockton|carlisle|scottish central|great north of england|sheffield"
br[sec_class == "ordinary" & grepl(sub_line, tolower(desc)), sec_class := "ordinary_sub"]

# Fallback: a first line with no security keywords is the company's undivided ordinary
# when the cleaned file also records it as the company's plain common stock
br[sec_class == "other" & td_type == "Common Stock" &
     (name_suffix %in% c("", "Ordinary", "Consolidated Ordinary") |
      (!grepl("[0-9]", desc) & !grepl("new|class|section|extension|\\?|same div", tolower(desc)))),
   sec_class := "ordinary"]

cat("\nSecurity-month records by class:\n"); print(br[, .N, by = sec_class][order(-N)])

# ============================================================================
# 5. PRICES, YIELDS, COUPONS
# ============================================================================

br[, `:=`(price   = to_num(pricemonthlate),
          coupon  = to_num(percentfrmsecdes),
          paid    = to_num(capitalpaid),
          capital = to_num(capitalsubscribed))]
br[is.na(price), price := (to_num(pricemonthhigh) + to_num(pricemonthlow)) / 2]
# IMM yield on investment, reported in pounds-shillings-pence per GBP 100 invested
br[, yield_imm := to_num(yieldinvtlatepricepound) + fcoalesce(to_num(yieldinvtlatepriceshilling), 0) / 20 +
                  fcoalesce(to_num(yieldinvtlatepricepence), 0) / 240]
br[yield_imm <= 0 | yield_imm > 25, yield_imm := NA]
# Coupon-based current yield for fixed-income claims (check on the IMM yield)
br[, yield_cpn := fifelse(sec_class %in% SENIOR_CLASSES & price > 0 & paid > 0, coupon * paid / price, NA_real_)]
br[yield_cpn <= 0 | yield_cpn > 25, yield_cpn := NA]
br[, yield := fcoalesce(yield_imm, yield_cpn)]

cat("\nCorrelation of IMM yield with coupon-based current yield (senior claims):",
    round(br[!is.na(yield_imm) & !is.na(yield_cpn), cor(yield_imm, yield_cpn)], 3), "\n")

# ============================================================================
# 6. CONSOL YIELD (RISK-FREE BENCHMARK)
# ============================================================================
# 3% Consols until the 1888 Goschen conversion; thereafter the 2 3/4% Consols,
# whose coupon stepped down to 2 1/2% in April 1903.

con <- td[Industry == 1 & NewID %in% c(10919, 10912), .(NewID, year = Year, month = Month, price = to_num(PriceMonthLate))]
con <- con[!is.na(price) & price > 0]
con[, coupon := fcase(NewID == 10919, 3,
                      NewID == 10912 & (year < 1903 | (year == 1903 & month < 4)), 2.75,
                      default = 2.5)]
con[, yld := coupon / price * 100]
con[, pick := fifelse(year < 1888 | (year == 1888 & month < 4), 10919L, 10912L)]
consols <- con[NewID == pick, .(year, month, consol_yield = yld)]
consols <- unique(consols, by = c("year", "month"))
cat("Consol yield months:", nrow(consols), "| range", fmt(min(consols$consol_yield)), "-",
    fmt(max(consols$consol_yield)), "\n")

br <- merge(br, consols, by = c("year", "month"), all.x = TRUE)
br[, spread_bp := (yield - consol_yield) * 100]

# Main outcome: yield relative to the median British senior railway yield in the same
# month (basis points). Government-bond prices are missing from the cleaned file for
# 1908-1914, so a month benchmark built from the railway market itself gives full
# coverage; it is equivalent to absorbing month fixed effects.
br[, mkt_yield := median(yield[sec_class %in% SENIOR_CLASSES], na.rm = TRUE), by = .(year, month)]
br[, rel_bp := (yield - mkt_yield) * 100]

# ============================================================================
# 7. SAVE MONTHLY PANEL AND COLLAPSE TO SECURITY-YEAR
# ============================================================================

setorder(br, company, id, year, month)
saveRDS(br, file.path(DERIVED_DIR, "sec_month.rds"))
saveRDS(consols, file.path(DERIVED_DIR, "consols.rds"))

mode1 <- function(x) { x <- x[!is.na(x)]; if (!length(x)) return(NA_character_); names(sort(table(x), decreasing = TRUE))[1] }
sec_year <- br[, .(sec_class   = mode1(sec_class),
                   desc        = last(desc),
                   NewID       = first(NewID),
                   ISO         = first(ISO),
                   coupon      = median(coupon, na.rm = TRUE),
                   capital     = max(capital, na.rm = TRUE),
                   price       = mean(price, na.rm = TRUE),
                   yield       = mean(yield, na.rm = TRUE),
                   spread_bp   = mean(spread_bp, na.rm = TRUE),
                   rel_bp      = mean(rel_bp, na.rm = TRUE),
                   n_months    = sum(!is.na(yield))),
               by = .(company, id, year)]
sec_year[!is.finite(capital), capital := NA]
for (v in c("price", "yield", "spread_bp", "rel_bp", "coupon")) sec_year[is.nan(get(v)), (v) := NA]
saveRDS(sec_year, file.path(DERIVED_DIR, "sec_year.rds"))
log_n$sec_years <- nrow(sec_year)
saveRDS(log_n, file.path(DERIVED_DIR, "build_log.rds"))

cat("\nSecurity-years:", fmti(nrow(sec_year)), "| with a yield:", fmti(sec_year[!is.na(yield), .N]), "\n")
print(sec_year[!is.na(yield), .(N = .N, mean_yield = round(mean(yield), 2), mean_rel_bp = round(mean(rel_bp))),
               by = sec_class][order(-N)])
cat("\nStep 1 complete.\n")
