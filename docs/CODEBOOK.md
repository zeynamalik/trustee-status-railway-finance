# Codebook

Intermediate datasets are written to `data/derived/` as `.rds` files (R `data.table`). They are excluded from version control because they are derived from the IMM data, which may not be redistributed. Run `scripts/01`–`03` to rebuild them.

---

## `sec_month.rds`: security-month panel (`01_build_panel.R`)

One row per British or Irish railway security per IMM issue, 1869–1929.

| Variable | Type | Definition |
|---|---|---|
| `id` | int | Original IMM security ID (`Railways_new.csv`) |
| `NewID` | int | ICF harmonized security ID (`Totaldata.csv`) |
| `year`, `month` | int | IMM issue |
| `page`, `onpage` | int | Position on the printed page (used to resolve ditto lines) |
| `company` | chr | Company, from the harmonized name stem, corrected by page-block majority |
| `ISO` | chr | Country code (GBR, IRL) |
| `region` | chr | Printed section heading |
| `compsecdes`, `secdes` | chr | Raw printed descriptions: the company's first line, and the line itself ("Do …") |
| `desc` | chr | Description used for classification (leading "Do" removed) |
| `sec_class` | chr | `debenture`, `rentcharge`, `guaranteed`, `preference`, `ordinary`, `pref_ordinary`, `deferred`, `ordinary_sub`, `leased`, `other` |
| `price` | num | Late-month price (or mid-point of high and low) |
| `coupon` | num | Fixed rate in the description (% of nominal) |
| `paid` | num | Amount paid up per unit (£) |
| `capital` | num | Nominal amount outstanding (£) |
| `yield_imm` | num | IMM printed yield on investment (%), from £/s/d |
| `yield_cpn` | num | Coupon-based current yield (%), senior claims only |
| `yield` | num | `yield_imm`, else `yield_cpn` |
| `consol_yield` | num | Current yield on Consols (%), where prices exist (not 1908–1914) |
| `spread_bp` | num | `(yield − consol_yield) × 100` |
| `mkt_yield` | num | Median senior British railway yield in the month (%) |
| `rel_bp` | num | **Main outcome:** `(yield − mkt_yield) × 100` |
| `dvdlastfour*` | chr | Raw dividend slots: rates, notes and dates of the last four payments |

## `sec_year.rds`: security-year panel (`01_build_panel.R`)

Means over the year's issues: `company`, `id`, `year`, `sec_class` (modal), `desc` (last), `NewID`, `ISO`, `coupon` (median), `capital` (max), `price`, `yield`, `spread_bp`, `rel_bp`, and `n_months` (months with a yield).

## `company_year.rds`: dividends and running variable (`02_running_variable.R`)

One row per company × year, 1869–1929.

| Variable | Definition |
|---|---|
| `div` | Annual ordinary dividend rate, slot measure (% p.a.); split stock recombined |
| `div_dated` | Annual ordinary dividend from dated payments (1883 on) |
| `div_yld` | Yield-implied ordinary dividend, rounded to 1/8 |
| `ord_id` | Security ID of the company's undivided ordinary stock that year |
| `ord_capital` | Its nominal amount (£) |
| `split_stock` | 1 if the year's dividend is preferred + deferred halves |
| `company_split` | 1 if the company ever has split stock |
| `fixed_dividend` | 1 if the dividend never varies over 10+ years (fixed rent) |
| `excluded` | 1 if listed in `config/company_exclusions.csv` or `fixed_dividend` |
| `min10` | Minimum of `div` over t−10…t−1 (≥ 8 years observed) |
| `min10_full` | Same, requiring all 10 years |
| `min10_dated`, `min10_yld` | Same, on the alternative measures |
| `min9` | Minimum over t−9…t−1 (defines AtStake) |
| `mean10`, `sd10`, `nobs10` | Mean, s.d. and count of `div` over t−10…t−1 |
| `div_lag1` | `div` in t−1 |
| `X`, `eligible` | Running variable `min10 − 3` and `1[X ≥ 0]` |
| `X_dated`, `eligible_dated` | Same, from the dated measure |
| `X_yld`, `eligible_yld` | Same, from the yield-implied measure |

## `analysis_senior.rds` and `analysis_ordinary.rds` (`03_analysis_sample.R`)

`sec_year` merged with the company-year variables above, restricted to securities with a yield in at least 3 months, companies not excluded, and an observed running variable. `analysis_senior` keeps debenture, rentcharge, guaranteed and preference stock; `analysis_ordinary` keeps each company's main ordinary stock (the placebo). Added variables:

| Variable | Definition |
|---|---|
| `period` | `pre` (1879–1887), `transition` (1888–1893), `post` (1894–1913), `war_and_after` (1914+) |
| `irish` | 1 if an Irish company (by name or ISO = IRL) |
| `log_capital` | Log nominal amount of the security |
| `log_ord_cap` | Log nominal amount of the company's ordinary stock |
| `at_stake` | 1 if `min9` ≥ 3 |

## Other derived files

| File | Content |
|---|---|
| `consols.rds` | Monthly consol yield |
| `build_log.rds`, `sample_flow.rds` | Counts used in Table 1 |
| `rd_results.rds`, `yield_gap.rds` | Stored estimates used in figures |
