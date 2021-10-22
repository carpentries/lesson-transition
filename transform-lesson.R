#!/usr/bin/env Rscript
r'{Transform a lesson from styles template to sandpaper infrastructure

This script will download a lesson repository from GitHub, translate it to the
new lesson infrastructure, {sandpaper}, and apply any post-translation scripts
that need to be applied in order to fix any issues that occurred in the
process.

If a lesson has been previously archived on the `data-lessons` repo, then the
new lesson will gain a `new-` prefix 

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
if (endsWith(new, "-")) {
  new <- paste0(new, path_file(arguments$repo))
} else {
  new <- path(new, path_file(arguments$repo))
}
# Record status of previous attempt
if (length(arguments$script)) {
  f <- gsub(".R$", ".txt", arguments$script)
  old_commits <- if (file_exists(f)) readLines(f) else character(0)
} else {
  old_commits <- character(0)
}
# determin if the new repository has previously been established
new_established <- length(old_commits) && !is.na(old_commits[2]) && old_commits[2] != ""
new_commits <- character(2)
# Download a carpentries lesson
#
library("usethis")
library("gert")
options(usethis.protocol = "https")
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
cli::cli_h2("Reading configuration file")
suppressWarnings(cfg <- yaml::read_yaml(from("_config.yml")))

# Functions --------------------------------------------------------------------
#
# The following lines are functions that I need to transform the lessons
#
# transform the image links to be local
fix_images <- function(episode, from = "([.][.][/])?(img|fig)/", to = "fig/") {
  blocks <- xml_find_all(episode$body, 
    ".//md:code_block[contains(text(), 'knitr::include_graphics')]",
    ns = episode$ns
  )
  if (length(blocks)) {
    txt <- xml_text(blocks)
    xml_set_text(blocks, sub(from, to, txt))
  }
  images <- episode$get_images(process = TRUE)
  images <- episode$images
  if (length(images)) {
    dest <- xml_attr(images, "destination")
    xml_set_attr(images, "destination", sub(from, to, dest))
  }
  episode
}

# transform the episodes via pegboard with reporters
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
  tryCatch(e$protect_math(),
    error = function(e) {
      cli::cli_alert_warning("Some math could not be parsed... likely because of shell variable examples")
      cli::cli_alert_info("Below is the error")
      cli::cli_alert_warning(e$message)
    })
  
  cli::cli_status_update("fixing image links") 
  fix_images(e)

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
    cli::cli_alert_warning("Could not process {.file {x}}: {e$message}")
  })
}

# Copy a directory if it exists
copy_dir <- function(x, out) {
  root <- fs::path_common(c(x, out))
  tryCatch(fs::dir_copy(x, out, overwrite = TRUE),
    error = function(e) {
      cli::cli_alert_warning("Could not copy {.file {fs::path_rel(x, root)}}")
      cli::cli_alert_warning(e$message)
    })
}

# Bootstrap a lesson and remove components we will not need/overwrite
make_lesson <- function(lesson = lsn, title = cfg$title) {
  cli::cli_h1("creating a new sandpaper lesson")
  create_lesson(lesson, name = title, open = FALSE)
  file_delete(to("episodes", "01-introduction.Rmd"))
  file_delete(to("index.md"))
}

fetch_new_lesson <- function(new, new_dir, exists = TRUE) {
  if (exists) {
    cli::cli_h1("using existing lesson in {.file {new}}")
    lsn <- new
    tryCatch(git_pull(repo = new), error = function(e) {})
    return(TRUE)
  } else {
    base <- path_file(path_ext_remove(new))
    if (!dir_exists(new_dir)) dir_create(new_dir)
    rmt <- paste0("data-lessons/", base)
    cli::cli_alert_info("local repo not found, attempting to use {.url https://github.com/{rmt}}")
    tryCatch({
      create_from_github(rmt, destdir = new_dir, open = FALSE)
      TRUE
    },
      error = function(e) {
        cli::cli_alert_danger("{e$message}")
        cli::cli_alert_danger("Could not find {.url https://github.com/{rmt}}")
        cli::cli_alert_warning("Defaulting to temporary lesson")
        FALSE
    })
  }
}
# END Functions ----------------------------------------------------------------

if (new_established) {
  exists_on_our_computer <- !is.na(new_commits[2]) && new_commits[2] != ""
  new_dir <- path_abs(arguments$out)
  res <- fetch_new_lesson(new, new_dir = new_dir, exists_on_our_computer)
  if (isFALSE(res)) {
    make_lesson(lsn, cfg$title)
    new_established <- FALSE
  } else {
    lsn <- new
  }
} else {
  make_lesson(lsn, cfg$title)
}


# appending our gitignore file
tgi <- readLines(to(".gitignore"))
fgi <- readLines(from(".gitignore"))
writeLines(unique(c(tgi, fgi)), to(".gitignore"))

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
copy_dir(from("fig"), to("episodes/fig"))
copy_dir(from("img"), to("episodes/fig"))
copy_dir(from("files"), to("episodes/files"))
copy_dir(from("data"), to("episodes/data"))
# Modify config file to match as close as possible to the one we have
set_config <- function(key, value, path = lsn) {
  cfg <- sandpaper:::path_config(path)
  l <- readLines(cfg)
  what <- grep(glue::glue("^{key}:"), l)
  line <- glue::glue("{key}: {shQuote(value)}")
  cli::cli_alert("Writing {.code {line}}")
  l[what] <- line
  writeLines(l, cfg)
}

cli::cli_h1("Setting the configuration parameters in config.yaml")
set_config("source", paste0("https://github.com/data-lessons/", path_file(new), "/"))
set_config("contact", cfg$email)
set_config("life_cycle", if (length(cfg$life_cycle)) cfg$life_cycle else "stable") 
set_config("carpentry",
  switch(strsplit(arguments$repo, "/")[[1]][1],
    swcarpentry = "swc",
    datacarpentry = "dc",
    librarycarpentry = "lc",
    "carpentries-incubator" = "incubator",
    "cp" # default
  )
)

# Transform and write to our episodes folder
cli::cli_h1("Transforming Episodes")
purrr::walk(old_lesson$episodes, ~try(transform(.x)))
if (length(cfg$episode_order)) {
  eps <- names(old_lesson$episodes)
  ord <- map_chr(paste0("^", cfg$episode_order, "\\.R?md$"), ~grep(.x, eps, value = TRUE))
  set_episodes(lsn, order = ord, write = TRUE)
} else {
  set_episodes(lsn, order = names(old_lesson$episodes), write = TRUE)
}


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

if (length(last)) {
  cli::cli_alert_info("Running {last}")
  source(last)
}

if (old_lesson$rmd) {
  cli::cli_h2("managing R dependencies")
  manage_deps(new)
} else {
  no_package_cache()
}

stat <- gert::git_status(repo = new)

if (arguments$build) {
  tryCatch(build_lesson(new, quiet = FALSE, preview = FALSE),
    error = function(e) {
      f <- sub("R$", "err", arguments$script)
      writeLines(e$message, f)
      cli::cli_alert_danger("There were issues with the lesson build process, see {.file {f} for details}")
    }
  )
} else {
  cli::cli_h2("no changes to lesson, no preview to be generated")
}

if (length(last) && nrow(stat) > 0) {
  msg <- getOption("custom.transformation.message", default = "[custom] fix lesson contents")
  cli::cli_alert_info("Committing new changes...")
  git_add(".", repo = new)
  git_commit(msg,
    committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
    repo = new
  )
}

cli::cli_alert_info("writing commit statuses")
new_commits[2] <- git_info(repo = new)$commit
writeLines(new_commits, sub("R$", "txt", arguments$script))

cli::cli_rule("Conversion finished")
cli::cli_alert_info("Browse the old lesson in {.file {old}}")
cli::cli_alert_info("The converted lesson is ready in {.file {new}}")
