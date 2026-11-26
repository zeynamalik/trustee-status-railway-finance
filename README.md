# Trustee Status and the Cost of Railway Capital

**Regulatory eligibility, dividend management, and bond prices in Britain, 1879–1922: an econometric analysis of the Victorian trustee-investment rules using security-level data from the *Investors Monthly Manual*.**

📄 **Paper:** [`Paper_Trustee_Status_and_the_Cost_of_Railway_Capital.pdf`](Paper_Trustee_Status_and_the_Cost_of_Railway_Capital.pdf)

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
├── README.md
├── config/
│   └── company_exclusions.csv     # hand-coded foreign / leased / jointly owned lines, with reasons
├── data/
│   ├── README.md                  # how to download the IMM files (not redistributed)
│   ├── raw/                       # Railways_new.csv, Totaldata.csv  (git-ignored)
│   └── derived/                   # intermediate .rds files            (git-ignored)
├── scripts/
│   ├── run_all.R                  # runs the full pipeline in order
│   ├── 00_utils.R                 # paths, constants, table writer, figure theme, wild bootstrap
│   ├── 01_build_panel.R           # raw IMM -> classified security-month and security-year panels
│   ├── 02_running_variable.R      # ordinary dividends (3 measures) -> 10-year minimum, eligibility
│   ├── 03_analysis_sample.R       # merges, sample restrictions, sample flow
│   ├── 04_descriptives.R          # table1, table2, table_a1; fig1-fig4
│   ├── 05_rd_estimates.R          # table3-table5; fig5-fig7 (RD, validity, multiple testing)
│   ├── 06_panel_and_iv.R          # table6 (fixed effects, fuzzy RD / 2SLS)
│   ├── 07_dividend_management.R   # table7 (LPM / logit / probit bunching tests)
│   └── 08_railways_act_1921.R     # table8; fig8 (difference-in-differences, event study)
├── output/
│   ├── tables/                    # LaTeX table fragments, notes, and macros_*.tex (numbers in the text)
│   └── figures/                   # PDF (vector) and PNG (300 dpi) figures
└── paper/
    └── main.tex                   # paper source; reads every number from output/tables/macros_*.tex
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

The IMM data are distributed by the International Center for Finance at Yale for academic use and **may not be redistributed**, so they are not in this repository. See [`data/README.md`](data/README.md) for download links. In short, put `Railways_new.csv` and `Totaldata.csv` in `data/raw/`.

---

## Usage

From the project root:

```bash
Rscript scripts/run_all.R            # about 10 minutes, mostly wild-cluster bootstraps
cd paper && latexmk -pdf main.tex     # optional: rebuild the paper
```

Each script can also be run on its own, in order. Scripts 01–03 write intermediate files to `data/derived/`, and scripts 04–08 read them.

---

## Methodology

### Running variable

For company *c* in year *t*, with *D* the annual dividend rate on undivided ordinary stock:

```
X_ct = min(D_c,t-10, ..., D_c,t-1) - 3          senior securities eligible iff X_ct >= 0
```

Three independent constructions of *D* are built:

| Measure | Source | Role |
|---|---|---|
| **Slot** | Two most recent of the "last four dividends" in the autumn/December issue | Main measure |
| **Dated** | Dated payments (1883+), averaged by calendar year | Consistency check (same printed rates) |
| **Yield-implied** | The IMM's printed yield × price ÷ amount paid, rounded to 1/8 | Instrument for misclassification (separately transcribed column) |

Split stock (1:1 preferred + deferred ordinary) is recombined, and leased or jointly owned lines are excluded (`config/company_exclusions.csv`).

### Outcome

The outcome is each senior security's current yield relative to the median British senior railway yield in the same month, in basis points. Government bond prices are missing from the cleaned file for 1908–1914, so the benchmark comes from the railway market itself. Year fixed effects are also included.

### Designs

| Design | Specification | ECON 1117 / 2123 tools |
|---|---|---|
| Dividend management | `Pr(D >= 3) = F(AtStake x Post + ...)` on dividends within 0.5 pt of 3%; placebo thresholds 2, 4, 5% | LPM, logit, probit; difference-in-differences |
| Regression discontinuity | Local linear at X = 0, year + class FE, h ∈ {MSE-opt, 0.5, 1, 1.5}, donut | RD, bandwidth choice, density test, covariate balance, placebo cutoffs |
| Difference-in-discontinuities | RD in 1894–1913 minus RD in 1879–1887 | Quasi-experimental design |
| Panel | Security + year FE as companies cross the threshold | Panel fixed effects, two-way clustering |
| Measurement error | Fuzzy RD / FE-2SLS instrumenting slot eligibility with yield-implied eligibility | IV, 2SLS, weak-instrument F |
| Railways Act 1921 | Monthly DiD and quarterly event study; nearest-neighbor matched controls | DiD, event study, matching |
| Inference | Company clusters, wild-cluster bootstrap (Webb weights), Holm and Romano–Wolf, Newey–West | Clustering, few clusters, multiple testing, time series |

---

## Output guide

### Tables (`output/tables/`)

| File | Paper | Content |
|---|---|---|
| `table1_sample_flow` | Table 1 | Sample construction |
| `table2_summary_stats` | Table 2 | Senior securities, 1894–1913, by eligibility and near the threshold |
| `table7_dividend_management` | Table 3 | LPM / logit / probit bunching tests and placebo thresholds |
| `table3_rd_main` | Table 4 | RD estimates (rdrobust; local linear h = 0.5, 1, 1.5; donut; company-year) |
| `table4_rd_validity` | Table 5 | Covariate balance, density test, placebo cutoffs, pre-period RD, difference-in-discontinuities |
| `table5_rd_by_class` | Table 6 | RD by security class with Holm and Romano–Wolf p-values |
| `table6_panel_iv` | Table 7 | Within-security FE; fuzzy RD and FE-2SLS with first-stage F |
| `table8_railways_act` | Table 8 | 1921 Act difference-in-differences (all and matched) |
| `table_a1_yield_gap_nw` | Table 9 | Eligible-minus-ineligible yield gap, Newey–West |
| `macros_*.tex` | — | Every statistic quoted in the paper, as LaTeX macros |

Each table's notes are in a companion `*_notes.tex` file.

### Figures (`output/figures/`, PDF + PNG)

| File | Paper | Content |
|---|---|---|
| `fig1_dividend_histories` | Figure 1 | Dividend records and eligibility, six companies |
| `fig2_dividend_bunching` | Figure 2 | Dividends near 3% by regime and whether the record was at stake |
| `fig3_running_variable` | Figure 3 | Distribution of X (mass at zero) |
| `fig5_rd_plot` | Figure 4 | RD plots, 1894–1913 and 1879–1887 |
| `fig6_bandwidth` | Figure 5 | Bandwidth sensitivity |
| `fig7_placebo_cutoffs` | Figure 6 | Placebo thresholds |
| `fig8_event_study` | Figure 7 | Railways Act 1921 event study |
| `fig4_yield_gap` | Figure 8 | Eligible vs. ineligible senior yields, 1879–1913 |

---

## Data-construction notes

These are the main judgment calls, each documented in the code:

- **Security types come from the raw monthly descriptions**, not from the cleaned file's static labels, which are occasionally wrong. For example, ID 33044 is the Midland's Consolidated Ordinary Stock but is labeled a branch line.
- **Ditto lines** ("Do do", transcribed `? ?`) inherit the type of the line above on the page.
- **Company identity** comes from the harmonized names, corrected by majority vote within each printed page block.
- **Foreign lines** registered in London, the Isle of Man (outside "Great Britain or Ireland"), and **leased, jointly owned or guaranteed lines** (which qualify under s.1(h), not the dividend test) are excluded by a hand-coded, documented list.
- **Pence rounding** in the printed yield is undone by rounding the yield-implied dividend to the nearest 1/8%.

---

## AI assistance

This project was developed with the assistance of an AI model (Claude, Anthropic), which helped write and debug the code and draft the text. All design choices, results and interpretations should be checked by the reader against the code, which runs end to end from the public data.

---

## Contact

**Author:** Zeyna Malik
**Institution:** Yale University

Questions about the code or methodology are welcome as GitHub issues.

---

## Acknowledgments

- **Data:** International Center for Finance, Yale School of Management, for digitizing and distributing the *Investors Monthly Manual*.
- **Template:** Repository layout follows [321gonzalezj/HMDA-Mortgage-Lending-Analysis](https://github.com/321gonzalezj/HMDA-Mortgage-Lending-Analysis).
- **Tools:** R with `data.table`, `fixest`, `rdrobust`, `rddensity`, `sandwich` and `ggplot2`.

## Selected references

- Calonico, S., M. D. Cattaneo, and R. Titiunik (2014). Robust nonparametric confidence intervals for regression-discontinuity designs. *Econometrica* 82(6).
- Chavaz, M. and M. Flandreau (2017). "High & Dry": The liquidity and credit of colonial and foreign government debt and the London Stock Exchange (1880–1910). *Journal of Economic History* 77(3).
- Goetzmann, W. N. and K. G. Rouwenhorst (2026). Capital structure, seniority, and risk premia: Evidence from the London Stock Exchange, 1870–1929. NBER Working Paper 34899.
- Kisgen, D. J. and P. E. Strahan (2010). Do regulations based on credit ratings affect a firm's cost of capital? *Review of Financial Studies* 23(12).
- Trustee Act 1893 (56 & 57 Vict. c. 53), s. 1(g); Railways Act 1921 (11 & 12 Geo. 5 c. 55), s. 15.
