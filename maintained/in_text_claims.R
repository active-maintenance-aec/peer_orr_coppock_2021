# peer_orr_coppock_2021/maintained/in_text_claims.R
# Output: printed CLAIM lines and a CLAIM SUMMARY line; no files
# Depends on: maintained/output/, ground_truth/published_claims.csv, errata_entries.csv, excheckr
# Description: One block per claim the published article makes that the pipeline can reach,
#   each carrying the article's own sentence verbatim and then recomputing the number from
#   the pipeline's committed output. This is the second instrument. It never reads
#   ground_truth/peer_orr_coppock_2021_ground_truth.csv, it fits nothing, and it reaches
#   every quantity by its own path (the study-level rows and the sampling check, where
#   build_ground_truth.R reads the tallies in text_counts.csv), so where the two disagree
#   one of them is wrong.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || [verdict] <label>
#
#   which build_ground_truth.R parses to check coverage against
#   ground_truth/published_claims.csv. The expectation is derived, never typed here:
#   published_claims.csv says what the article prints, and errata_entries.csv says which of
#   those a published note corrects and to what. A claim an erratum of class quantity names
#   is REQUIRED to differ from the article and to equal the corrected value.
#
#   Transcription note: every quote was checked against the rendered page, and the quotes
#   are what the article prints today, however wrong. Where a sentence is wrong that is
#   recorded in the ground truth and in peer_orr_coppock_2021_errata.pdf, never by editing
#   the quote. The article's spelled-out numbers are printed as numerals.

library(here)
library(tidyverse)
library(excheckr)

here::i_am("maintained/in_text_claims.R")

options(width = 200)

out <- function(file) read_csv(here::here("maintained", "output", file), show_col_types = FALSE)

study <- out("study_level.csv")
sampled <- out("sampled_studies.csv")
sampling <- out("sampling_check.csv")
table_1 <- out("table_1_computational_reproducibility.csv")

published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))
errata <- read_csv(here::here("errata_entries.csv"),
                   col_types = cols(.default = col_character()))

claim_start(published = published, errata = errata, format = "id", label_column = "claim")

# one: a single value out of a filtered frame, asserted to be a scalar, so a widened output
# file cannot turn a claim into a silently empty line.
one <- function(x) {
  stopifnot(length(x) == 1, !is.na(x))
  x
}

n_where <- function(condition) sum(condition, na.rm = TRUE)
rejection <- sampling |> filter(sample_kind == "Rejection")

# Abstract ----

# "We document this problem with a random sample of studies posted to the Institution for
#  Social and Policy Studies (ISPS) Data Archive; we encountered nontrivial errors in seven
#  of 20 studies."
claim("abstract_n_errors_studies", n_where(study$issues_orig == 1))
claim("abstract_n_sampled", nrow(study))

# Evaluation of the long-term computational reproducibility of 20 studies ----

# "We compiled a list of all 97 archived studies, excluded three books, and then randomly
#  selected 20 studies (Peer, Orr, and Coppock 2021)."
# The study list the sampling script draws from has the rows counted here. Nothing in the
# deposit or the archived materials marks a book, so the three has no counterpart.
claim("eval_list_n", one(rejection$n_frame))
claim("eval_sample_n", nrow(sampled))

# "The sample included studies archived between 2009 and 2019, with from four to 88 files
#  associated with each study."
claim("eval_year_first", min(study$archive_year))
claim("eval_year_last", max(study$archive_year))
claim("eval_files_min", min(study$num_of_files))
claim("eval_files_max", max(study$num_of_files))

# "These studies were archived using versions of Stata (18), R (one), and SPSS (one) that
#  were available at the time of deposit."
claim("eval_stata_n", sum(study$uses_stata))
claim("eval_r_n", sum(study$uses_r))
claim("eval_spss_n", sum(study$uses_spss))

# "Of these 20 studies, 13 could be reproduced with present-day hardware and software.
#  Various challenges to computational reproducibility emerged in the remaining seven
#  studies. In six studies, program files produced errors that could be resolved by
#  seasoned analysts."
claim("eval_reproduced_of_n", nrow(study))
claim("eval_reproduced_n", n_where(study$issues_orig == 0))
claim("eval_remaining_n", nrow(study) - n_where(study$issues_orig == 0))
claim("eval_resolvable_n", n_where(study$user_resolvable_orig == 1))

# "In three of the studies, program files produced errors that could not be resolved by
#  present-day users without further information or documentation."
claim("eval_further_info_n", n_where(study$author_resolvable_orig == 1))

# "In three of the 20 studies, raw data and associated cleaning files were not deposited."
claim("eval_private_data_n", n_where(study$scripts_for_private_data == 1))
claim("eval_private_data_of_n", nrow(study))

# "For 11 of the studies, archive staff added R files at the time of deposit as part of an
#  effort to convert statistical code to open-source formats. Of the eight instances in
#  which the R programs did not run, several included simple typos."
claim("eval_archive_r_n", n_where(!is.na(study$issues_isps)))
claim("eval_archive_r_failed_n", n_where(study$issues_isps == 1))

# "For example, three studies relied on packages that had been removed from CRAN (e.g.,
#  Design) or updated in ways that made it impossible to run the original syntax (e.g.,
#  Zelig)."
claim("eval_package_changes_n", n_where(study$isps_rpackage == 1))
claim("eval_package_design_named", as.numeric("Design" %in% study$isps_rpackage_name), digits = 0)
claim("eval_package_zelig_named", as.numeric("Zelig" %in% study$isps_rpackage_name), digits = 0)

# "In summary, we found that even in the relatively short 10-year period, replication
#  materials that originally allowed for computational reproducibility broke down."
claim("eval_decade_years", max(study$archive_year) - min(study$archive_year))

# Table 1, title ----

# "Table 1 Computational Reproducibility in 20 Studies"
# The table's cells are compared one by one in the ground truth, against the transcription
# in ground_truth/published_maintext_tables.csv.
claim("table_1_title_n", one(unique(table_1$n_column[table_1$column == "Author provided code"])))

# Claims the pipeline cannot reach ----
# The review window, the software versions, the motivating example's dates and its estimate of
# the work it took, the hypothetical horizon, the year of R's change, the counts of fields and
# questions, and the deposit DOI are verified at the point of use or are not recorded in the
# deposit. The books excluded have no counterpart because no list field marks a book.

claim_summary()
assert_claims()
