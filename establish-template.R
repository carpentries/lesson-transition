#!/usr/bin/env Rscript
r'{Create a template sandpaper lesson

This will create a template sandpaper lesson _without_ the git repository so
components can be copied over without hassle.

Usage: 
  establish-template.R <dir>
  establish-template.R -w <workflow> <dir>
  establish-template.R -h | --help
  establish-templte.R -v | --version

-h, --help     Show this information and exit
-v, --version  Print the version information of this script
-w <workflow>  Extra workflow to insert into the lesson
<dir>          The directory to save the repository for later use,
               defaults to a temporary directory
}' -> doc
library("fs")
library("cli")
library("docopt")
library("sandpaper")
library("varnish")
library("pandoc")

arguments <- docopt(doc, version = "Stunning Barnacle 2022-09", help = TRUE)

lesson <- path_abs(arguments$dir)
wflow  <- path_abs(arguments$w)
to <- function(...) path(lesson, ...)

if (dir_exists(lesson)) {
  dir_delete(lesson)
}

cli::cli_alert_info("creating a new sandpaper lesson")
tmpout <- file.path(tempdir(), "workbench-template-rmd")
gert::git_clone("https://github.com/carpentries/workbench-template-rmd", tmpout)
fs::dir_copy(tmpout, lesson)
cli::cli_alert_info("Updating workflows")
sandpaper::update_github_workflows(lesson)
file_copy(wflow, to(".github/workflows/"))
cli::cli_alert_info("Removing boilerplate")
file_delete(to("episodes", "introduction.Rmd"))
file_delete(to("index.md"))
file_delete(to("README.md"))
dir_delete(to(".git"))
dir_delete(to("renv/profiles/lesson-requirements/renv"))
cli::cli_alert_info("Provisioning pandoc")
if (!pandoc_is_installed("3.1.2")) {
  pandoc_install("3.1.2")
}
pandoc_activate("3.1.2")
for (line in pandoc_run("--version")) {
  cli::cli_text(cli::col_cyan("\t{.emph {line}}"))
}
