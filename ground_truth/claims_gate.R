# peer_orr_coppock_2021/ground_truth/claims_gate.R
# Output: none; defines `printed`, the CLAIM lines parsed from in_text_claims.R, in its environment
# Depends on: maintained/in_text_claims.R, ground_truth/published_claims.csv
# Description: The coverage gate. Runs the second instrument as a program, non-interactively,
#   and asserts that the claims it printed are exactly the extraction's needs_block rows,
#   that none ended on a failing verdict, and that the counts reconcile. Sourced by
#   build_ground_truth.R into its own environment.

library(here)
library(tidyverse)

here::i_am("ground_truth/claims_gate.R")

extraction <- read_csv(here::here("ground_truth", "published_claims.csv"),
                       col_types = cols(.default = col_character(), needs_block = col_logical()))

claims_log <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env()),
  type = "output"
)

line_pattern <- "^CLAIM ([A-Za-z0-9_]+) = (.*?) \\|\\| \\[([A-Za-z]+)\\] "
printed <- claims_log |>
  keep(\(x) str_detect(x, line_pattern)) |>
  str_match(line_pattern) |>
  as_tibble(.name_repair = ~ c("line", "claim_id", "printed", "verdict")) |>
  select(-line)

required <- extraction |> filter(needs_block) |> pull(claim_id)

# Changing one claim's needs_block is a three-file edit: the extraction row, the block, and
# the ground-truth row. A count mismatch here usually means one of the three was missed,
# not that a block was deleted.
stopifnot(
  !anyDuplicated(printed$claim_id),
  setequal(printed$claim_id, required),
  !any(printed$verdict %in% c("MISMATCH", "STALE", "DRIFT", "MISSING"))
)

summary_line <- claims_log |> keep(\(x) str_detect(x, "^CLAIM SUMMARY: printed=")) 
stopifnot(length(summary_line) == 1, str_detect(summary_line, str_c("printed=", nrow(printed), " ")),
          str_detect(summary_line, "failed=0"))
