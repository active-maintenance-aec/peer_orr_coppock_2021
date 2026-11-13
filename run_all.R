# peer_orr_coppock_2021/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, then the
# sample, the table and the in-text counts, then the record of what the deposit contains,
# then the ground truth and the second instrument, then the archive check again. Every
# script is self-contained and can be run alone.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Harvard Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# The sample ----
# Draws the 20 studies from the archive's study list and asserts the deposited ids.
source(here::here("maintained", "sample_20_studies.R"))

# Table 1 and the in-text counts ----
source(here::here("maintained", "table_1_computational_reproducibility.R"))
source(here::here("maintained", "text_claims.R"))

# The deposited archive as a program ----
# The deposit holds a data file and a codebook and no code, so this records that there is
# nothing to run. Nothing is ever run inside original/.
source(here::here("ground_truth", "run_archive.R"))

# Figure timestamps ----
# R's pdf() device stamps a wall-clock /CreationDate and /ModDate into every figure it
# writes. This repository writes no figure, so the sweep finds nothing, and it stays so a
# figure added later cannot break the determinism check.
source(here::here("maintained", "helpers.R"))
walk(
  list.files(here::here("maintained", "output"), pattern = "\\.pdf$", full.names = TRUE),
  blank_pdf_timestamps
)

# Ground truth ----
# Rebuilds the comparison table from the outputs above, so it cannot go stale.
# The build also runs in_text_claims.R under capture.output for the coverage
# gate; the call below is the human-readable pass.
source(here::here("ground_truth", "build_ground_truth.R"))
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The gate inside download_original.R is a precondition: sourcing it first proves original/
# was intact when the run began and says nothing about what the run did to it. Re-sourcing
# it here is what catches a script that damaged the deposit mid-run.
source(here::here("download_original.R"))
