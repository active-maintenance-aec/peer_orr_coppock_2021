# peer_orr_coppock_2021/maintained/helpers.R
# Output: none
# Depends on: nothing
# Description: Packages and shared helpers sourced by every script in maintained/.

library(here)
library(tidyverse)
library(randomizr)
library(knitr)
library(kableExtra)

here::i_am("maintained/helpers.R")

# The deposited study-level file, one row per sampled study. Every count in the
# article is a tally over its indicator columns, so every script reads it here.
# The deposited name is active_maintenance.csv; Dataverse serves it as a .tab.
load_deposit <- function() {
  here::here("original", "active_maintenance.csv") |>
    read_csv(show_col_types = FALSE) |>
    mutate(archive_year = year(mdy_hm(archive_date)))
}

# The ISPS Data Archive's list of studies as of 2019-11-08, which the authors
# sampled from. Public catalog metadata only: id, title, author, archive date,
# and number of files.
load_study_list <- function() {
  here::here("maintained", "data", "ISPSDataArchive_StudyList_20191108.csv") |>
    read_csv(show_col_types = FALSE)
}

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone. This repository writes
# no figure, so the sweep in run_all.R finds nothing to blank.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
