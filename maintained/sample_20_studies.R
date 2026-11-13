# peer_orr_coppock_2021/maintained/sample_20_studies.R
# Output: output/sampled_studies.csv, output/sampling_check.csv
# Depends on: helpers.R, data/ISPSDataArchive_StudyList_20191108.csv, original/active_maintenance.csv
# Description: Draw the sample of 20 studies from the archive's study list with
#   the seed and the sampler the authors used, and assert that it is the set of
#   20 ids the deposit carries. The sampling script was not deposited.

source(here::here("maintained", "helpers.R"))

isps <- load_study_list()
deposit <- load_deposit()

# The draw ----
# The default sampler, which is the one this repository keeps. The 20 ids the
# deposit carries come out of it exactly.
set.seed(343)
sampled_studies <- isps |>
  mutate(sampled = complete_rs(N = nrow(isps), n = 20)) |>
  filter(sampled == 1) |>
  arrange(id)

stopifnot(setequal(sampled_studies$id, deposit$id))

# The pre-3.6 sampler ----
# R changed how sample() draws in version 3.6.0 (April 2019), and the study list is
# dated November 2019, so the authors drew under the new sampler. The old one is
# run here only to record that it does not reproduce the deposited ids.
draw_ids <- function(kind) {
  old_kind <- RNGkind()[3]
  suppressWarnings(RNGkind(sample.kind = kind))
  set.seed(343)
  ids <- isps |>
    mutate(sampled = complete_rs(N = nrow(isps), n = 20)) |>
    filter(sampled == 1) |>
    pull(id)
  suppressWarnings(RNGkind(sample.kind = old_kind))
  stopifnot(RNGkind()[3] == old_kind)
  ids
}

sampling_check <- tibble(sample_kind = c("Rejection", "Rounding")) |>
  mutate(
    ids = map(sample_kind, draw_ids),
    n_frame = nrow(isps),
    n_drawn = map_int(ids, length),
    n_in_deposit = map_int(ids, \(x) sum(x %in% deposit$id)),
    reproduces_deposit = map_lgl(ids, \(x) setequal(x, deposit$id))
  ) |>
  select(-ids)

stopifnot(sampling_check$reproduces_deposit[sampling_check$sample_kind == "Rejection"])

write_csv(select(sampled_studies, id, title, author, archive_date, Num_of_files),
          here::here("maintained", "output", "sampled_studies.csv"))
write_csv(sampling_check, here::here("maintained", "output", "sampling_check.csv"))

print(sampling_check)
