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

arguments <- docopt(doc, version = "Stunning Barnacle 2021-10", help = TRUE)

lesson <- path_abs(arguments$dir)
to <- function(...) path(lesson, ...)

if (dir_exists(lesson)) {
  dir_delete(lesson)
}

cli::cli_alert_info("creating a new sandpaper lesson")
create_lesson(lesson, name = "FIXME", open = FALSE)
cli::cli_alert_info("Removing boilerplate")
file_delete(to("episodes", "01-introduction.Rmd"))
dir_delete(to("episodes", "data"))
dir_delete(to("episodes", "fig"))
dir_delete(to("episodes", "files"))
file_delete(to("index.md"))
file_delete(to("README.md"))
dir_delete(to(".git"))
dir_delete(to("renv/profiles/lesson-requirements/renv"))
