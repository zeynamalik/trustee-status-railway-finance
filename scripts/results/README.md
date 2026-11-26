# Results: Regression Tables & Figures

## 📂 Directory structure

```
scripts/results/
├── 05_rd_estimates.R          # Regression discontinuity, validity, multiple testing
├── 06_panel_and_iv.R          # Within-security fixed effects; fuzzy RD and FE-2SLS
├── 07_dividend_management.R   # Bunching at the threshold: LPM / logit / probit
└── 08_railways_act_1921.R     # Railways Act 1921: difference-in-differences and event study

output/results/
├── tables/    # LaTeX tabular fragments (*.tex), notes (*_notes.tex), macros_*.tex
└── figures/   # PDF (vector) + PNG (300 dpi)
```

## 🚀 Quick start

From the project root, after running the data-construction scripts `01`–`03`:

```bash
Rscript scripts/results/05_rd_estimates.R
Rscript scripts/results/06_panel_and_iv.R
Rscript scripts/results/07_dividend_management.R
Rscript scripts/results/08_railways_act_1921.R
```

Or run everything with `Rscript scripts/run_all.R`. Runtime is about 8 minutes, most of it in the wild-cluster bootstraps of `05` and `08`.

---

## 📊 Tables

### Table 3 (paper): Dividend management at the 3% threshold
**Script:** `07_dividend_management.R` → `table7_dividend_management.tex`

Company-years with an ordinary dividend within 0.5 points of threshold *k*. The dependent variable is 1[dividend ≥ *k*]. Columns 1–4 use *k* = 3 (LPM, LPM with company FE, logit, probit); columns 5–7 are placebo thresholds *k* = 2, 4, 5.

| | LPM | LPM + FE | Logit | Probit | *k*=2 | *k*=4 | *k*=5 |
|---|---|---|---|---|---|---|---|
| At stake × post-1893 | 0.321* | 0.958*** | 2.248*** | 1.245** | 0.078 | −0.090 | 0.091 |

After 1893, 47% of company-years with the record at stake paid exactly 3.00%, against 5% of those without.

### Table 4 (paper): Main RD estimates
**Script:** `05_rd_estimates.R` → `table3_rd_main.tex`

| | rdrobust | *h*=0.5 | *h*=1 | *h*=1.5 | Donut | Company-year |
|---|---|---|---|---|---|---|
| Eligible (bp) | 9.8 | 5.5 | 10.7 | 5.4 | 5.1 | 9.1 |
| s.e. | (6.8) | (7.2) | (6.2) | (5.1) | (5.8) | (7.9) |
| 95% CI | [−1.6, 25.0] | [−8.7, 19.6] | [−1.5, 22.9] | [−4.5, 15.4] | [−6.2, 16.4] | [−6.3, 24.6] |

### Table 5 (paper): Validity
**Script:** `05_rd_estimates.R` → `table4_rd_validity.tex`

- **A.** Covariate balance at *h* = 1.
- **B.** Density test: *p* = 0.015, reflecting the bunching at exactly *X* = 0.
- **C.** Placebo cutoffs at ±0.5 and ±1.
- **D.** RD in 1879–1887 (+1.0, s.e. 5.1) and the difference-in-discontinuities (+9.6, s.e. 8.7).

### Table 6 (paper): By security class, with multiple-testing corrections
**Script:** `05_rd_estimates.R` → `table5_rd_by_class.tex`

Debenture/rentcharge, preference, guaranteed, and ordinary stock (placebo). Reports cluster, wild-bootstrap, Holm and Romano–Wolf *p*-values; no senior class is significant after correction.

### Table 7 (paper): Panel and IV
**Script:** `06_panel_and_iv.R` → `table6_panel_iv.tex`

Within-security FE (5 switching companies); a fuzzy RD instrumenting slot eligibility with yield-implied eligibility (first stage 0.84, *F* = 40; 2SLS +8.9, s.e. 6.7); and FE-2SLS.

### Table 8 (paper): Railways Act 1921
**Script:** `08_railways_act_1921.R` → `table8_railways_act.tex`

DiD of newly eligible vs. already-eligible amalgamated companies: −1.0 bp (s.e. 8.3, wild *p* = 0.93). Matched estimate: +7.2 (s.e. 6.0).

---

## 📈 Figures

| File | Paper | Content |
|---|---|---|
| `fig5_rd_plot` | Figure 4 | Binned senior yields against *X*, 1894–1913 and 1879–1887, with local linear fits |
| `fig6_bandwidth` | Figure 5 | RD estimate and 95% CI for *h* from 0.5 to 2 |
| `fig7_placebo_cutoffs` | Figure 6 | Estimates at false thresholds (true threshold highlighted) |
| `fig8_event_study` | Figure 7 | Quarterly event study around the 1920 White Paper and the 1921 Act |

---

## 🔢 Numbers in the paper

Each script writes the statistics quoted in the text to `output/results/tables/macros_<step>.tex`, for example `\newcommand{\rdTauHone}{10.7}`. `paper/main.tex` reads these files, so every number in the text is produced by the code.

## ⚙️ Inference choices

- Standard errors are clustered by company.
- Wild-cluster bootstrap *p*-values (restricted, Webb weights, 999 draws) are reported because only 9–12 companies lie just below the threshold.
- `rdrobust` reports robust bias-corrected intervals.
- Romano–Wolf resamples companies jointly across outcomes (499 draws).
- Seeds are fixed, so results reproduce exactly.

See [`docs/METHODOLOGY.md`](../../docs/METHODOLOGY.md) for full equations.
