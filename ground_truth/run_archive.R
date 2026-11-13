# peer_orr_coppock_2021/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original_manifest.csv, original/
# Description: Record what running the deposited archive amounts to. The deposit is one
#   data file and one codebook, so it holds no script to run in either pass and nothing
#   to overwrite. The finding is asserted from the files rather than typed: every
#   deposited file is checked against the extensions that carry code, and the contents of
#   the codebook and the data file are checked for write calls. Nothing is run, and
#   nothing is run inside original/.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

code_extensions <- c("r", "rmd", "qmd", "do", "ado", "sps", "sas", "py", "ipynb", "m", "jl", "sh", "bat")
deposited <- list.files(here::here("original"), recursive = TRUE, all.files = TRUE, no.. = TRUE)

stopifnot(setequal(deposited, manifest$file))

code_files <- deposited[str_to_lower(tools::file_ext(deposited)) %in% code_extensions]
stopifnot(length(code_files) == 0)

# A script could hide inside a data file or a codebook, so the text of both is read for
# anything that looks like a statistical program.
program_pattern <- "library\\(|setwd\\(|read[._]csv\\(|<-|^\\s*(use|import delimited|insheet|get file)\\s"
looks_like_code <- map_lgl(deposited, \(f) {
  lines <- read_lines(here::here("original", f), progress = FALSE)
  any(str_detect(lines, program_pattern))
})
stopifnot(!any(looks_like_code))

stopped_at <- str_glue(
  "The deposit holds {length(deposited)} files ({str_c(deposited, collapse = ', ')}) and no script."
)

# Both passes are the same copy: with no script and no derived object there is nothing to
# strip, so the stripped pass is vacuous and is recorded as such rather than as a pass.
archive_run_status <- expand_grid(pass = c("as_shipped", "stripped")) |>
  mutate(
    script = "none deposited",
    role = "other",
    exit_status = NA_integer_,
    outcome = "not_run",
    stopped_at = as.character(stopped_at)
  )

archive_overwrites <- tibble(
  pass = character(), file = character(), effect = character(), matches_deposit = logical()
)

write_csv(archive_run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(archive_overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(archive_run_status)
