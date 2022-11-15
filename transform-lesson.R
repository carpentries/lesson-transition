#!/usr/bin/env Rscript
r'{Transform a lesson from styles template to sandpaper infrastructure

This script will transform a lesson from the former Jekyll infrastructure to the
new sandpaper infrastructure after it has been filtered with git-filter-repo.

ASSUMPTIONS

This script assumes that the repo you are transforming exists in the current
working directory as <organisation>/<lesson-name>. It also assumes that a 
template sandpaper lesson has been created with `establish-template.R`.

Usage: 
  transform-lesson.R -f <script> -t <dir> -o <dir> <repo> [<script>]
  transform-lesson.R -h | --help
  transform-lesson.R -v | --version
  transform-lesson.R [-qnlb] -f <script> -t <dir> -o <dir> <repo> [<script>]

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
                          carpentries/lesson-example. This doubles as the
                          relative path to the existing lesson previously cloned
                          from github.
<script>                  Additional script to run after the transformation.
                          Important variables to use will be `old` = path to the
                          lesson we just downloaded and `new` = path to the new
                          sandpaper lesson. `old_lesson` = the Lesson object
}' -> doc
library("fs")
library("docopt")
options(cli.width = 160)

arguments <- docopt(doc, version = "Stunning Barnacle 2021-11", help = TRUE)
if (arguments$quiet) {
  sink()
}

sandpaper:::check_git_user(".", 
  name = Sys.getenv("GITHUB_ACTOR"),
  email = paste0(Sys.getenv("GITHUB_ACTOR"), "@users.noreply.github.com")
)
# Load the functions needed to transform the repository

source(arguments$funs)

old  <- path_abs(arguments$repo)
new  <- path_abs(arguments$output)
last <- if (length(arguments$script)) path_abs(arguments$script) else NULL

cli::cli_rule("OLD: {.file {path_rel(old)}}")
cli::cli_rule("NEW: {.file {path_rel(new)}}")

if (!dir_exists(old)) {
  cli::cli_h1("Submodule not yet added... adding...")
  system(glue::glue("git submodule add https://github.com/{arguments$repo}"))
}

library("usethis")
library("gert")

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
library("jsonlite")
library("purrr")
library("xml2")
library("here")

from <- function(...) path(old, ...)
to   <- function(...) path(new, ...)
template <- function(...) path(path_abs(arguments$template), ...)

cli::cli_h1("Reading in lesson with {.pkg pegboard}")
old_lesson <- pegboard::Lesson$new(old, fix_liquid = arguments$fix_liquid)
cli::cli_h2("Reading configuration file")
suppressWarnings(cfg <- yaml::read_yaml(from("_config.yml")))
# copy new directories
copy_dir(template("instructors"), to("instructors"))
copy_dir(template("learners"), to("learners"))
copy_dir(template("profiles"), to("profiles"))
copy_dir(template("episodes/data"), to("episodes/data"))
copy_dir(template("episodes/fig"), to("episodes/fig"))
copy_dir(template("episodes/files"), to("episodes/files"))
copy_dir(template(".github"), to(".github"))
if (old_lesson$rmd) {
  copy_dir(template("renv"), to("renv"))
}
file_copy(template("config.yaml"), to("config.yaml"))
file_copy(template("LICENSE.md"), to("LICENSE.md"))
file_copy(template("CONTRIBUTING.md"), to("CONTRIBUTING.md"))
file_copy(template("CODE_OF_CONDUCT.md"), to("CODE_OF_CONDUCT.md"))

# appending our gitignore file
tgi <- readLines(template(".gitignore"))
fgi <- readLines(from(".gitignore"))
writeLines(unique(c(tgi, fgi)), to(".gitignore"))


cli::cli_h2("Processing index")
# Modify the index to include our magic header
idx <- list.files(old, pattern = "^index.R?md")
if (length(idx)) {
  idx <- if (length(idx) == 2) "index.Rmd" else idx
  idx <- Episode$new(from(idx), fix_liquid = TRUE)
  add_experiment_info(idx)
  idx$yaml[length(idx$yaml) + 0:1] <- c("site: sandpaper::sandpaper_site", "---")
  idx$unblock()$use_sandpaper()
}
idx$write(path = new, format = "md")

cli::cli_h2("Processing README")
# modify readme to include experiment info
rdm <- Episode$new(to("README.md"))
rdm$confirm_sandpaper()
add_experiment_info(rdm)

# write index and readme
rdm$write(path = new, format = "md")

# Transform non-episode MD files
cli::cli_h2("copying instructor and learner materials")
rewrite(from("_extras", "design.md"), to("instructors"))
rewrite(from("_extras", "guide.md"), to("instructors"))
if (fs::file_exists(to("instructors", "guide.md"))) {
  fs::file_move(to("instructors", "guide.md"), to("instructors", "instructor-notes.md"))
}

rewrite(from("_extras", "discuss.md"), to("learners"))
rewrite(from("_extras", "exercises.md"), to("learners"))
rewrite(from("_extras", "figures.md"), to("learners"))
rewrite(from("reference.md"), to("learners"))
rewrite(from("setup.md"), to("learners"))
del_dir("_extras")


# Copy Figures (N.B. this was one of the pain points for the Jekyll lessons: figures lived above the RMarkdown documents)
cli::cli_h2("copying figures, files, and data")
copy_dir(to("fig"), to("episodes/fig"))
del_dir(to("fig"))
copy_dir(to("img"), to("episodes/fig"))
del_dir(to("img"))
copy_dir(to("images"), to("episodes/fig"))
del_dir(to("images"))
copy_dir(to("files"), to("episodes/files"))
del_dir(to("files"))
copy_dir(to("data"), to("episodes/data"))
del_dir(to("data"))

cli::cli_h1("Setting the configuration parameters in config.yaml")
this_carp <- strsplit(arguments$script, "/")[[1]][1]
# DEPRECATED
this_carp_domain <- switch(this_carp,
  # swcarpentry             = "https://lessons.software-carpentry.org",
  datacarpentry           = "https://lessons.datacarpentry.org",
  # librarycarpentry        = "https://lessons.librarycarpentry.org",
  "https://fishtree-attempt.github.io" # default
)

params <- c(
  title      = cfg$title,
  source     = glue::glue("https://github.com/fishtree-attempt/{path_file(new)}/"),
  contact    = cfg$email,
  life_cycle = if (length(cfg$life_cycle)) cfg$life_cycle else "stable",
  carpentry  = switch(this_carp,
    swcarpentry             = "swc",
    datacarpentry           = "dc",
    librarycarpentry        = "lc",
    "carpentries-incubator" = "incubator",
    "cp" # default
  ),
  url = glue::glue("https://preview.carpentries.org/{path_file(new)}"),
  "workbench-beta" = "true"
)
set_config(params, path = new, write = TRUE, create = TRUE)
file_copy(from("_config.yml"), to("gifnoc_.yml"))

# copy over the editor config if it exists
if (file_exists(from(".editorconfig"))) {
  file_copy(from(".editorconfig"), to(".editorconfig"))
}


# Transform and write to our episodes folder
cli::cli_h1("Transforming Episodes")
purrr::walk(old_lesson$episodes, ~try(transform(.x)))
if (length(cfg$episode_order)) {
  eps <- names(old_lesson$episodes)
  ord <- map_chr(paste0("^", cfg$episode_order, "\\.R?md$"), ~grep(.x, eps, value = TRUE))
  set_episodes(new, order = ord, write = TRUE)
} else {
  set_episodes(new, order = names(old_lesson$episodes), write = TRUE)
}

# Remembering to provision the site folder
if (!dir_exists(path(new, "site"))) {
  copy_dir(template("site"), to("site"))
}


cli::cli_alert_info("Committing...")
sandpaper:::check_git_user(new, 
  name = Sys.getenv("GITHUB_ACTOR"),
  email = paste0(Sys.getenv("GITHUB_ACTOR"), "@users.noreply.github.com")
)
chchchchanges <- git_add(".", repo = new)
change_id <- git_commit("[automation] transform lesson to sandpaper",
  committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
  repo = new
)

json_out <- list(chchchchanges)
names(json_out) <- change_id


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

