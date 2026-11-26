# Methodology

This document sets out the research design in more detail than the paper's methods section. It covers the institutional rule, how each variable is constructed from the raw *Investors Monthly Manual* (IMM) records, every estimating equation, and how inference is done. Script references point to the code that implements each step.

---

## 1. The rule being studied

**Trustee Act 1893, s. 1(g)** (56 & 57 Vict. c. 53). A trustee may, unless forbidden by the trust instrument, invest in

> the debenture or rentcharge, or guaranteed or preference stock of any railway company in Great Britain or Ireland incorporated by special Act of Parliament, and having during each of the ten years last past before the date of investment paid a dividend at the rate of not less than three per centum per annum on its ordinary stock.

Four features drive the design:

| Feature | Implication |
|---|---|
| The test uses the **ordinary** dividend, but eligibility attaches to **senior** securities | The outcome (senior yields) is not mechanically a function of the running variable |
| The test is a **ten-year minimum** | One year below 3% removes eligibility for a decade, so firms have a strong incentive near the threshold |
| The rule is **public and mechanical** | Investors could compute eligibility from the same printed dividends I use |
| Leased lines qualify under **s. 1(h)**, not the dividend test | Leased, jointly owned and guaranteed lines are excluded (`config/company_exclusions.csv`) |

**Regimes.** 1879–1887 comes before the 1888–89 reforms (the placebo regime); 1888–1893 is a transition that is dropped; 1894–1913 is after the 1893 consolidation and before wartime state control (the main regime). **Railways Act 1921, s. 15** deemed each of the four amalgamated companies to have met the 3% test, which gave statutory trustee status to the stocks of constituent companies that had failed it.

---

## 2. Data construction

### 2.1 Sample of securities (`scripts/01_build_panel.R`)

1. **Load** all 595,675 IMM railway security-months (1869–1929).
2. **Link** each record to the ICF's harmonized security ID (`NewID`), name and country code in `Totaldata.csv`, by original ID × year × month.
3. **Company identity.** Take the stem of the harmonized name up to "Railway(s) Co. / Ltd. / Inc.", for example "Caledonian Railway Co. Inc. 4% Debenture" → "Caledonian Railway Co. Inc.". On the printed page every security of a company sits in one block under the same first line (`compsecdes`), so each block takes the **majority** company of its members. This corrects 20,643 records, mostly guaranteed sub-line stocks that belong to the lessee.
4. **Geography.** Keep ISO ∈ {GBR, IRL}. Drop companies listed *mainly* under foreign, colonial, American or Indian headings (headings occasionally spill across page breaks, so the rule uses the majority).
5. **Security type** is classified *each month* from the printed description, using ordered regular expressions: leased → other (rights, scrip, new shares) → rentcharge → debenture → guaranteed → preferred ordinary → deferred ordinary → preference → ordinary.
   - Ditto lines ("Do do 4 % (C)", transcribed `? ? 4 % (C)`) inherit the class of the preceding line in the same page block.
   - Remaining fixed-income lines without keywords ("6 per cent. perpetual") take the cleaned file's type.
   - Branch and constituent-line ordinary stocks are flagged as `ordinary_sub` and never used as the company's ordinary stock.

### 2.2 Prices and yields (`01_build_panel.R`)

- **Price:** the late-month price, or the mid-point of the month's high and low.
- **IMM yield:** printed in pounds-shillings-pence per £100 invested, converted as `£ + s/20 + d/240`.
- **Coupon yield** (check and fallback for senior claims): `coupon × paid / price`.
- **Outcome** `rel_bp`: yield minus the **median senior British railway yield in the same month**, × 100. Government bond prices are missing from the cleaned file for 1908–1914, so the benchmark is built from the railway market itself. It is equivalent to month fixed effects. A consol spread (`spread_bp`) is kept for descriptive use where consol prices exist.
- **Security-year** values are means over months with a valid yield; the analysis requires at least 3 such months.

### 2.3 Ordinary dividends (`scripts/02_running_variable.R`)

The IMM prints, for each security, the rates (% p.a.) of the **last four dividend payments**, oldest first; "nil" means a passed dividend (coded 0). Three measures of the annual dividend $D_{cs}$ are built:

| Measure | Construction | Role |
|---|---|---|
| **Slot** | In the latest October–December issue of year *s*, the mean of slots 3–4 (the two payments made during *s*); all four slots for quarterly payers; slot 4 for annual payers | Main measure, available every year |
| **Dated** | From 1883 each payment carries a date; collect all dated payments across issues, take the modal rate per payment, and average by calendar year | Timing check (same printed rates) |
| **Yield-implied** | `IMM yield × price / amount paid` in the late-year issue, rounded to the nearest 1/8% (dividends were declared in eighths; the yield is printed to the penny) | Instrument: transcribed from a different column |

**The company's ordinary stock in year *s*** is the ordinary-class security with the largest nominal capital. **Split stock:** several companies divided ordinary stock 1:1 into preferred and deferred halves (for the Caledonian in 1895, Consolidated 5% = preferred 3% + deferred 2%).

- If an undivided line is quoted alongside a deferred line, use the undivided line.
- If an "ordinary" line pays no more than the preferred half and no separate deferred line exists, the "ordinary" line is the deferred half (the North British, 1895–1910).
- Otherwise the undivided rate is preferred + deferred.

### 2.4 Running variable

$$X_{ct} = \min\{D_{c,t-10},\dots,D_{c,t-1}\} - 3, \qquad \text{Eligible}_{ct} = \mathbf{1}[X_{ct} \ge 0],$$

computed when at least 8 of the 10 years are observed (`min10_full` requires all 10). The same construction on the dated and yield-implied measures gives `X_dated` and `X_yld`. The variable `min9` (the minimum over $t-9$ to $t-1$) defines **AtStake**: if `min9` ≥ 3, paying below 3% in year *t* breaks a ten-year record.

---

## 3. Estimating equations

### 3.1 Dividend management (`scripts/results/07_dividend_management.R`)

Company-years with $|D_{ct} - k| < 0.5$, in 1879–1887 and 1894–1913:

$$\Pr(D_{ct} \ge k) = F\big(\alpha + \beta_1 \text{AtStake}_{ct} + \beta_2 \text{Post}_t + \beta_3\, \text{AtStake}_{ct} \times \text{Post}_t + \gamma D_{c,t-1}\big)$$

- $F$ is linear (LPM, with and without company fixed effects), logistic, or normal.
- $\beta_3$ is the extra pull toward the threshold once it has legal meaning: a difference-in-differences against the pre-rule regime.
- **Placebo thresholds:** $k \in \{2, 4, 5\}$ have no legal meaning, which separates the rule from dividend smoothing (Lintner 1956).

### 3.2 Regression discontinuity (`scripts/results/05_rd_estimates.R`)

For senior security *i* of company *c* in year *t*, 1894–1913:

$$y_{ict} = \tau\,\mathbf{1}[X_{ct}\ge 0] + \beta_1 X_{ct} + \beta_2 X_{ct}\mathbf{1}[X_{ct}\ge 0] + \delta_t + \kappa_{k(i)} + \varepsilon_{ict}, \qquad |X_{ct}| \le h$$

| Specification | Detail |
|---|---|
| `rdrobust` | Triangular kernel, MSE-optimal *h*, year and class covariates, company clusters, robust bias-corrected CI (Calonico, Cattaneo & Titiunik 2014) |
| Local linear | Uniform kernel, *h* ∈ {0.5, 1, 1.5}, year and class FE |
| Donut | Drops $0 \le X < 0.125$ (the mass of firms at exactly 3.00%) |
| Company-year | One capital-weighted observation per company-year |
| By class | Debenture/rentcharge, preference, guaranteed; ordinary stock as placebo |

**Validity.** The checks are covariate balance (coupon, log nominal amount, log ordinary capital, Irish, class shares), a density test (Cattaneo, Jansson & Ma 2020), placebo cutoffs on each side of the threshold, bandwidth sensitivity, and the same RD in 1879–1887.

**Difference-in-discontinuities** pools both regimes within $|X| \le 1$:

$$y = \ldots + \tau_{\Delta}\, \mathbf{1}[X\ge 0] \times \text{Post} + (\text{all lower-order interactions of } \mathbf{1}[X\ge0], X, \text{Post}) + \delta_t + \kappa_k$$

### 3.3 Panel and measurement error (`scripts/results/06_panel_and_iv.R`)

- **Within security:** $y_{it} = \alpha_i + \gamma_t + \beta\,\text{Eligible}_{ct} + \theta' Z_{ct} + \varepsilon_{it}$, where $Z$ = lagged dividend and ten-year mean, with company clusters and company × year two-way clusters.
- **Fuzzy RD:** use the running variable $X^{yld}$ built from the yield-implied measure, with instrument $\mathbf{1}[X^{yld} \ge 0]$ for slot-measured eligibility, within $|X^{yld}| \le 1$.
- **FE-2SLS:** instrument slot eligibility with yield-implied eligibility in the within-security model.
- Misclassification of a binary regressor is non-classical. IV with a second error-ridden measure bounds the attenuation rather than removing it (Black, Berger & Scott 2000), and the first-stage *F* is reported.

### 3.4 Railways Act 1921 (`scripts/results/08_railways_act_1921.R`)

Monthly senior yields, January 1919 to December 1922, for British companies amalgamated under the Act:

$$y_{im} = \beta\, \text{Treat}_c \times \text{Post}_m + \alpha_i + \lambda_m + \varepsilon_{im}$$

- **Treat:** the company failed the 3% test in 1921. **Post:** from royal assent (August 1921). A second specification adds White Paper → assent (July 1920 to July 1921).
- **Event study:** quarters relative to 1920Q2.
- **Matching:** each treated security is paired with the control security of the same class whose 1919 mean yield is closest (with replacement), and estimated with pair-specific fixed effects.

---

## 4. Inference

| Issue | Treatment |
|---|---|
| Securities of one company are correlated | Cluster by company throughout |
| Few clusters near the threshold (9 to the left at *h* = 1) | Restricted wild-cluster bootstrap with Webb six-point weights, 999 draws (`wild_cluster_p()` in `scripts/00_utils.R`) |
| Discrete running variable (dividends in eighths) | Reported as a caveat; estimates are stable across bandwidths and in the donut (Kolesár & Rothe 2018) |
| Four outcomes in the by-class table | Holm step-down and Romano–Wolf step-down max-*t* with a pairs cluster bootstrap that resamples companies jointly across outcomes (499 draws) |
| Serial correlation in the annual yield-gap series | Newey–West standard errors, 2 lags |

---

## 5. Reproducibility

- `Rscript scripts/run_all.R` rebuilds every table, figure and number in the paper from the two raw files.
- Every statistic quoted in the text is written by the code to `output/*/tables/macros_*.tex` and read by `paper/main.tex`, so the text cannot drift from the results.
- Random seeds are fixed for all bootstraps.
- The full pipeline has been run from a fresh clone and reproduces all estimates exactly.
