# ============================================================================
# Trustee Status and the Cost of Railway Capital: full replication
# ----------------------------------------------------------------------------
# Run from the project root:   Rscript scripts/run_all.R
# Requires the two IMM files in data/raw/ (see data/README.md).
# Runtime: about 10 minutes on a laptop (most of it wild-cluster bootstraps).
# ============================================================================

steps <- c("01_build_panel.R",          # raw IMM records -> security-month / security-year panels
           "02_running_variable.R",     # ordinary dividends -> ten-year minimum, eligibility
           "03_analysis_sample.R",      # merge, sample restrictions, sample flow
           "04_descriptives.R",         # table1, table2, table_a1; fig1-fig4
           "05_rd_estimates.R",         # table3-table5; fig5-fig7
           "06_panel_and_iv.R",         # table6
           "07_dividend_management.R",  # table7
           "08_railways_act_1921.R")    # table8; fig8

for (s in steps) {
  t0 <- Sys.time()
  cat("\n>>> Running", s, "\n")
  source(file.path("scripts", s), local = new.env())
  cat(sprintf(">>> %s finished in %.1f seconds\n", s, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
cat("\nAll steps complete. Tables in output/tables/, figures in output/figures/.\n")
