# Descriptive Exhibits

## 📂 Directory structure

```
scripts/exhibits/
├── 04_descriptives.R     # Generates all descriptive tables and figures
├── README.md             # This file
└── QUALITY_REVIEW.md     # Data-construction and exhibit checks

output/exhibits/
├── tables/               # LaTeX tabular fragments (*.tex), notes (*_notes.tex), macros_descriptives.tex
└── figures/              # PDF (vector) + PNG (300 dpi)
```

## 🚀 Quick start

From the project root, after the data-construction scripts:

```bash
Rscript scripts/01_build_panel.R
Rscript scripts/02_running_variable.R
Rscript scripts/03_analysis_sample.R
Rscript scripts/exhibits/04_descriptives.R
```

**What it does:**
1. Reads the derived panels in `data/derived/`
2. Writes 3 tables (sample flow, summary statistics, Newey–West yield gap)
3. Writes 4 figures (PDF + PNG)
4. Writes `macros_descriptives.tex`, the sample sizes quoted in the paper

**Runtime:** under 5 seconds once `01`–`03` have run (about 45 seconds including them).

---

## 📊 Tables

### Table 1: Sample construction
**File:** `table1_sample_flow.tex`

| Stage | Observations | Companies |
|---|---|---|
| IMM railway security-months, 1869–1929 | 595,675 | |
| British and Irish railway security-months | 258,127 | 215 |
| Senior railway security-years | 16,776 | 149 |
| Post-1893 regime (main RD sample) | 3,940 | 44 |
| Pre-1888 regime (placebo sample) | 1,948 | 42 |

### Table 2: Summary statistics, 1894–1913
**File:** `table2_summary_stats.tex`

Senior securities, overall, by eligibility, and within one point of the threshold. The full sample shows that eligible securities belong to larger, higher-dividend companies and yield less (−9 bp vs. +36 bp relative to market). Within one point of the threshold the gap shrinks to about 11 bp before controlling for the running variable.

### Table 9 (appendix): Eligible-minus-ineligible yield gap over time
**File:** `table_a1_yield_gap_nw.tex`

The annual gap regressed on regime indicators. The gap widens by 26 bp after 1893 (OLS s.e. 5.9; Newey–West s.e. 6.1). This is descriptive: it mixes trustee status with company size and credit quality, which is why the paper relies on the RD.

---

## 📈 Figures

| File | Paper | Content |
|---|---|---|
| `fig1_dividend_histories` | Figure 1 | Ordinary dividend, ten-year minimum, and eligibility shading for six companies near the threshold |
| `fig2_dividend_bunching` | Figure 2 | Dividends between 1.5% and 5%, by regime and whether the ten-year record was at stake |
| `fig3_running_variable` | Figure 3 | Distribution of *X* = ten-year minimum − 3, 1894–1913 (mass at zero) |
| `fig4_yield_gap` | Figure 8 | Mean relative senior yields of eligible vs. ineligible companies, 1879–1913 |

All figures use one theme (`theme_paper()` in `scripts/00_utils.R`) and a colorblind-safe palette.

See [`QUALITY_REVIEW.md`](QUALITY_REVIEW.md) for the checks behind each exhibit.
