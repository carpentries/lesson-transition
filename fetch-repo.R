#!/usr/bin/env Rscript
r'{Fetch a repository or pull commits if it already exists

This script will download a lesson repository from GitHub or pull changes from
upstream

Usage: 
  fetch-repo.R -s <dir> <repo>
  fetch-repo.R -h | --help
  fetch-repo.R -v | --version

-h, --help                Show this information and exit
-v, --version             Print the version information of this script
-s <dir>, --save=<dir>    The directory to save the repository for later use,
                          defaults to a temporary directory
<repo>                    The GitHub repository that contains the lesson. E.g.
                          carpentries/lesson-example
}' -> doc
library("fs")
library("here")
library("gert")
library("usethis")
library("cli")
library("docopt")

arguments <- docopt(doc, version = "Stunning Barnacle 2021-10", help = TRUE)
program_dir <- path_abs(arguments$save)

if (!dir_exists(program_dir)) {
  dir_create(program_dir, recurse = TRUE)
}

old <- path(program_dir, path_file(arguments$repo))
outfile <- path_ext_set(here(arguments$repo), "hash")
res <- ""

options(usethis.protocol = "https")
we_have_local_copy <- dir_exists(old)
if (we_have_local_copy) {
  cli::cli_alert("switching to local copy of {.file {arguments$repo}} and pulling changes")
  res <- capture.output(rpo <- git_pull(repo = old), type = "message")
} else {
  cli::cli_alert("Downloading {.file {arguments$repo}} with {.fn usethis::create_from_github}")
  create_from_github(arguments$repo, destdir = program_dir, fork = FALSE, open = FALSE)
}

if (!startsWith(res, "Already up to date") || !file_exists(outfile)) {
  cli::cli_alert("Writing hash to {.file {outfile}}")
  writeLines(git_info(repo = old)$commit, outfile)
}

