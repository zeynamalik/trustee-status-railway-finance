# Sources

## Data

- **Investors Monthly Manual, 1869–1929.** Digitized by the International Center for Finance, Yale School of Management. [London Stock Exchange data page](https://som.yale.edu/centers/international-center-for-finance/data/historical-financial-research-data/london-stock-exchange). The files used are `Railways_new.csv` and `Totaldata.csv`; see [`data/README.md`](../data/README.md). Scanned original issues are available from the same page for checking individual records.

## Statutes

| Source | Provision used | Link |
|---|---|---|
| Trust Investment Act 1889 (52 & 53 Vict. c. 32) | Earlier statutory trustee investment powers (ss. 2–6, repealed and re-enacted in 1893) | [irishstatutebook.ie](https://www.irishstatutebook.ie/eli/1889/act/32/enacted/en/print) |
| Trustee Act 1893 (56 & 57 Vict. c. 53) | s. 1(g): railway senior stock, 3% for ten years; s. 1(h): leased lines; s. 1(m): municipal stock, population > 50,000 | [irishstatutebook.ie](https://www.irishstatutebook.ie/1893/en/act/pub/0053/print.html) |
| Railways Act 1921 (11 & 12 Geo. 5 c. 55) | s. 15: amalgamated companies deemed to have paid 3% for ten years | [legislation.gov.uk](https://legislation.gov.uk/ukpga/1921/55/section/15/enacted) |
| Trustee Act 1925 (15 & 16 Geo. 5 c. 19) | Re-enacts the 3% test; names the four amalgamated companies | [legislation.gov.uk](https://www.legislation.gov.uk/ukpga/Geo5/15-16/19/enacted) |
| Railways Act 1924 (Irish Free State) | s. 11: equivalent deeming provision for the Irish amalgamation | [irishstatutebook.ie](https://www.irishstatutebook.ie/1924/en/act/pub/0029/sec0011.html) |

## Parliamentary and official documents

| Source | Used for | Link |
|---|---|---|
| HC Deb 9 May 1871, vol. 206 | Railway debenture stock "almost invariably included in modern settlements" (express powers wider than the statutory list) | [Hansard](https://api.parliament.uk/historic-hansard/commons/1871/may/09/bill-123-second-reading) |
| HC Deb 22 March 1888, vol. 324 | Proposed clause on reinvesting converted consols in railway stock | [Hansard](https://api.parliament.uk/historic-hansard/commons/1888/mar/22/national-debt-conversion-bill) |
| HL Deb 18 July 1889, vol. 338 | The 1888 bill's ten-year dividend test for railway preference shares | [Hansard](https://api.parliament.uk/historic-hansard/lords/1889/jul/18/second-reading-3) |
| Cmd. 787 (June 1920) | *Outline of Proposals as to the Future Organisation of Transport Undertakings*: the event date for the 1921 analysis | [Hansard reference](https://api.parliament.uk/historic-hansard/written-answers/1920/oct/25/transport-organisation-legislation) |
| HC Deb 21 June 1938 | Complaint that the statutory test admitted "indifferent investments, such as preference shares in some of the railways" | [Hansard](https://api.parliament.uk/historic-hansard/commons/1938/jun/21/trustee-act) |
| HC Written Answers 26 July 1939 | Railways drawing on reserves to pay a token dividend to keep prior charges trustee-eligible | [Hansard](https://api.parliament.uk/historic-hansard/written_answers/1939/jul/26/trustee-acts-railway-stocks) |

## Literature

**Related work on the London market**

- Campbell, G., R. S. Grossman and J. D. Turner (2021). Before the cult of equity: The British stock market, 1829–1929. *European Review of Economic History* 25(4).
- Chambers, D. and N. Crafts (n.d.). Late Victorian railways and investor returns. Unpublished manuscript. [PDF](https://personal.lse.ac.uk/colvinc/clio/chambers-crafts.pdf).
- Chavaz, M. and M. Flandreau (2017). "High & Dry": The liquidity and credit of colonial and foreign government debt and the London Stock Exchange (1880–1910). *Journal of Economic History* 77(3).
- Coyle, C. and J. D. Turner (2013). Law, politics, and financial development: The great reversal of the UK corporate debt market. *Journal of Economic History* 73(3).
- Goetzmann, W. N. and K. G. Rouwenhorst (2026). Capital structure, seniority, and risk premia: Evidence from the London Stock Exchange, 1870–1929. [NBER Working Paper 34899](http://www.nber.org/papers/w34899).

**Regulatory eligibility and asset prices**

- Becker, B. and V. Ivashina (2015). Reaching for yield in the bond market. *Journal of Finance* 70(5).
- Ellul, A., C. Jotikasthira and C. T. Lundblad (2011). Regulatory pressure and fire sales in the corporate bond market. *Journal of Financial Economics* 101(3).
- Kisgen, D. J. and P. E. Strahan (2010). Do regulations based on credit ratings affect a firm's cost of capital? *Review of Financial Studies* 23(12).

**Methods**

- Barreca, Lindo and Waddell (2016), *Economic Inquiry*: donut RD.
- Black, Berger and Scott (2000), *JASA*: bounds with non-classical measurement error.
- Calonico, Cattaneo and Titiunik (2014), *Econometrica*: robust bias-corrected RD.
- Cameron, Gelbach and Miller (2008), *REStat*: few-cluster bootstrap.
- Cattaneo, Jansson and Ma (2020), *JASA*: density test.
- Grembi, Nannicini and Troiano (2016), *AEJ: Applied*: difference-in-discontinuities.
- Holm (1979); Romano and Wolf (2005), *Econometrica*: multiple testing.
- Kleven (2016), *Annual Review of Economics*: bunching.
- Kolesár and Rothe (2018), *AER*: discrete running variables.
- Lee and Lemieux (2010), *JEL*: RD designs.
- Lintner (1956), *AER*: dividend smoothing.
- McCrary (2008), *J. Econometrics*: manipulation test.
- Webb (2023), *Canadian Journal of Economics*: wild-cluster bootstrap weights.

The full bibliography is in [`paper/main.tex`](../paper/main.tex).
