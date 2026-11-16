# Maintained reproduction of Peer, Orr, and Coppock (2021)

**Archived at Zenodo:** [doi:10.5281/zenodo.24289043](https://doi.org/10.5281/zenodo.24289043). This DOI always resolves to the latest release of the maintained version.

- [What this repository is](#what-this-repository-is)
  - [Folder layout](#folder-layout)
  - [How to reproduce](#how-to-reproduce)
- [The paper](#the-paper)
- [Does the deposited archive run?](#does-the-deposited-archive-run)
- [Errata](#errata)
  - [Findings that are not errata](#findings-that-are-not-errata)
- [The ground truth](#the-ground-truth)
  - [Coverage, float by float](#coverage-float-by-float)
- [The extraction and the two
  instruments](#the-extraction-and-the-two-instruments)
- [The maintained rewrite](#the-maintained-rewrite)
- [Table 1 verification](#table-1-verification)
- [Rewrite verification](#rewrite-verification)
- [R environment](#r-environment)

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

## What this repository is

A maintained reproduction of every number in Peer, Orr, and Coppock
(2021), which proposes “active maintenance” of replication archives and
documents the problem with a random sample of 20 studies from the ISPS
Data Archive. The repository fetches the authors’ deposited data,
redraws the sample from the archive’s study list, recomputes Table 1 and
every in-text count, and keeps a ground truth that records, claim by
claim, whether the published number reproduces.

All but 2 of the paper’s 38 compared numbers reproduce at the precision
the page prints. The two that do not are filed as errata in
`peer_orr_coppock_2021_errata.pdf`, built from `errata.qmd`: a sampling
frame described as 94 studies that is 92 in the archived materials, and
a percentage in Table 1 printed as 74 that is 73. Neither changes a
conclusion.

|  |  |
|----|----|
| Article | Peer L, Orr LV and Coppock A (2021). “Active Maintenance: A Proposal for the Long-Term Computational Reproducibility of Scientific Results.” *PS: Political Science & Politics* 54 (3), 462–466. <https://doi.org/10.1017/S1049096521000366> |
| Replication archive | <https://doi.org/10.7910/DVN/JLLFGK> (Harvard Dataverse, version 1.0, released 22 February 2021), the deposit the article cites |
| Second copy of the archive | <https://doi.org/10.60600/YU/STDUPI> (Yale Dataverse). Both files are byte-identical to the Harvard deposit, checked by MD5 and by byte comparison. This repository fetches the Harvard copy. |

### Folder layout

    download_original.R    fetches and verifies the deposited archive
    run_all.R              runs everything, in order
    original/              the deposited archive (not redistributed; fetched on demand)
    original_manifest.csv  every deposited file, its size and its published checksum
    maintained/            the rewrite; maintained/output/ holds every number it produces
    maintained/data/       the ISPS Data Archive's public study list the sample was drawn from
    ground_truth/          the extraction, the comparison and the gates
    errata.qmd             corrections to the published article

### How to reproduce

Download the repository, open `peer_orr_coppock_2021.Rproj`, and run:

``` r
source("run_all.R")
```

`run_all.R` fetches the deposited archive from Harvard Dataverse,
verifies every file against its published checksum and byte size,
redraws the sample, writes Table 1 and every in-text count, records what
the deposit contains, rebuilds the ground truth, and re-verifies the
archive. Nothing writes into `original/`. The archive is 7.2 kB, so the
first run downloads almost nothing.

## The paper

The article argues that code in replication archives becomes obsolete
within a few years and proposes that researchers, archives, and journals
plan for the “active maintenance” of analysis code. Its evidence is a
review of a random sample of 20 studies drawn from the ISPS Data Archive
at Yale, all of which were computationally reproducible when deposited.
Archive staff re-ran each study’s programs between December 2019 and
March 2020. 13 of the 20 studies still ran, 7 did not, and of the 11
studies for which the archive had added R programs, 8 of those programs
failed to run.

The paper has one table, Table 1, and no figure and no appendix. Every
number it reports is a tally over the indicator columns of the deposited
study-level file, with two exceptions: the size of the list the sample
was drawn from, and a handful of descriptions of the review itself (its
dates, its software versions, and a hedged estimate of the effort a
motivating example took) that no data in the deposit record.

## Does the deposited archive run?

The deposit is 2 files: one data file, `active_maintenance.csv`
(Dataverse serves it as a `.tab`), and its codebook. **The deposit
contains no code**, so there is no script to run and nothing to
overwrite. The two passes the procedure calls for are recorded as not
run, and the table of overwritten files is empty:

| pass | script | outcome | stopped_at |
|:---|:---|:---|:---|
| as_shipped | none deposited | not_run | The deposit holds 2 files (active_maintenance_codebook.txt, active_maintenance.csv) and no script. |
| stripped | none deposited | not_run | The deposit holds 2 files (active_maintenance_codebook.txt, active_maintenance.csv) and no script. |

`ground_truth/run_archive.R` asserts the finding from the files rather
than typing it: every deposited file is matched against the extensions
that carry code, and the text of each is searched for anything that
reads as a program. It finds 0 overwritten files and no code. As a
consequence the `value_script` and `match` columns of the ground truth
are empty on every row: the authors’ own analysis, which was done in
Stata, is not part of the archive, and a comparison against the
archive’s output is not possible.

The sampling script, the one piece of code behind the article’s numbers
that the authors still hold, was not deposited either. It is
reconstructed here and is described under the maintained rewrite.

## Errata

Two entries, listed in `peer_orr_coppock_2021_errata.pdf`. The first is
a sampling frame of 97 studies, less three books, that the archived
materials show to be 92. The second is a percentage in Table 1 printed
one point too high. Neither changes a conclusion.

| entry | class | form | title | location | claim_ids |
|:---|:---|:---|:---|:---|:---|
| 1 | quantity | full | The number of studies the sample was drawn from | p. 463, Evaluation | eval_list_n |
| 2 | float | brief | A percentage printed one point too high in Table 1 | p. 464, Table 1 | table_1_archive_resolvable_errors_pct |

### Findings that are not errata

- **The categories overlap, so Table 1’s first column does not sum to
  20.** It sums to 25. Of the 7 studies with errors, 2 carry both a
  resolvable error and an error needing further information, and a study
  with private-data scripts can also carry an error. The article’s
  counts are right as printed; its text says six and three of seven,
  which only reconciles with the overlap in view.
- **Descriptions of the review have no data behind them.** The review
  window, the Stata, R, and SPSS versions, the July 2017 date of the
  first review of the motivating example, and the estimate of “perhaps
  10 emails and an hour of debugging” are recorded in the extraction as
  definitional or transcribed claims. They are neither reproducible nor
  contradicted.
- **The printed 0 for private-data scripts in the archive-added column
  is a structural zero.** The codebook defines that indicator over the
  author-provided scripts only.

## The ground truth

| claim_type   | not compared | holds | does not reproduce | reproduces |
|:-------------|-------------:|------:|-------------------:|-----------:|
| definitional |            7 |     0 |                  0 |          0 |
| descriptive  |            0 |     3 |                  0 |          0 |
| pipeline     |            0 |     0 |                  2 |         36 |
| structural   |            3 |     1 |                  0 |          0 |
| transcribed  |            5 |     0 |                  0 |          0 |

The ground truth has 57 rows: the 16 printed cells of Table 1, the 40
claims of the extraction, and one row recording that the sampling script
reproduces the deposited ids. Of the 38 compared numbers, 36 reproduce
and 2 do not, and both of the latter are filed as errata with the locus
`paper_internal`: the article disagrees with the materials it cites.

| claim_id | value_paper | value_rewrite | defect_locus | disposition |
|:---|:---|---:|:---|:---|
| table_1_archive_resolvable_errors_pct | 74 | 72.72727 | paper_internal | corrected_here |
| eval_list_n | 97 | 92.00000 | paper_internal | corrected_here |

### Coverage, float by float

| float | published_numbers | covered | reproduced_by_rewrite | reproduced_by_archive |
|:---|---:|---:|---:|:---|
| Table 1 | 16 | 16 | 15 | NA |

Printed cells are the two column Ns and the counts and percentages of
the rows. The deposit holds no code, so no archive value exists to
compare. The one cell not reproduced prints 74 where the data give 73
(errata entry 2). The article has no figure.

## The extraction and the two instruments

`ground_truth/published_claims.csv` is the extraction: every number and
every spelled-out number in the article’s text, classified by hand as
`pipeline` (22), `descriptive` (3), `definitional` (7), `structural`
(3), or `transcribed` (5). The reference list and the in-text citations
were not audited. The 16 cells of Table 1 are transcribed separately in
`ground_truth/published_maintext_tables.csv` and compared cell by cell.

25 extraction rows require a block in `maintained/in_text_claims.R`, the
second instrument, and the coverage gate asserts that the claims it
prints are exactly those rows. The two instruments reach each number by
separate paths: `ground_truth/build_ground_truth.R` reads the tallies in
`text_counts.csv`, and `in_text_claims.R` recomputes them from the
study-level rows. Where they disagree one of them is wrong, and the
build stops. Each printed claim carries a verdict: a claim an erratum
corrects must differ from the article and equal the corrected value, and
any other claim must equal the article’s.

| claim_type   | needs_block |   n |
|:-------------|:------------|----:|
| definitional | FALSE       |   7 |
| descriptive  | TRUE        |   3 |
| pipeline     | TRUE        |  22 |
| structural   | FALSE       |   3 |
| transcribed  | FALSE       |   5 |

## The maintained rewrite

| Script | Output |
|----|----|
| `maintained/sample_20_studies.R` | `sampled_studies.csv`, `sampling_check.csv` |
| `maintained/table_1_computational_reproducibility.R` | `table_1_computational_reproducibility.csv` and `.tex` |
| `maintained/text_claims.R` | `study_level.csv`, `text_counts.csv` |
| `maintained/in_text_claims.R` | printed claims only |

**The sample.** The authors’ sampling script was not deposited. The
archive’s public study list, dated 8 November 2019, is committed under
`maintained/data/` and holds 92 studies. The script draws 20 from it
with `set.seed(343)` and `randomizr::complete_rs()`, and asserts that
the set of ids equals the deposit’s. It does, under the current default
sampler. Under the pre-3.6 sampler the same seed draws a different
sample, of which only 2 ids are in the deposit. The default sampler
reproduces the deposited ids and the old one does not, which fits a list
dated after R 3.6.0 appeared. The rewrite keeps the default sampler.

**Table 1.** Each count is a tally over the deposit’s indicator columns:
no errors is `issues_orig == 0`, resolvable is
`user_resolvable_orig == 1`, requiring further information is
`author_resolvable_orig == 1`, and data-preparation scripts not archived
is `scripts_for_private_data == 1`. The archive-added column is the 11
studies with a non-missing `issues_isps`, tallied the same way on the
`_isps` columns.

## Table 1 verification

| cell | printed | rewrite | reproduces |
|:---|:---|:---|:---|
| Author provided code, N, column N | 20 | 20 | yes |
| Archive added code, N, column N | 11 | 11 | yes |
| Author provided code, No errors, count | 13 | 13 | yes |
| Author provided code, No errors, percentage | 65 | 65 | yes |
| Author provided code, Resolvable errors, count | 6 | 6 | yes |
| Author provided code, Resolvable errors, percentage | 30 | 30 | yes |
| Author provided code, Errors requiring further information, count | 3 | 3 | yes |
| Author provided code, Errors requiring further information, percentage | 15 | 15 | yes |
| Author provided code, Data-preparation scripts not archived, count | 3 | 3 | yes |
| Author provided code, Data-preparation scripts not archived, percentage | 15 | 15 | yes |
| Archive added code, No errors, count | 3 | 3 | yes |
| Archive added code, No errors, percentage | 27 | 27 | yes |
| Archive added code, Resolvable errors, count | 8 | 8 | yes |
| Archive added code, Resolvable errors, percentage | 74 | 73 | no |
| Archive added code, Errors requiring further information, count | 0 | 0 | yes |
| Archive added code, Data-preparation scripts not archived, count | 0 | 0 | yes |

15 of the 16 printed cells reproduce. The one that does not is the
archive-added column’s percentage of resolvable errors, which prints 74
where 8 of 11 is 72.7, and rounds to 73 (errata entry 2).

## Rewrite verification

`run_all.R` runs end to end from a clean session, and a second run
leaves every committed file byte-identical. The only quantity that
depends on a random draw is the sample, which is seeded, and its result
is asserted against the deposit on every run. The repository writes no
figure.

## R environment

    R version 4.6.1 (2026-06-24)
    Platform: aarch64-apple-darwin23
    Running under: macOS Tahoe 26.6.2

    Matrix products: default
    BLAS:   /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRblas.0.dylib 
    LAPACK: /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1

    locale:
    [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

    time zone: America/Chicago
    tzcode source: internal

    attached base packages:
    [1] stats     graphics  grDevices utils     datasets  methods   base     

    other attached packages:
     [1] knitr_1.51      here_1.0.2      lubridate_1.9.5 forcats_1.0.1   stringr_1.6.0   dplyr_1.2.1     purrr_1.2.2     readr_2.2.0     tidyr_1.3.2     tibble_3.3.1    ggplot2_4.0.3   tidyverse_2.0.0

    loaded via a namespace (and not attached):
     [1] bit_4.6.0          gtable_0.3.6       jsonlite_2.0.0     crayon_1.5.3       compiler_4.6.1     tidyselect_1.2.1   parallel_4.6.1     scales_1.4.0       yaml_2.3.12        fastmap_1.2.0     
    [11] R6_2.6.1           generics_0.1.4     rprojroot_2.1.1    pillar_1.11.1      RColorBrewer_1.1-3 tzdb_0.5.0         rlang_1.3.0        stringi_1.8.9      xfun_0.60          S7_0.2.2          
    [21] bit64_4.8.2        otel_0.2.0         timechange_0.4.0   cli_3.6.6          withr_3.0.3        magrittr_2.0.5     digest_0.6.39      grid_4.6.1         vroom_1.7.1        hms_1.1.4         
    [31] lifecycle_1.0.5    vctrs_0.7.3        evaluate_1.0.5     glue_1.8.1         farver_2.1.2       rmarkdown_2.31     tools_4.6.1        pkgconfig_2.0.3    htmltools_0.5.9   
