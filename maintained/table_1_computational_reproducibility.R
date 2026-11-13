# peer_orr_coppock_2021/maintained/table_1_computational_reproducibility.R
# Output: output/table_1_computational_reproducibility.csv, output/table_1_computational_reproducibility.tex
# Depends on: helpers.R, original/active_maintenance.csv
# Description: Table 1, the counts of studies by kind of error for the author-provided
#   scripts (all 20 studies) and for the scripts the archive added (the 11 studies for
#   which it wrote R files), with each count as a share of its column.

source(here::here("maintained", "helpers.R"))

deposit <- load_deposit()

# Counts ----
# The categories overlap: a study can have errors of both kinds, and a study with
# private-data scripts can also have errors, so a column's counts need not sum to its N.
author <- tibble(
  column = "Author provided code",
  n_column = nrow(deposit),
  row_label = c("No errors", "Resolvable errors", "Errors requiring further information",
                "Data-preparation scripts not archived"),
  n = c(sum(deposit$issues_orig == 0), sum(deposit$user_resolvable_orig == 1, na.rm = TRUE),
        sum(deposit$author_resolvable_orig == 1, na.rm = TRUE),
        sum(deposit$scripts_for_private_data == 1))
)

archive_rows <- deposit |> filter(!is.na(issues_isps))
archive <- tibble(
  column = "Archive added code",
  n_column = nrow(archive_rows),
  row_label = author$row_label,
  n = c(sum(archive_rows$issues_isps == 0), sum(archive_rows$user_resolvable_isps == 1, na.rm = TRUE),
        sum(archive_rows$author_resolvable_isps == 1, na.rm = TRUE), 0L)
)

# The codebook defines scripts_for_private_data over the author-provided scripts only, so
# the archive-added column's private-data cell is a structural zero rather than a count.
# The deposit holds no indicator that could be tallied for it, and structural_zero marks it.
table_1 <- bind_rows(author, archive) |>
  mutate(share = n / n_column,
         structural_zero = column == "Archive added code" &
           row_label == "Data-preparation scripts not archived")

write_csv(table_1, here::here("maintained", "output", "table_1_computational_reproducibility.csv"))

# Formatted table ----
table_1_formatted <- table_1 |>
  mutate(cell = if_else(n == 0, "0", str_glue("{n} ({sprintf('%.0f', 100 * share)}%)"))) |>
  select(row_label, column, cell) |>
  pivot_wider(names_from = column, values_from = cell)

table_1_formatted |>
  rename(` ` = row_label) |>
  kbl(format = "latex", booktabs = TRUE, linesep = "",
      caption = "Computational reproducibility in 20 studies") |>
  write_lines(here::here("maintained", "output", "table_1_computational_reproducibility.tex"))

print(table_1_formatted)
