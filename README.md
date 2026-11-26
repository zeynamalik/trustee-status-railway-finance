# Trustee Status and the Cost of Railway Capital

**Regulatory eligibility, dividend management, and bond prices in Britain, 1879–1922: an econometric analysis of the Victorian trustee-investment rules using security-level data from the *Investors Monthly Manual*.**

📄 **Paper:** [`Paper_Trustee_Status_and_the_Cost_of_Railway_Capital.pdf`](Paper_Trustee_Status_and_the_Cost_of_Railway_Capital.pdf) · 📘 **Methodology:** [`docs/METHODOLOGY.md`](docs/METHODOLOGY.md)

---

## Overview

Under the Trustee Act 1893, British trustees could buy a railway's debenture, rentcharge, guaranteed or preference stock only if the company had paid **at least 3% on its ordinary stock in each of the previous ten years**. This sharp, public rule makes it possible to ask whether eligibility for a regulated class of investors lowers the cost of infrastructure finance. The question still matters for insurance capital rules, bank liquidity rules, and central-bank collateral lists.

The repository rebuilds ten-year dividend records for British and Irish railway companies from 595,675 IMM security-months (1869–1929) and asks:

1. **Firm behavior:** Did railway boards manage dividends to keep trustee status?
2. **Prices:** Did eligibility lower the yields of the senior securities it covered?
3. **A statutory test:** When the Railways Act 1921 granted trustee status by law to every company in the 1923 amalgamation, did the newly eligible securities reprice?

### Key findings

1. **Boards managed dividends to keep trustee status.** After 1893, of 34 company-years whose ten-year record was at stake and whose dividend fell within half a point of 3%, only 2 paid below 3%, and 47% paid exactly 3.00% (vs. 5% with nothing at stake). Relative to 1879–1887, when 3% had no legal meaning, the probability of paying at least 3% when the record was at stake rose by **0.32** (LPM, s.e. 0.17), or **0.96** with company fixed effects (s.e. 0.25). Logit and probit agree. Placebo thresholds at 2%, 4% and 5% show nothing (0.08, −0.09, 0.09).
2. **Eligibility did not lower senior yields.** The RD estimate at the threshold is small and *positive*: **+10.7 bp** (s.e. 6.2, 95% CI [−1.5, 22.9]) at h = 1, and +9.8 bp with rdrobust (robust CI [−1.6, 25.0]). The jump does not become more negative relative to 1879–1887 (difference-in-discontinuities +9.6, s.e. 8.7), survives a donut that drops the bunched companies (+5.1), and holds in a fuzzy RD that corrects misclassification with an independently transcribed dividend measure (+8.9, first-stage F = 40).
3. **Statutory trustee status in 1921 did not reprice senior stock on average.** Companies that qualified only through s.15 of the Railways Act 1921 saw yields move **−1.0 bp** relative to companies that already qualified (s.e. 8.3, wild-bootstrap p = 0.93), or +7.2 bp with matched controls.
4. **Interpretation:** the legal list changed *corporate behavior* without measurably changing *prices* at the margin. That fits a rule that was slack for marginal companies: trust deeds often granted wider powers, and trustees favored first-class stocks far above the threshold.


---

## Repository structure

```
trustee-status-railway-finance/
├── Paper_Trustee_Status_and_the_Cost_of_Railway_Capital.pdf
├── README.md                         # This file
│
├── docs/                             # Documentation for reviewers
│   ├── METHODOLOGY.md                # Rule, variable construction, equations, inference
│   ├── CODEBOOK.md                   # Every variable in the derived datasets
│   └── SOURCES.md                    # Statutes, Hansard, literature (with links)
│
├── config/
│   └── company_exclusions.csv        # Hand-coded foreign / leased / jointly owned lines, with reasons
│
├── data/                             # Data files (NOT in GitHub; see data/README.md)
│   ├── README.md                     # Download instructions and known data issues
│   ├── raw/                          # Railways_new.csv, Totaldata.csv
│   └── derived/                      # Intermediate .rds panels
│
├── scripts/                          # R analysis scripts
│   ├── run_all.R                     # Runs the full pipeline in order
│   ├── 00_utils.R                    # Paths, constants, table writer, figure theme, wild bootstrap
│   ├── 01_build_panel.R              # Raw IMM -> classified security-month / security-year panels
│   ├── 02_running_variable.R         # Ordinary dividends (3 measures) -> ten-year minimum, eligibility
│   ├── 03_analysis_sample.R          # Merges, sample restrictions, sample flow
│   ├── exhibits/                     # Descriptive statistics
│   │   ├── 04_descriptives.R         # Tables 1, 2, 9; Figures 1-3, 8
│   │   ├── README.md
│   │   └── QUALITY_REVIEW.md         # Data-construction and exhibit checks
│   └── results/                      # Regression results
│       ├── 05_rd_estimates.R         # RD, validity, multiple testing (Tables 4-6; Figures 4-6)
│       ├── 06_panel_and_iv.R         # Fixed effects, fuzzy RD / 2SLS (Table 7)
│       ├── 07_dividend_management.R  # LPM / logit / probit bunching tests (Table 3)
│       ├── 08_railways_act_1921.R    # DiD, event study, matching (Table 8; Figure 7)
│       └── README.md
│
├── output/                           # Generated outputs
│   ├── exhibits/{tables,figures}/    # Descriptive tables (.tex) and figures (PDF + PNG)
│   └── results/{tables,figures}/     # Regression tables (.tex) and figures (PDF + PNG)
│
└── paper/
    └── main.tex                      # Paper source; every quoted number is read from output/*/tables/macros_*.tex
```

---

## Getting started

### Prerequisites

**Software:** R 4.1 or later (developed with R 4.3.3). LaTeX is needed only to rebuild the PDF.

**R packages:**

```r
install.packages(c(
  "data.table",   # fast data manipulation
  "fixest",       # fixed-effects OLS, IV, logit/probit with clustered SEs
  "rdrobust",     # local polynomial RD with robust bias-corrected inference
  "rddensity",    # manipulation (density) test
  "sandwich",     # Newey-West standard errors
  "ggplot2"       # figures (PDF export uses cairo)
))
```

**System:** about 2 GB of RAM; the raw files are about 370 MB.

### Data setup

The IMM data are distributed by the International Center for Finance at Yale for academic use and **may not be redistributed**, so they are not in this repository. Download `Railways_new.csv` and `Totaldata.csv` from the ICF (links in [`data/README.md`](data/README.md)) and place them in `data/raw/`.

---

## Usage

From the project root:

```bash
Rscript scripts/run_all.R             # full pipeline, about 10 minutes
cd paper && latexmk -pdf main.tex     # optional: rebuild the paper
```

| Step | Script | Runtime | Output |
|---|---|---|---|
| 1. Build panels | `scripts/01_build_panel.R` | ~40 s | `data/derived/sec_month.rds`, `sec_year.rds` |
| 2. Running variable | `scripts/02_running_variable.R` | ~10 s | `data/derived/company_year.rds` |
| 3. Analysis samples | `scripts/03_analysis_sample.R` | <1 s | `data/derived/analysis_*.rds` |
| 4. Descriptive exhibits | `scripts/exhibits/04_descriptives.R` | ~3 s | `output/exhibits/` |
| 5–8. Results | `scripts/results/05`–`08` | ~8 min | `output/results/` |

---

## Methodology in brief

**Running variable.** For company *c* in year *t*, with *D* the annual dividend rate on undivided ordinary stock:

```
X_ct = min(D_c,t-10, ..., D_c,t-1) - 3          senior securities eligible iff X_ct >= 0
```

*D* is built three ways: from the printed "last four dividends" (main), from dated payments (timing check), and from the IMM's printed yield × price (an independently transcribed instrument).

**Outcome.** Each senior security's current yield relative to the median British senior railway yield in the same month, in basis points.

| Design | Specification | Econometric tools |
|---|---|---|
| Dividend management | `Pr(D >= 3) = F(AtStake x Post + ...)`, dividends within 0.5 pt of 3%; placebo thresholds 2, 4, 5% | LPM, logit, probit; difference-in-differences |
| Regression discontinuity | Local linear at X = 0, year + class FE; h ∈ {MSE-optimal, 0.5, 1, 1.5}; donut | RD, bandwidth choice, density test, covariate balance, placebo cutoffs |
| Difference-in-discontinuities | RD in 1894–1913 minus RD in 1879–1887 | Quasi-experimental design |
| Panel | Security + year FE as companies cross the threshold | Fixed effects, two-way clustering |
| Measurement error | Fuzzy RD / FE-2SLS with the independent dividend measure | IV, 2SLS, weak-instrument F |
| Railways Act 1921 | Monthly DiD, quarterly event study, nearest-neighbor matching | DiD, event study, matching |
| Inference | Company clusters; wild-cluster bootstrap; Holm and Romano–Wolf; Newey–West | Few clusters, multiple testing, serial correlation |

Full equations and choices are in [`docs/METHODOLOGY.md`](docs/METHODOLOGY.md); variable definitions are in [`docs/CODEBOOK.md`](docs/CODEBOOK.md).

---

## Output guide

### Tables

| File | Paper | Content |
|---|---|---|
| `exhibits/tables/table1_sample_flow` | Table 1 | Sample construction |
| `exhibits/tables/table2_summary_stats` | Table 2 | Senior securities, 1894–1913, by eligibility and near the threshold |
| `results/tables/table7_dividend_management` | Table 3 | LPM / logit / probit bunching tests and placebo thresholds |
| `results/tables/table3_rd_main` | Table 4 | RD estimates (rdrobust; local linear h = 0.5, 1, 1.5; donut; company-year) |
| `results/tables/table4_rd_validity` | Table 5 | Balance, density test, placebo cutoffs, pre-period RD, difference-in-discontinuities |
| `results/tables/table5_rd_by_class` | Table 6 | RD by security class with Holm and Romano–Wolf p-values |
| `results/tables/table6_panel_iv` | Table 7 | Within-security FE; fuzzy RD and FE-2SLS with first-stage F |
| `results/tables/table8_railways_act` | Table 8 | 1921 Act difference-in-differences (all and matched) |
| `exhibits/tables/table_a1_yield_gap_nw` | Table 9 | Eligible-minus-ineligible yield gap, Newey–West |

Each table has a companion `*_notes.tex`. The `macros_*.tex` files hold every statistic quoted in the paper.

### Figures (PDF + PNG)

| File | Paper | Content |
|---|---|---|
| `exhibits/figures/fig1_dividend_histories` | Figure 1 | Dividend records and eligibility, six companies |
| `exhibits/figures/fig2_dividend_bunching` | Figure 2 | Dividends near 3% by regime and whether the record was at stake |
| `exhibits/figures/fig3_running_variable` | Figure 3 | Distribution of X (mass at zero) |
| `results/figures/fig5_rd_plot` | Figure 4 | RD plots, 1894–1913 and 1879–1887 |
| `results/figures/fig6_bandwidth` | Figure 5 | Bandwidth sensitivity |
| `results/figures/fig7_placebo_cutoffs` | Figure 6 | Placebo thresholds |
| `results/figures/fig8_event_study` | Figure 7 | Railways Act 1921 event study |
| `exhibits/figures/fig4_yield_gap` | Figure 8 | Eligible vs. ineligible senior yields, 1879–1913 |

---

## Data-construction notes

These are the main judgment calls, each documented in the code and in [`scripts/exhibits/QUALITY_REVIEW.md`](scripts/exhibits/QUALITY_REVIEW.md):

- **Security types come from the raw monthly descriptions**, not from the cleaned file's static labels, which are occasionally wrong.
- **Ditto lines** ("Do do", transcribed `? ?`) inherit the type of the line above on the page.
- **Company identity** comes from harmonized names, corrected by majority vote within each printed page block.
- **Split ordinary stock** (1:1 preferred + deferred halves) is recombined to the undivided rate.
- **Foreign lines** registered in London, the Isle of Man, and **leased, jointly owned or guaranteed lines** (which qualify under s.1(h), not the dividend test) are excluded by a documented list.
- **Pence rounding** in the printed yield is undone by rounding the yield-implied dividend to the nearest 1/8%.

---

## Project checklist

Before running:
- [ ] Downloaded `Railways_new.csv` and `Totaldata.csv` into `data/raw/`
- [ ] Installed the R packages above

To reproduce the paper:
- [ ] `Rscript scripts/run_all.R`
- [ ] Check `output/exhibits/` and `output/results/`
- [ ] `cd paper && latexmk -pdf main.tex`

---

## Contact

**Author:** Zeyna Malik
**Institution:** Yale University

Questions about the code or methodology are welcome as GitHub issues.

---

## Acknowledgments

- **Data:** International Center for Finance, Yale School of Management, for digitizing and distributing the *Investors Monthly Manual*.
- **Tools:** R with `data.table`, `fixest`, `rdrobust`, `rddensity`, `sandwich` and `ggplot2`.

## Selected references

- Calonico, S., M. D. Cattaneo, and R. Titiunik (2014). Robust nonparametric confidence intervals for regression-discontinuity designs. *Econometrica* 82(6).
- Chavaz, M. and M. Flandreau (2017). "High & Dry": The liquidity and credit of colonial and foreign government debt and the London Stock Exchange (1880–1910). *Journal of Economic History* 77(3).
- Goetzmann, W. N. and K. G. Rouwenhorst (2026). Capital structure, seniority, and risk premia: Evidence from the London Stock Exchange, 1870–1929. NBER Working Paper 34899.
- Kisgen, D. J. and P. E. Strahan (2010). Do regulations based on credit ratings affect a firm's cost of capital? *Review of Financial Studies* 23(12).
- Trustee Act 1893 (56 & 57 Vict. c. 53), s. 1(g); Railways Act 1921 (11 & 12 Geo. 5 c. 55), s. 15.

The full source list is in [`docs/SOURCES.md`](docs/SOURCES.md).
