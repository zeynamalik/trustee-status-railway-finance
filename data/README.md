# Data

The analysis uses the **Investors Monthly Manual (IMM)**, the monthly statistical supplement to *The Economist* that recorded prices, dividends and capital for securities traded on the London Stock Exchange, 1869–1929. The digitized data are distributed by the International Center for Finance (ICF) at the Yale School of Management.

The ICF supplies the data for academic research only and prohibits redistribution, so **no data files are included in this repository**.

## Download

From the ICF's [London Stock Exchange page](https://som.yale.edu/centers/international-center-for-finance/data/historical-financial-research-data/london-stock-exchange), download and unzip:

| File | Link | Used for |
|---|---|---|
| `Railways_new.csv` | [Railways_new.csv.zip](https://som.yale.edu/sites/default/files/2021-12/Railways_new.csv.zip) | Every railway security-month: descriptions, prices, the IMM's printed yield, and the last four dividend payments |
| `Totaldata.csv` | [Totaldata.zip](https://som.yale.edu/sites/default/files/2021-12/Totaldata.zip) | Harmonized security names (company identity), country codes, and UK government bond prices |

Place both files in `data/raw/`:

```
data/raw/Railways_new.csv    # ~221 MB, 595,675 rows, 94 columns
data/raw/Totaldata.csv       # ~145 MB, 1,048,575 rows, 22 columns
```

Check them in R:

```r
library(data.table)
dim(fread("data/raw/Railways_new.csv", encoding = "Latin-1"))   # 595675 94
dim(fread("data/raw/Totaldata.csv"))                            # 1048575 22
```

## Known issues handled in the code

- **`Totaldata.csv` stops at 1,048,575 rows**, the Excel row limit. The cut falls inside the miscellaneous-companies block in 1895. Railways (industry 3) are complete, and the cleaned file is used only for railway names and for government bonds.
- **Government bond prices are missing for 1908–1914.** The main outcome is therefore measured relative to the railway market itself (see `scripts/01_build_panel.R`). Spreads over consols are kept for descriptive use where available.
- **Static names in `Totaldata.csv` are occasionally wrong at the security level.** For example, ID 33044 is labeled a branch ordinary but is the Midland's Consolidated Ordinary Stock from 1883. Security types are therefore classified from the raw monthly descriptions, and company identity is checked against the printed page block.
- **Ditto marks** ("Do do", transcribed as `? ?`) are resolved by inheriting the type of the preceding line on the page.

## Derived files

`scripts/01`–`03` write intermediate `.rds` files to `data/derived/`. These are also excluded from version control.
