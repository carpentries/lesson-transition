#!/usr/bin/env Rscript
r'{Transform a lesson from styles template to sandpaper infrastructure

This script will download a lesson repository from GitHub, translate it to the
new lesson infrastructure, {sandpaper}, and apply any post-translation scripts
that need to be applied in order to fix any issues that occurred in the
process.

Usage: 
  transform-lesson.R -o <dir> <repo> [<script>]
  transform-lesson.R -h | --help
  transform-lesson.R -v | --version
  transform-lesson.R [-qnfb] [-s <dir>] -o <dir> <repo> [<script>]

-h, --help                Show this information and exit
-v, --version             Print the version information of this script
-q, --quiet               Do not print any progress messages
-n, --dry-run             Perform the translation, but do not create the output
                          directory.
-f, --fix-liquid          Fix liquid tags that may not be processed normally
-b, --build               Build the lesson after translation. This can be useful
                          when writing scripts to see what needs to be fixed.
-s <dir>, --save=<dir>    The directory to save the repository for later use,
                          defaults to a temporary directory
-o <dir>, --output=<dir>  The output directory for the new sandpaper repository
<repo>                    The GitHub repository that contains the lesson. E.g.
                          carpentries/lesson-example
<script>                  Additional script to run after the transformation.
                          Important variables to use will be `old` = path to the
                          lesson we just downloaded and `new` = path to the new
                          sandpaper lesson. `old_lesson` = the Lesson object
}' -> doc
library("fs")
library("docopt")

arguments <- docopt(doc, version = "Stunning Barnacle 2021-10", help = TRUE)

if (arguments$quiet) {
  sink()
}

this_repo <- if (length(arguments$save)) path_abs(arguments$save) else tempfile()
new  <- path_abs(arguments$out)
last <- if (length(arguments$script)) path_abs(arguments$script) else NULL

if (!dir_exists(this_repo)) {
  dir_create(this_repo, recurse = TRUE)
}
old <- path(this_repo, path_file(arguments$repo))
new <- path(new, path_file(arguments$repo))
# Record status of previous attempt
if (length(arguments$script)) {
  f <- gsub(".R$", ".txt", arguments$script)
  old_commits <- if (file_exists(f)) readLines(f) else character(0)
} else {
  old_commits <- character(0)
}
new_commits <- character(2)
# Download a carpentries lesson
#
library("usethis")
library("gert")
we_have_local_copy <- dir_exists(old)
if (we_have_local_copy) {
  cli::cli_alert("switching to local copy of {.file {arguments$repo}} and pulling changes")
  git_pull(repo = old)
} else {
  cli::cli_alert("Downloading {.file {arguments$repo}} with {.fn usethis::create_from_github}")
  create_from_github(arguments$repo, destdir = this_repo, fork = FALSE, open = FALSE)
}

new_commits[1] <- git_info(repo = old)$commit

if (dir_exists(new)) {
  new_commits[2] <- git_info(repo = new)$commit
}


# Transfom a carpentries lesson to a sandpaper lesson
#
# This script will start in a lesson repository and take the steps to convert
# lesson content from Jekyll markdown to pandoc markdown syntax and move these
# files to a brand new sandpaper lesson.
#
# This process will take the files most of the way there, but because there are
# unique idiosyncracies to the lessons, this script should be ammended with
# lesson-specific transformations
library("sandpaper")
library("pegboard")
library("purrr")
library("xml2")
library("here")

lsn  <- tempfile()
from <- function(...) path(old, ...)
to   <- function(...) path(lsn, ...)

cli::cli_h1("Reading in lesson with {.pkg pegboard}")
old_lesson <- pegboard::Lesson$new(old, fix_liquid = arguments$fix_liquid)
# Script to transform the episodes via pegboard with traces
transform <- function(e, out = lsn) {
  outdir <- fs::path(out, "episodes/")
  cli::cli_process_start("Converting {.file {e$path}} to {.emph sandpaper}")
  cli::cli_status_update("converting block quotes to pandoc fenced div")
  e$unblock()

  cli::cli_status_update("removing Jekyll syntax")
  e$use_sandpaper()

  cli::cli_status_update("moving yaml items to body")
  e$move_questions()
  e$move_objectives()
  e$move_keypoints()
  cli::cli_process_done()

  cli::cli_status_update("fixing math blocks")
  e$protect_math()

  cli::cli_process_start("Writing {.file {outdir}/{e$name}}")
  e$write(outdir, format = path_ext(e$name), edit = FALSE)
  cli::cli_process_done()
}

# Read and and transform additional files
rewrite <- function(x, out) {
  tryCatch({
  ref <- Episode$new(x, process_tags = TRUE, fix_links = TRUE, fix_liquid = TRUE)
  ref$unblock()$use_sandpaper()$write(out)
  }, error = function(e) {
    cli::cli_alert_warning("Error in transformation: {e$message}")
  })
}

set_config <- function(key, value, path = lsn) {
  cfg <- sandpaper:::path_config(path)
  l <- readLines(cfg)
  what <- grep(glue::glue("^{key}:"), l)
  l[what] <- glue::glue("{key}: {shQuote(value)}")
  writeLines(l, cfg)
}

new_established <- length(old_commits) && old_commits[2] == new_commits[2]

suppressWarnings(cfg <- yaml::read_yaml(from("_config.yml")))

if (new_established) {
  cli::cli_h1("using existing lesson in {.file {new}}")
  lsn <- new
} else {
  # Create lesson
  cli::cli_h1("creating a new sandpaper lesson")
  create_lesson(lsn, name = cfg$title, open = FALSE)
  file_delete(to("episodes", "01-introduction.Rmd"))
  file_delete(to("index.md"))
}

# appending our gitignore file
tgi <- readLines(to(".gitignore"))
fgi <- readLines(from(".gitignore"))
writeLines(unique(c(tgi, fgi)), to(".gitignore"))

# Modify config file to match as close as possible to the one we have
cli::cli_h2("setting the configuration parameters in config.yaml")
set_config("title", cfg$title)
set_config("life_cycle", if (length(cfg$life_cycle)) cfg$life_cycle else "stable") 
set_config("contact", cfg$email)

if (length(gert::git_remote_list(repo = old)) == 0) {
  message("Cannot automatically set the following configuration values:\n source: <GITHUB URL>\n carpentry: <CARPENTRY ABBREVIATION>\n\nPlease edit config.yaml to set these values")
} else {
  rmt <- gert::git_remote_list(repo = old)
  i <- if (any(i <- rmt$name == "upstream")) which(i) else 1L
  url <- rmt$url[[i]]
  rmt <- gh:::github_remote_parse(rmt$url[[i]])$username
  set_config("source", url)
  set_config("carpentry",
    switch(rmt,
      swcarpentry = "swc",
      datacarpentry = "dc",
      librarycarpentry = "lc",
      "carpentries-incubator" = "incubator",
      "cp" # default
  ))
}


# Transform and write to our episodes folder
cli::cli_h1("Transforming Episodes")
purrr::walk(old_lesson$episodes, ~try(transform(.x)))
set_episodes(lsn, order = names(old_lesson$episodes), write = TRUE)

# Modify the index to include our magic header
idx <- list.files(old, pattern = "^index.R?md")
if (length(idx)) {
  idx <- if (length(idx) == 2) "index.Rmd" else idx
  idx <- Episode$new(from(idx), fix_liquid = TRUE)
  idx$yaml[length(idx$yaml) + 0:1] <- c("site: sandpaper::sandpaper_site", "---")
  idx$unblock()$use_sandpaper()
}

# write index and readme
idx$write(path = path(lsn), format = "md")
file_copy(from("README.md"), to("README.md"), overwrite = TRUE)

# Transform non-episode MD files
cli::cli_h2("copying instructor and learner materials")
rewrite(from("_extras", "design.md"), to("instructors"))
rewrite(from("_extras", "guide.md"), to("instructors"))
rewrite(from("_extras", "discuss.md"), to("learners"))
rewrite(from("_extras", "exercises.md"), to("learners"))
rewrite(from("_extras", "figures.md"), to("learners"))
rewrite(from("reference.md"), to("learners"))
rewrite(from("setup.md"), to("learners"))

# Copy Figures (N.B. this was one of the pain points for the Jekyll lessons: figures lived above the RMarkdown documents)
cli::cli_h2("copying figures, files, and data")
fs::dir_copy(from("fig"), to("episodes/fig"), overwrite = TRUE)
fs::dir_copy(from("files"), to("episodes/files"), overwrite = TRUE)
fs::dir_copy(from("data"), to("episodes/data"), overwrite = TRUE)

if (!new_established) {
  if (dir_exists(new)) {
    dir_delete(new)
  }
  cli::cli_h1("Copying transformed lesson to {new}")
  dir_copy(lsn, new)
  cli::cli_alert_info("Committing...")
  git_add(".", repo = new)
  git_commit("Transfer lesson to sandpaper",
    committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
    repo = new
  )
}
cli::cli_alert_info("The lesson is ready in {.file {new}}")

if (length(last)) {
  cli::cli_alert_info("Running {last}")
  source(last)
}

if (arguments$build) {
  build_lesson(new, quiet = FALSE)
}

stat <- gert::git_status(repo = new)
if (length(last) && nrow(stat) > 0) {
  cli::cli_alert_info("Committing new changes...")
  git_add(".", repo = new)
  git_commit("[custom] fix lesson contents",
    committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
    repo = new
  )
}

cli::cli_alert_info("writing commit statuses")
new_commits[2] <- git_info(repo = new)$commit
writeLines(new_commits, sub("R$", "txt", arguments$script))
