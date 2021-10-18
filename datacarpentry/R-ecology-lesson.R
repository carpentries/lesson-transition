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
library("docopt")

arguments <- docopt(doc, version = "R Ecology Converter 2021-10", help = TRUE)
# Convert DataCarpentry R-ecology lesson to use the {sandpaper} infrastructure
# ============================================================================
#
# author: Zhian N. Kamvar
# date: 2021-09-15 (updated 2021-10-18 to auto-download and update)
#
# This script will do _most_ of the work to convert this lesson into something
# that can be deployed immediately. There are a couple of quirks that need to
# be fixed to get things working smoothly that I don't know yet if I want to fix
# programmatically:
#  - The note on episode 2 will need the heading increased or the <aside> tags
#    will not work :(
#
# TODO: write code handout extractor
# see https://github.com/ropensci/tinkr/pull/52 for details on how to do this

library("sandpaper")
library("usethis")
# NOTE: this version of pegboard needs this PR from tinkr: 
#  https://github.com/ropensci/tinkr/pull/54 
library("pegboard")
library("purrr")
library("dplyr")
library("xml2")
library("gert")
library("fs")

this_repo <- if (length(arguments$save)) path_abs(arguments$save) else tempfile()
new  <- path_abs(arguments$out)

if (!dir_exists(this_repo)) {
  dir_create(this_repo, recurse = TRUE)
}
old <- path(this_repo, path_file(arguments$repo))
new <- path(new, path_file(arguments$repo))
# Record status of previous attempt
f <- "datacarpentry/R-ecology-lesson.txt"
old_commits <- if (file_exists(f)) readLines(f) else character(0)
new_commits <- character(2)
# Download a carpentries lesson
#
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

lsn  <- tempfile()
from <- function(...) path(old, ...)
to   <- function(...) path(lsn, ...)

cli::cli_h1("Reading in lesson with {.pkg pegboard}")

eps <- dir_ls(old, regexp = "[/]0.+?Rmd$")
names(eps) <- eps
eps <- map(eps, Episode$new)

# This lesson uses block quotes differently than other lessons... it does not 
# have specific labels, but instead labels the block quotes with headings and
# treats them all the same.
#
# Because our converter relied on the presence of a kramdown postfix tag, which
# we converted to an attribute, we can read the headings and convert them to
# xml attributes so we can use our converter (unblock) to convert them into 
# pandoc fenced divs.
convert_blocks <- function(episode) {
  blocks <- episode$get_blocks()
  block_types <- map_chr(blocks, 
    ~xml_text(xml_find_first(.x, ".//md:heading", episode$ns))
  )
  ktags <- case_when(
    grepl("^Challenge", block_types)           ~ "{: .challenge}",
    grepl("^Learning Objectives", block_types) ~ "{: .objectives}",
    is.na(block_types)                         ~ "{: .blockquote}",
    TRUE                                       ~ "{: .callout}"
  )
  xml_set_attr(blocks, attr = "ktag", ktags)
  episode$unblock()$use_sandpaper()
}


# Convert answer code chunks to solutions 
find_answers <- function(episode) {
  lines <- xml_attr(xml_children(episode$body), "sourcepos")
  ep <- episode$code
  answers <- keep(ep, ~!is.na(xml_attr(.x, "answer")))
  which(lines %in% xml_attr(answers, "sourcepos"))
}

# add pandoc fenced-div tags to surround our answers
wrap_solutions <- function(episode) {
  answers <- find_answers(episode)
  n <- 0L
  for (a in answers) {
    episode$add_md(":::::::::::::::::", where = a + n)
    episode$add_md(":::::::: solution", where = a + n - 1L)
    n <- n + 2L
  }
  episode$label_divs()
}

# fix knitr graphics that use img/ 
fix_images <- function(episode, from = "img/", to = "fig/") {
  blocks <- xml_find_all(episode$body, 
    ".//md:code_block[contains(text(), 'knitr::include_graphics')]",
    ns = episode$ns
  )
  if (length(blocks)) {
    txt <- xml_text(blocks)
    xml_set_text(blocks, sub(from, to, txt))
  }
  images <- episode$images
  if (length(images)) {
    dest <- xml_attr(images, "destination")
    xml_set_attr(images, "destination", sub("img/", "fig/", dest))
  }
  episode
}
experiment <- "> **ATTENTION** This is an experimental test of the [{sandpaper}](https://carpentries.github.io/sandpaper-docs) lesson infrastructure.
If anything seems off, please contact Zhian Kamvar <zkamvar@carpentries.org>
"
# Convert information in Episodes
walk(eps, convert_blocks)
walk(eps, wrap_solutions)
walk(eps, fix_images)

# Fix an error in episode 5 where there is a stray `>` at the end of the code
# block.
cb <- eps[[6]]$code
extra_alligator <- cb[xml_attr(cb, "name") == "left_join_answer"]
ea_txt <- xml_text(extra_alligator)
invisible(xml_set_text(extra_alligator, sub("\\n[>]\\n$", "\n", ea_txt)))

# Modify the index to include our magic header
idx <- Episode$new(from("index.Rmd"))
idx$add_md(experiment, 0L)
idx$yaml[length(idx$yaml) + 0:1] <- c("site: sandpaper::sandpaper_site", "---")
idx$label_divs() # fee our image from it's HTML prison
invisible(fix_images(idx))

# add notice in README
rdm <- Episode$new(from("README.md"))
rdm$add_md(experiment, 0L)

# Create lesson
new_established <- length(old_commits) && old_commits[2] == new_commits[2]

if (new_established) {
  exists_on_our_computer <- !is.na(new_commits[2]) && new_commits[2] != ""
  if (exists_on_our_computer) {
    cli::cli_h1("using existing lesson in {.file {new}}")
    lsn <- new
    tryCatch(git_pull(repo = new), error = function(e) {})
  } else {
    base <- path_file(path_ext_remove(new))
    new_dir  <- path_abs(arguments$out)
    if (!dir_exists(new_dir)) dir_create(new_dir)
    rmt <- paste0("data-lessons/", base)
    cli::cli_alert_info("local repo not found, attempting to use {.url https://github.com/{rmt}}")
    res <- tryCatch({
      create_from_github(rmt, destdir = new_dir, open = FALSE)
    },
      error = function(e) {
        cli::cli_alert_danger("{e$message}")
        cli::cli_alert_danger("Could not find {.url https://github.com/{rmt}}")
        cli::cli_alert_warning("Defaulting to temporary lesson")
        FALSE
    })
    lsn <- if (isFALSE(res)) lsn else new
  }
} else {
  # Create lesson
  cli::cli_h1("creating a new sandpaper lesson")
  create_lesson(lsn, name = 'Data Analysis and Visualisation in R for Ecologists', open = FALSE)
  file_delete(to("episodes", "01-introduction.Rmd"))
  file_delete(to("index.md"))
}

# write episodes, index, and readme
walk(eps, ~.x$write(path = to("episodes"), format = "Rmd"))
set_episodes(lsn, order = path_file(names(eps)), write = TRUE)
idx$write(path = lsn, format = "Rmd")
rdm$write(path = lsn, format = "md")

# hack: copy the included file in both places
file_copy(from("_page_built_on.Rmd"), to("episodes"), overwrite = TRUE)
file_copy(from("_page_built_on.Rmd"), lsn, overwrite = TRUE)

# copy setup.R script and make modifications to avoid our folder preferences
SEQ <- function(a) a[1]:a[2]
setup <- readLines(from("setup.R"))
answers <- grep("^(knitr::knit_hook|\\}\\))", setup)
setup[SEQ(answers)] <- paste("#", setup[SEQ(answers)])
setup <- sub("fig.path", "# fig.path", setup, fixed = TRUE)
writeLines(setup, to("episodes", "setup.R"))


# copy learner reference
ref <- Episode$new(from("reference.md"))
ref$yaml <- c("---", "title: Learners' Reference", "---")
ref$write(to("learners"), format = "md")
set_learners(lsn, order = "reference.md", write = TRUE)

# copy instructor notes and modify links
ino <- Episode$new(from("instructor-notes.md"))
ino$confirm_sandpaper()
ilinks <- xml2::xml_attr(ino$links, "destination")
ilinks[grepl("code-handout.R", ilinks)] <- "files/code-handout.R"
ilinks <- sub("datacarpentry", "data-lessons", ilinks)
xml2::xml_set_attr(ino$links, "destination", ilinks)
ino$write(path = to("instructors"), format = "md")
set_instructors(lsn, order = "instructor-notes.md", write = TRUE)

# copy AUTHORS file
file_copy(from("AUTHORS"), lsn, overwrite = TRUE)

# ignore the index.Rmd (which contains the sandpaper::sandpaper_site)
writeLines("index.Rmd", to(".renvignore"))

# copy over images
dir_delete(to("episodes", "fig"))
dir_copy(from("img"), to("episodes", "fig"))

# Fix config items
set_config <- function(key, value, path = lsn) {
  cfg <- sandpaper:::path_config(path)
  l <- readLines(cfg)
  what <- grep(glue::glue("^{key}:"), l)
  l[what] <- glue::glue("{key}: {shQuote(value)}")
  writeLines(l, cfg)
}
set_config("carpentry", "dc")
set_config("contact", "zkamvar@carpentries.org")
set_config("title", "Data Analysis and Visualisation in R for Ecologists")
set_config("life_cycle", "stable")
set_config("source", "https://github.com/data-lessons/R-ecology-lesson")

# delete detritus
detritus <- dir_ls(to("episodes", "fig"), regexp = "R-ecology-[^/]+$")
file_delete(detritus)

# move over temporary lesson
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

yaml <- readLines(to(".github/workflows/sandpaper-main.yaml"))
l <- grep("sandpaper:::ci_deploy", yaml, fixed = TRUE)
pad <- gsub("(^[[:space:]]+).+$", "\\1", yaml[l])
yaml <- c(yaml[1:(l - 1L)],
  paste0(pad, "options(sandpaper.handout = TRUE)"), 
  yaml[l:length(yaml)]
)

if (arguments$build) {
  build_lesson(new, quiet = FALSE)
}

stat <- gert::git_status(repo = new)
if (nrow(stat) > 0) {
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
writeLines(new_commits, "datacarpentry/R-ecology-lesson.txt")

cli::cli_alert_info("The lesson is ready in {.file {new}}")
