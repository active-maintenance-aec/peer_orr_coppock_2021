# peer_orr_coppock_2021/ground_truth/build_ground_truth.R
# Output: ground_truth/peer_orr_coppock_2021_ground_truth.csv, ground_truth/float_coverage.csv
# Depends on: ground_truth/published_claims.csv, ground_truth/published_maintext_tables.csv,
#   maintained/output/, errata_entries.csv, ground_truth/claims_gate.R, excheckr
# Description: Assemble the ground truth from the two transcriptions of the article and the
#   pipeline's output. The only typed numbers are the article's own, read into the two
#   transcription files; every value_rewrite is read out of maintained/output/. The deposit
#   holds no code, so value_script and match are NA on every row. The build stops on any
#   published value with no counterpart in the rewrite and on any rewrite cell nothing
#   compares against, and it refuses an adverse row without a named locus.

library(here)
library(tidyverse)
library(excheckr)

here::i_am("ground_truth/build_ground_truth.R")

# Readers ----
# value_paper is read as character everywhere: a double would drop the printed zeros.
claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(.default = col_character(), needs_block = col_logical(),
                                    digits = col_integer()))
cells <- read_csv(here::here("ground_truth", "published_maintext_tables.csv"),
                  col_types = cols(.default = col_character()))
spine <- read_csv(here::here("errata_entries.csv"), col_types = cols(.default = col_character()))

out <- \(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)
text_counts <- out("text_counts.csv")
table_1 <- out("table_1_computational_reproducibility.csv")
sampling_check <- out("sampling_check.csv")

counts <- deframe(text_counts)
stopifnot(!anyDuplicated(text_counts$quantity))

# One join helper: both sides unique on the key and the result one to one ----
join_exact <- function(x, y, by) {
  stopifnot(!anyDuplicated(x[by]), !anyDuplicated(y[by]))
  anti_x <- anti_join(x, y, by = by)
  anti_y <- anti_join(y, x, by = by)
  list(joined = inner_join(x, y, by = by, relationship = "one-to-one"), only_x = anti_x, only_y = anti_y)
}

render <- function(value, digits) {
  out <- sprintf("%.*f", digits, value)
  sub("^-(0(\\.0*)?)$", "\\1", out)
}

# Table 1's cells ----
rewrite_cells <- table_1 |>
  mutate(share_pct = 100 * share) |>
  pivot_longer(c(n, share_pct), names_to = "statistic", values_to = "value_rewrite") |>
  mutate(statistic = recode(statistic, share_pct = "pct")) |>
  bind_rows(distinct(table_1, column, n_column) |>
              mutate(row_label = "N", statistic = "n_column", value_rewrite = n_column) |>
              select(column, row_label, statistic, value_rewrite)) |>
  select(column, row_label, statistic, value_rewrite)

cell_join <- join_exact(cells, rewrite_cells, c("column", "row_label", "statistic"))

# Every published cell has a rewrite counterpart. The reverse direction has one named
# exemption: the rewrite computes a percentage for the two archive-added rows that print a
# bare 0, and the article prints no percentage there.
stopifnot(nrow(cell_join$only_x) == 0)
exempt_rewrite_cells <- tribble(
  ~column, ~row_label, ~statistic,
  "Archive added code", "Errors requiring further information", "pct",
  "Archive added code", "Data-preparation scripts not archived", "pct"
)
stopifnot(nrow(anti_join(cell_join$only_y, exempt_rewrite_cells,
                         by = c("column", "row_label", "statistic"))) == 0)

cell_rows <- cell_join$joined |>
  mutate(
    location = table,
    claim_type = "pipeline",
    claim = str_glue("Table 1, {column}, {row_label}, {recode(statistic, n = 'count', pct = 'percentage', n_column = 'column N')}"),
    digits = claim_digits(value_paper),
    needs_block = FALSE,
    holds = NA_real_,
    match_rewrite = as.numeric(render(value_rewrite, digits) == value_paper)
  ) |>
  select(claim_id, location, claim_type, claim, value_paper, digits, value_rewrite, match_rewrite, holds)

# Extraction rows: value_rewrite from the tallies, by this file's own path ----
# Each quantity is named here and read from text_counts.csv. in_text_claims.R reaches the same
# numbers from the study-level rows instead.
rewrite_values <- tribble(
  ~claim_id, ~value_rewrite,
  "abstract_n_errors_studies", counts[["n_with_errors"]],
  "abstract_n_sampled", counts[["n_deposit"]],
  "eval_list_n", counts[["n_study_list"]],
  "eval_sample_n", counts[["n_sampled"]],
  "eval_year_first", counts[["year_first"]],
  "eval_year_last", counts[["year_last"]],
  "eval_files_min", counts[["files_min"]],
  "eval_files_max", counts[["files_max"]],
  "eval_stata_n", counts[["n_uses_stata"]],
  "eval_r_n", counts[["n_uses_r"]],
  "eval_spss_n", counts[["n_uses_spss"]],
  "eval_reproduced_of_n", counts[["n_deposit"]],
  "eval_reproduced_n", counts[["n_no_errors"]],
  "eval_remaining_n", counts[["n_deposit"]] - counts[["n_no_errors"]],
  "eval_resolvable_n", counts[["n_user_resolvable"]],
  "eval_further_info_n", counts[["n_author_resolvable"]],
  "eval_private_data_n", counts[["n_private_data"]],
  "eval_private_data_of_n", counts[["n_deposit"]],
  "eval_archive_r_n", counts[["n_archive_r"]],
  "eval_archive_r_failed_n", counts[["n_archive_r_failed"]],
  "eval_package_changes_n", counts[["n_package_changes"]],
  "eval_package_design_named", as.numeric(counts[["n_package_design"]] > 0),
  "eval_package_zelig_named", as.numeric(counts[["n_package_zelig"]] > 0),
  "eval_decade_years", counts[["year_last"]] - counts[["year_first"]],
  "table_1_title_n", unique(table_1$n_column[table_1$column == "Author provided code"])
)

block_rows <- claims |> filter(needs_block)
extraction_join <- join_exact(select(block_rows, claim_id), rewrite_values, "claim_id")
stopifnot(nrow(extraction_join$only_x) == 0, nrow(extraction_join$only_y) == 0)

claim_rows <- claims |>
  left_join(rewrite_values, by = "claim_id") |>
  mutate(
    stated = !is.na(value_paper) & !is.na(value_rewrite),
    agrees = stated & render(value_rewrite, replace_na(digits, 0)) == value_paper,
    # A descriptive claim carries its verdict in holds and no match_rewrite. One with a
    # printed value is checked for agreement first. One with none prints a truth value.
    holds = case_when(
      claim_type == "descriptive" & stated ~ as.numeric(agrees),
      claim_type == "descriptive" ~ value_rewrite,
      .default = NA_real_
    ),
    match_rewrite = case_when(
      claim_type == "descriptive" | !needs_block ~ NA_real_,
      .default = as.numeric(agrees)
    )
  ) |>
  select(claim_id, location, claim_type, claim, value_paper, digits, value_rewrite, match_rewrite, holds,
         needs_block)

# The second instrument's coverage gate ----
gate <- new.env()
source(here::here("ground_truth", "claims_gate.R"), local = gate)
printed <- gate$printed

# A claim's printed value and the value read from the tallies here must agree at the
# claim's own precision, and a quantity erratum must be the only thing that lets the printed
# value differ from the article's.
compared <- claim_rows |>
  filter(needs_block) |>
  inner_join(printed, by = "claim_id") |>
  mutate(expected = render(value_rewrite, replace_na(digits, 0)))
stopifnot(nrow(compared) == nrow(printed), all(compared$expected == compared$printed))

# The same classification on both sides: a claim the second instrument scores [corrected]
# is exactly a claim this build finds disagreeing with the article.
adverse_pipeline <- claim_rows |>
  filter(needs_block, claim_type == "pipeline", match_rewrite == 0) |>
  pull(claim_id)
stopifnot(setequal(adverse_pipeline, printed$claim_id[printed$verdict == "corrected"]))

# Assembly ----
extra_rows <- tibble(
  claim_id = "sampling_script_reproduces_deposit",
  location = "Evaluation, p. 463",
  claim_type = "structural",
  claim = "The maintained sampling script, run with the authors' seed and the current default sampler on the study list, draws exactly the 20 ids the deposit carries",
  value_paper = NA_character_,
  digits = NA_integer_,
  value_rewrite = as.numeric(sampling_check$reproduces_deposit[sampling_check$sample_kind == "Rejection"]),
  match_rewrite = NA_real_,
  holds = as.numeric(sampling_check$reproduces_deposit[sampling_check$sample_kind == "Rejection"])
)

# The locus is named at each call site and never defaulted. Both adverse rows are the
# article disagreeing with its own materials.
loci <- tribble(
  ~claim_id, ~defect_locus,
  "eval_list_n", "paper_internal",
  "table_1_archive_resolvable_errors_pct", "paper_internal"
)

spine_ids <- spine$claim_ids |> na.omit() |> str_split(";") |> unlist() |> str_trim()

row_notes <- tribble(
  ~claim_id, ~note,
  "eval_list_n", "The study list the sampling script reads has 92 rows. The sentence implies 94 (97 less three books). Neither figure is reconciled by the deposited or archived materials. Errata entry 1.",
  "eval_books_excluded", "No field in the study list or the deposit marks a book, so the count has no counterpart.",
  "table_1_archive_resolvable_errors_pct", "8 of 11 is 72.7 per cent, which rounds to 73. The page prints 74. Errata entry 2.",
  "table_1_archive_data_preparation_scripts_not_archived_n", "The codebook defines scripts_for_private_data over the author-provided scripts only, so this printed 0 is a structural zero rather than a tally.",
  "sampling_script_reproduces_deposit", "Under the pre-3.6 sampler the same seed draws a different set of ids (sampling_check.csv).",
  "eval_review_window", "A date range for work the deposit does not record.",
  "motivating_emails", "A hedged personal estimate with no data behind it.",
  "motivating_hours", "A hedged personal estimate with no data behind it."
)

ground_truth <- bind_rows(cell_rows, claim_rows |> select(-needs_block), extra_rows) |>
  left_join(loci, by = "claim_id") |>
  left_join(row_notes, by = "claim_id") |>
  left_join(select(claims, claim_id, claims_note = notes), by = "claim_id") |>
  mutate(
    paper_id = "peer_orr_coppock_2021",
    value_script = NA_real_,
    match = NA_real_,
    disposition = case_when(
      is.na(defect_locus) ~ NA_character_,
      claim_id %in% spine_ids ~ "corrected_here",
      .default = NA_character_
    ),
    disposition_reason = NA_character_,
    notes = coalesce(note, if_else(!is.na(claims_note) & claims_note != "", claims_note, NA_character_)),
    notes = if_else(is.na(notes) & is.na(value_rewrite) & !is.na(value_paper),
                    "No counterpart in the pipeline: not recorded in the deposit.", notes)
  ) |>
  select(paper_id, claim_id, location, claim_type, claim, value_paper, digits, value_script, match,
         value_rewrite, match_rewrite, holds, defect_locus, disposition, disposition_reason, notes)

# Gates ----
adverse <- (!is.na(ground_truth$match_rewrite) & ground_truth$match_rewrite == 0) |
  (!is.na(ground_truth$holds) & ground_truth$holds == 0)
clean <- !is.na(ground_truth$match_rewrite) & ground_truth$match_rewrite == 1

stopifnot(
  !anyDuplicated(ground_truth$claim_id),
  setequal(ground_truth$claim_id[adverse], loci$claim_id),
  all(!is.na(ground_truth$defect_locus[adverse])),
  all(is.na(ground_truth$defect_locus[clean])),
  all(!is.na(ground_truth$disposition[!is.na(ground_truth$defect_locus)])),
  all(c(claims$claim_id, cells$claim_id) %in% ground_truth$claim_id),
  all(spine_ids %in% ground_truth$claim_id),
  all(is.na(ground_truth$disposition[ground_truth$defect_locus %in% "paper_internal" &
                                       !ground_truth$claim_id %in% spine_ids]))
)

# Every erratum names a claim that really disagrees with the article, and every disagreement
# with the article is named by an erratum.
stopifnot(setequal(spine_ids, ground_truth$claim_id[adverse]))

# The extraction and the ground truth carry one transcription of each prose value.
reconcile <- inner_join(select(claims, claim_id, value_paper),
                        select(ground_truth, claim_id, gt_value = value_paper), by = "claim_id")
stopifnot(all(replace_na(reconcile$value_paper, "") == replace_na(reconcile$gt_value, "")))

# The column of the table the figures sum to.
stopifnot(sum(table_1$n[table_1$column == "Author provided code"]) == 25)

# value_paper keeps the page's own string: normalize nothing but sign and write.
write_csv(ground_truth, here::here("ground_truth", "peer_orr_coppock_2021_ground_truth.csv"), na = "NA")

# Float coverage ----
table_cells <- ground_truth |> filter(claim_id %in% cells$claim_id)
float_coverage <- tibble(
  float = "Table 1",
  published_numbers = nrow(cells),
  covered = nrow(table_cells),
  reproduced_by_rewrite = sum(table_cells$match_rewrite == 1),
  reproduced_by_archive = NA_integer_,
  plotted = NA_integer_,
  plotted_reproduced = NA_integer_,
  note = str_glue(
    "Printed cells are the two column Ns and the counts and percentages of the rows. ",
    "The deposit holds no code, so no archive value exists to compare. ",
    "The one cell not reproduced prints 74 where the data give 73 (errata entry 2). ",
    "The article has no figure."
  )
)
stopifnot(float_coverage$covered == float_coverage$published_numbers)
write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"))

print(ground_truth |> count(claim_type))
print(ground_truth |> filter(!is.na(defect_locus)) |> select(claim_id, defect_locus, disposition))
