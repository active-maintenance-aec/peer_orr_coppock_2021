# peer_orr_coppock_2021/download_original.R
# Output: original/ (the deposited replication archive, not redistributed here)
# Depends on: original_manifest.csv
# Description: Fetch the deposited archive from Harvard Dataverse and verify every
#   file. Run this once before running anything in maintained/. Re-running is
#   free: files already present with the right checksum are not downloaded again.
#
#   The manifest carries two checksums per file. md5_served is the MD5 of the
#   bytes Dataverse returns for ?format=original, which is what this code was
#   written against. md5_published is the checksum Dataverse displays. Here both
#   agree for both files, but they do not always, so verification runs against
#   md5_served and any disagreement is reported rather than raised as a failure.
#
#   The data file was ingested as tabular data, so Dataverse serves it under a
#   .tab name unless ?format=original is requested. The manifest records the
#   deposited name (active_maintenance.csv) in file and the served name in
#   served_as.
#
#   The deposit is flat: one data file and one codebook, and no code. A
#   byte-identical copy of both files sits in the Yale Dataverse as
#   doi:10.60600/YU/STDUPI; this script fetches the Harvard deposit, which is the
#   one the article cites.

library(tidyverse)
library(here)

here::i_am("download_original.R")

dataset_doi <- "doi:10.7910/DVN/JLLFGK"
base_url <- "https://dataverse.harvard.edu/api/access/datafile"

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

dir.create(here::here("original"), showWarnings = FALSE, recursive = TRUE)

# Download what is missing or wrong ----
# format=original asks for the deposited bytes rather than the tabular
# representation Dataverse derives for ingested files.
planned <- manifest |>
  mutate(
    path = here::here("original", file),
    url = str_glue("{base_url}/{dataverse_file_id}?format=original"),
    md5_local = unname(tools::md5sum(path)),
    needs_download = is.na(md5_local) | md5_local != md5_served
  )

walk2(
  planned$url[planned$needs_download],
  planned$path[planned$needs_download],
  function(url, path) download.file(url, destfile = path, mode = "wb", quiet = TRUE)
)

print(str_glue("Downloaded {sum(planned$needs_download)} of {nrow(planned)} files; ",
               "{sum(!planned$needs_download)} already present and verified."))

# Verify ----
verified <- planned |>
  mutate(
    md5_downloaded = unname(tools::md5sum(path)),
    bytes_local = file.size(path),
    md5_ok = !is.na(md5_downloaded) & md5_downloaded == md5_served,
    bytes_ok = !is.na(bytes_local) & bytes_local == bytes,
    published_agrees = md5_served == md5_published
  ) |>
  select(file, bytes, bytes_local, bytes_ok, md5_served, md5_downloaded, md5_ok,
         published_agrees)

if (!all(verified$md5_ok & verified$bytes_ok)) {
  print(verified |> filter(!md5_ok | !bytes_ok), n = Inf)
  stop("Checksum or byte size mismatch: the archive in original/ does not match what Dataverse served when this code was written.")
}

# original/ must hold the deposit and nothing else. Anything extra found here
# means something was written into the directory, so this halts rather than
# warns. all.files = TRUE is not optional: without it a
# stray dotfile passes silently. The membership check runs after the checksum
# check so that a renamed deposited file is caught by the checksum first.
extra <- setdiff(list.files(here::here("original"), recursive = TRUE, all.files = TRUE,
                            no.. = TRUE),
                 manifest$file)

print(str_glue("All {nrow(verified)} files match md5_served and the deposited byte size. ",
               "{sum(!verified$published_agrees)} carry a published checksum that disagrees."))

if (length(extra) > 0) {
  print(extra)
  stop("original/ holds ", length(extra), " file(s) the manifest does not list. ",
       "Restore the deposit and run the archive in a copy, never in place.")
}

print(str_glue("Archive: {dataset_doi}"))
