# Data and Exhibits Quality Review

**Date:** November 2026
**Scope:** data construction (`scripts/01`–`03`), descriptive exhibits (`scripts/exhibits/`), and reproducibility of all results

---

## Summary

| Check | Result |
|---|---|
| Raw records loaded | ✅ 595,675 security-months, 3,302 securities (matches source file) |
| Security types classified | ✅ 98.1% of British and Irish security-months classified; 1.9% "other" (rights, scrip, new-share issues) |
| Company identity | ✅ 20,643 records corrected by page-block majority; spot-checked |
| Dividend histories vs. known record | ✅ Major companies match their known dividend paths (table below) |
| Independent dividend measures agree | ✅ Dividend correlation 0.965–0.984; eligibility agreement 99–99.8% |
| Yield measures agree | ✅ IMM printed yield vs. coupon/price: correlation 0.82 for senior claims |
| Reproducibility | ✅ A fresh clone reproduces every table, figure and quoted number exactly |
| Known limitations | ⚠️ Listed at the end |

---

## 1. Raw data and sample flow

| Stage | Observations | Companies |
|---|---|---|
| IMM railway security-months, 1869–1929 | 595,675 | |
| British and Irish railway security-months | 258,127 | 215 |
| Security-years (all types) | 22,598 | |
| Senior railway security-years | 16,776 | 149 |
| … with a yield in ≥ 3 months | 12,265 | 119 |
| … company not foreign, leased or jointly owned | 11,086 | 73 |
| … ten-year dividend record observed | 9,276 | 60 |
| … in 1879–1887 or 1894–1913 | 5,888 | 55 |
| Post-1893 regime (main RD sample) | 3,940 | 44 |
| Pre-1888 regime (placebo sample) | 1,948 | 42 |

**Checks.**
- `Totaldata.csv` ends at 1,048,575 rows, the Excel limit. The truncation falls inside the miscellaneous-companies block in 1895, and all railway rows (industry 3) are present: 594,567 cleaned rows against 595,675 raw.
- 249 duplicate (ID, year, month) keys in `Totaldata.csv` are de-duplicated before merging. `Railways_new.csv` has no duplicate keys.

## 2. Security classification

Security-months by class (British and Irish lines):

| Class | Records | | Class | Records |
|---|---|---|---|---|
| Preference | 88,171 | | Rentcharge | 7,177 |
| Debenture | 69,692 | | Leased | 6,503 |
| Ordinary | 41,255 | | Preferred ordinary | 4,984 |
| Guaranteed | 26,639 | | Other | 4,793 |
| Deferred ordinary | 7,781 | | Ordinary (sub-line) | 1,132 |

**Issues found and fixed.**
- **Static names are sometimes wrong at the security level.** ID 33044 is labeled "Midland Railway Co. Sheffield & Rotherham Branch Ordinary" in `Totaldata.csv`, but from 1883 the printed page shows it as the Midland's *Consolidated Ordinary Stock*. Classification therefore uses the raw monthly description.
- **Ditto marks.** About 19% of lines were unclassifiable before ditto lines ("Do do", transcribed `? ?`) were resolved by inheriting the previous line's type. Afterwards the figure is 1.9%.
- **Heading spill-over.** A few records of the LNWR, Midland and LSWR sit under a "Colonial Railways" heading at page breaks. Dropping any company that *ever* appeared under a foreign heading wrongly removed the largest British lines, so the rule now uses the *majority* heading.
- **London-registered foreign lines** with ISO = GBR (Lima, Sambre & Meuse, Smyrna & Cassaba, Tournay–Jurbise) and the Isle of Man are excluded by name (`config/company_exclusions.csv`).

## 3. Dividend histories

Annual ordinary dividend (% p.a., slot measure) for selected companies:

| Company | 1880 | 1890 | 1900 | 1910 |
|---|---|---|---|---|
| London & North-Western | 7.13 | 7.38 | 6.88 | 6.25 |
| North-Eastern | 7.38 | 7.50 | 6.50 | 6.00 |
| Midland | 6.13 | 6.13 | 5.50 | 5.50 |
| Great Western | 5.00 | 6.63 | 5.25 | 5.50 |
| Caledonian | 3.38 | 5.13 | 4.50 | 3.00 |
| South-Eastern | 5.63 | 5.00 | 3.37 | 3.00 |
| Great Eastern | 1.38 | 3.00 | 3.63 | 2.88 |
| Metropolitan | 5.00 | 2.88 | 3.75 | 1.13 |
| North British | 0.50 | 5.00 | 3.75 | 3.50 |

These match the familiar ranking of Victorian railway dividends: the LNWR and NER at the top, the Great Eastern and Metropolitan near or below 3%.

**Split stock.** For the Caledonian in 1895, Consolidated (undivided) 5% = preferred converted 3% + deferred converted 2%, which confirms the 1:1 recombination rule. The North British's "ordinary" line in 1895–1910 is the deferred half; the same ID reads "deferred ordinary" from 1915.

**Agreement across measures.**

| Comparison | Dividend correlation | Within 0.25 pt | Eligibility agrees |
|---|---|---|---|
| Slot vs. dated payments | 0.984 | 87.8% | 99.8% |
| Slot vs. yield-implied (rounded to 1/8) | 0.965 | 89.8% | 99% (98% within 1 pt of threshold) |

Before rounding to 1/8, the yield-implied measure returned 2.99% for many true 3.00% dividends (pence rounding in the printed yield). That misclassified exactly the firms at the threshold and produced a weak first stage (*F* = 0.2). Rounding to the declaration grid fixes it (*F* = 40).

## 4. Outcome

- The IMM printed yield and the coupon-based current yield correlate at 0.82 for senior claims. The printed yield is used, with the coupon yield as a fallback.
- **Government bond prices are absent from `Totaldata.csv` for 1908–1914** (all UK government series), and Goschen's consols are quoted only to 1902. The main outcome is therefore measured against the monthly median senior railway yield rather than consols.

## 5. Exhibits

| Exhibit | Checks |
|---|---|
| Table 1 (sample flow) | Each row is a subset of the previous; counts match the build log |
| Table 2 (summary statistics) | Eligible securities have lower and far less dispersed yields; differences shrink within 1 pt of the threshold, as expected |
| Figure 1 (dividend histories) | Shading switches exactly when the dashed ten-year minimum crosses 3% |
| Figure 2 (bunching) | Facet labels fit; at-stake post-1893 mass sits in the 3.00–3.25 bin |
| Figure 3 (running variable) | Spike at *X* = 0 (4% of company-years); consistent with the density test (*p* = 0.015) |
| Figure 4 / Table A1 (yield gap) | Gap widens by 26 bp after 1893 (Newey–West s.e. 6.1); labeled as descriptive |
| Formatting | Numbers comma-separated; units in every axis and column; colorblind-safe palette; PDF (vector) and PNG (300 dpi) |

## 6. Reproducibility

- `Rscript scripts/run_all.R` was run in a fresh clone with only the two raw files added, and reproduced every estimate exactly: rdrobust 9.8 [−1.6, 25.0]; local linear (*h* = 1) 10.7 (6.2); density *p* = 0.015; difference-in-discontinuities 9.6 (8.7); fuzzy RD 8.9 (*F* = 40); LPM interaction 0.321 (0.168); 1921 DiD −1.0 (8.3).
- All bootstrap seeds are fixed.

## ⚠️ Known limitations

1. Few companies near the threshold: 26 within one point after 1893, with 9 below it at *h* = 1.
2. The running variable is discrete (dividends in eighths) and has a mass point at zero caused by firms' own dividend management.
3. Hand-coded exclusions of leased, jointly owned and guaranteed lines involve judgment. The list and reasons are in `config/company_exclusions.csv` and can be varied.
4. Current yield ignores call features. Most railway debenture and preference stock was perpetual, so the difference from yield to maturity is small.
