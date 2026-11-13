# peer_orr_coppock_2021/maintained/text_claims.R
# Output: output/study_level.csv, output/text_counts.csv
# Depends on: helpers.R, original/active_maintenance.csv, output/sampled_studies.csv
# Description: The counts the article states in its running text: how many studies,
#   which years, how many files, which statistical software, how many studies had
#   which kind of error. study_level.csv is the deposit's study-level rows with the
#   archive year parsed; text_counts.csv is the tallies.

source(here::here("maintained", "helpers.R"))

deposit <- load_deposit()
isps <- load_study_list()
sampled <- read_csv(here::here("maintained", "output", "sampled_studies.csv"), show_col_types = FALSE)

study_level <- deposit |>
  select(id, archive_year, num_of_files, uses_r, uses_stata, uses_spss, issues_orig,
         user_resolvable_orig, author_resolvable_orig, scripts_for_private_data,
         issues_isps, isps_rpackage, isps_rpackage_name, user_resolvable_isps,
         author_resolvable_isps)

text_counts <- tribble(
  ~quantity, ~value,
  "n_study_list", nrow(isps),
  "n_sampled", nrow(sampled),
  "n_deposit", nrow(deposit),
  "year_first", min(deposit$archive_year),
  "year_last", max(deposit$archive_year),
  "files_min", min(deposit$num_of_files),
  "files_max", max(deposit$num_of_files),
  "n_uses_stata", sum(deposit$uses_stata == 1),
  "n_uses_r", sum(deposit$uses_r == 1),
  "n_uses_spss", sum(deposit$uses_spss == 1),
  "n_no_errors", sum(deposit$issues_orig == 0),
  "n_with_errors", sum(deposit$issues_orig == 1),
  "n_user_resolvable", sum(deposit$user_resolvable_orig == 1, na.rm = TRUE),
  "n_author_resolvable", sum(deposit$author_resolvable_orig == 1, na.rm = TRUE),
  "n_both_resolvable_kinds",
  sum(deposit$user_resolvable_orig == 1 & deposit$author_resolvable_orig == 1, na.rm = TRUE),
  "n_private_data", sum(deposit$scripts_for_private_data == 1),
  "n_archive_r", sum(!is.na(deposit$issues_isps)),
  "n_archive_r_failed", sum(deposit$issues_isps == 1, na.rm = TRUE),
  "n_package_changes", sum(deposit$isps_rpackage == 1, na.rm = TRUE),
  "n_package_design", sum(deposit$isps_rpackage_name == "Design", na.rm = TRUE),
  "n_package_zelig", sum(deposit$isps_rpackage_name == "Zelig", na.rm = TRUE)
)

write_csv(study_level, here::here("maintained", "output", "study_level.csv"))
write_csv(text_counts, here::here("maintained", "output", "text_counts.csv"))

print(text_counts, n = Inf)
