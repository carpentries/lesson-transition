#!/usr/bin/env Rscript
r'{Create a template sandpaper lesson

This will create a template sandpaper lesson _without_ the git repository so
components can be copied over without hassle.

Usage: 
  establish-template.R <dir>
  establish-template.R -h | --help
  establish-templte.R -v | --version

-h, --help     Show this information and exit
-v, --version  Print the version information of this script
<dir>          The directory to save the repository for later use,
               defaults to a temporary directory
}' -> doc
library("fs")
library("cli")
library("docopt")
library("sandpaper")
library("varnish")

arguments <- docopt(doc, version = "Stunning Barnacle 2022-09", help = TRUE)

lesson <- path_abs(arguments$dir)
to <- function(...) path(lesson, ...)

if (dir_exists(lesson)) {
  dir_delete(lesson)
}

cli::cli_alert_info("creating a new sandpaper lesson")
usethis::create_from_github("carpentries/workbench-template-rmd", tempdir())
fs::dir_copy(fs::path(tempdir(), "workbench-template-rmd"), lesson)
cli::cli_alert_info("Updating workflows")
sandpaper::update_github_workflows(lesson)
cli::cli_alert_info("Removing boilerplate")
file_delete(to("episodes", "introduction.Rmd"))
file_delete(to("index.md"))
file_delete(to("README.md"))
dir_delete(to(".git"))
dir_delete(to("renv/profiles/lesson-requirements/renv"))
