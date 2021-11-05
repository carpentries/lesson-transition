#!/usr/bin/env Rscript
r'{Transform a lesson from styles template to sandpaper infrastructure

This script will download a lesson repository from GitHub, translate it to the
new lesson infrastructure, {sandpaper}, and apply any post-translation scripts
that need to be applied in order to fix any issues that occurred in the
process.

Usage: 
  R-ecology-lesson.R -f <script> -t <dir> -o <dir> <repo>
  R-ecology-lesson.R -h | --help
  R-ecology-lesson.R -v | --version
  R-ecology-lesson.R [-qnlb] -f <script> -t <dir> -o <dir> <repo>

-h, --help                Show this information and exit
-v, --version             Print the version information of this script
-q, --quiet               Do not print any progress messages
-n, --dry-run             Perform the translation, but do not create the output
                          directory.
-l, --fix-liquid          Fix liquid tags that may not be processed normally
-b, --build               Build the lesson after translation. This can be useful
                          when writing scripts to see what needs to be fixed.
-f <script> --funs=<script>  The path to the script that contains the custom
                             functions for this script to work.
-t <dir>, --template=<dir>  The path to the template repo.
-o <dir>, --output=<dir>  The output directory for the new sandpaper repository
<repo>                    The GitHub repository that contains the lesson. E.g.
                          carpentries/lesson-example
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
library("sandpaper")
library("usethis")
# NOTE: this version of pegboard needs this PR from tinkr: 
#  https://github.com/ropensci/tinkr/pull/54 
library("pegboard")
library("jsonlite", warn.conflicts = FALSE)
library("purrr", warn.conflicts = FALSE)
library("dplyr", warn.conflicts = FALSE)
library("xml2")
library("gert")
library("fs")

if (arguments$quiet) {
  sink()
}

source(arguments$funs)

old  <- path_abs(arguments$repo)
new  <- path_abs(arguments$output)

from <- function(...) path(old, ...)
to   <- function(...) path(new, ...)
template <- function(...) path(path_abs(arguments$template), ...)

cli::cli_h1("Reading in lesson with {.pkg pegboard}")

eps <- dir_ls(new, regexp = "[/]0.+?Rmd$")
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

# copy new directories
copy_dir(template("episodes"), to("episodes"))
copy_dir(template("instructors"), to("instructors"))
copy_dir(template("learners"), to("learners"))
copy_dir(template("profiles"), to("profiles"))
copy_dir(template("episodes/data"), to("episodes/data"))
copy_dir(template("episodes/fig"), to("episodes/fig"))
copy_dir(template("episodes/files"), to("episodes/files"))
copy_dir(template("renv"), to("renv"))
copy_dir(template(".github"), to(".github"))
file_copy(template("config.yaml"), to("config.yaml"))
# appending our gitignore file
tgi <- readLines(template(".gitignore"))
fgi <- readLines(from(".gitignore"))
writeLines(unique(c(tgi, fgi)), to(".gitignore"))
# Convert information in Episodes
cli::cli_h2("Converting block quotes")
walk(eps, convert_blocks)
cli::cli_h2("Converting solutions")
walk(eps, wrap_solutions)
cli::cli_h2("fixing image paths")
walk(eps, fix_images)

cli::cli_h2("Fixing error in episode 5")
# Fix an error in episode 5 where there is a stray `>` at the end of the code
# block.
cb <- eps[[6]]$code
extra_alligator <- cb[xml_attr(cb, "name") == "left_join_answer"]
ea_txt <- xml_text(extra_alligator)
invisible(xml_set_text(extra_alligator, sub("\\n[>]\\n$", "\n", ea_txt)))

# Modify the index to include our magic header
idx <- Episode$new(from("index.Rmd"))
add_experiment_info(idx)
idx$yaml[length(idx$yaml) + 0:1] <- c("site: sandpaper::sandpaper_site", "---")
idx$label_divs() # fee our image from it's HTML prison
invisible(fix_images(idx))

# add notice in README
rdm <- Episode$new(from("README.md"))
add_experiment_info(rdm)

# hack: copy the included file in both places
file_copy(from("_page_built_on.Rmd"), to("episodes"), overwrite = TRUE)
file_copy(from("_page_built_on.Rmd"), new, overwrite = TRUE)

# write episodes, index, and readme
walk(eps, ~.x$write(path = to("episodes"), format = "Rmd"))
walk(eps, ~file_delete(.x$path))
set_episodes(new, order = path_file(names(eps)), write = TRUE)
idx$write(path = new, format = "Rmd")
rdm$write(path = new, format = "md")


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
set_learners(new, order = "reference.md", write = TRUE)
file_delete(to("reference.md"))

# copy instructor notes and modify links
ino <- Episode$new(from("instructor-notes.md"))
ino$confirm_sandpaper()
ilinks <- xml2::xml_attr(ino$links, "destination")
ilinks[grepl("code-handout.R", ilinks)] <- "files/code-handout.R"
ilinks <- sub("datacarpentry", "data-lessons", ilinks)
xml2::xml_set_attr(ino$links, "destination", ilinks)
ino$write(path = to("instructors"), format = "md")
set_instructors(new, order = "instructor-notes.md", write = TRUE)
file_delete(to("instructor-notes.md"))

# ignore the index.Rmd (which contains the sandpaper::sandpaper_site)
writeLines("index.Rmd", to(".renvignore"))

# copy over images
dir_delete(to("episodes", "fig"))
dir_copy(from("img"), to("episodes", "fig"))

# Fix config items
cli::cli_h1("Setting the configuration parameters in config.yaml")
params <- c(
  title      = "Data Analysis and Visualisation in R for Ecologists",
  source     = "https://github.com/data-lessons/new-R-ecology-lesson/",
  contact    = "zkamvar@carpentries.org",
  life_cycle = "stable",
  carpentry  = "dc"
)
set_config(params, path = new, write = TRUE)


# cli::cli_alert_info("Committing...")
# git_add(".", repo = new)
# git_commit("Transfer lesson to sandpaper",
#   committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
#   repo = new
# )

yaml <- readLines(to(".github/workflows/sandpaper-main.yaml"))
l <- grep("sandpaper:::ci_deploy", yaml, fixed = TRUE)
pad <- gsub("(^[[:space:]]+).+$", "\\1", yaml[l])
yaml <- c(yaml[1:(l - 1L)],
  paste0(pad, "options(sandpaper.handout = TRUE)"), 
  yaml[l:length(yaml)]
)

# Remembering to provision the site folder
if (!dir_exists(path(new, "site"))) {
  copy_dir(template("site"), to("site"))
}


cli::cli_alert_info("Committing...")
chchchchanges <- git_add(".", repo = new)
change_id <- git_commit("[automation] transform lesson to sandpaper",
  committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
  repo = new
)

json_out <- list(chchchchanges)
names(json_out) <- change_id

cli::cli_h2("managing R dependencies")
manage_deps(new)

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
  custom <- git_add(".", repo = new)
  custom_id <- git_commit(msg,
    committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
    repo = new
  )
  json_out <- c(json_out, custom)
  names(json_out)[2] <- custom_id
}

json <- path_ext_set(new, "json")
cli::cli_alert("Writing list of modified files to {.file {json}}")
json_out <- list(json_out)
names(json_out) <- arguments$repo
write_json(json_out, path = json)

cli::cli_rule("Conversion finished")
cli::cli_alert_info("Browse the old lesson in {.file {path_rel(old)}}")
cli::cli_alert_info("The converted lesson is ready in {.file {path_rel(new)}}")


