# ============================================================================
# Trustee Status and the Cost of Railway Capital: full replication
# ----------------------------------------------------------------------------
# Run from the project root:   Rscript scripts/run_all.R
# Requires the two IMM files in data/raw/ (see data/README.md).
# Runtime: about 10 minutes on a laptop (most of it wild-cluster bootstraps).
# ============================================================================

steps <- c(
  # --- Data construction ------------------------------------------------------
  "01_build_panel.R",                  # raw IMM records -> security-month / security-year panels
  "02_running_variable.R",             # ordinary dividends -> ten-year minimum, eligibility
  "03_analysis_sample.R",              # merges, sample restrictions, sample flow
  # --- Descriptive exhibits (output/exhibits/) --------------------------------
  "exhibits/04_descriptives.R",        # table1, table2, table_a1; fig1-fig4
  # --- Regression results (output/results/) -----------------------------------
  "results/05_rd_estimates.R",         # table3-table5; fig5-fig7
  "results/06_panel_and_iv.R",         # table6
  "results/07_dividend_management.R",  # table7
  "results/08_railways_act_1921.R"     # table8; fig8
)

for (s in steps) {
  t0 <- Sys.time()
  cat("\n>>> Running", s, "\n")
  source(file.path("scripts", s), local = new.env())
  cat(sprintf(">>> %s finished in %.1f seconds\n", s, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
cat("\nAll steps complete. Outputs in output/exhibits/ and output/results/.\n")
