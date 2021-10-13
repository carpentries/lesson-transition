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
library("gert")
library("here")
library("fs")

src <- here()
lsn <- tempfile()
there <- function(...) path(lsn, ...)

repo_path <- getOption("new.sandpaper.repo", 
  default = paste0("../sandpaper-", basename(getwd()))
)

pgap <- pegboard::Lesson$new(src)
# Script to transform the episodes via pegboard with traces
transform <- function(e, out = lsn) {
  outdir <- fs::path(out, "episodes/")
  cli::cat_rule(fs::path_rel(e$name, out)) # -----------------------------------
  cli::cli_process_start(glue::glue(" converting blockquotes to fenced div"))
  e$unblock()
  cli::cli_process_done()

  cli::cli_process_start(glue::glue("removing Jekyll syntax"))
  e$use_sandpaper()
  cli::cli_process_done()

  cli::cli_process_start(glue::glue("moving yaml items to body"))
  e$move_questions()
  e$move_objectives()
  e$move_keypoints()
  cli::cli_process_done()

  cli::cli_process_start(glue::glue("writing output"))
  e$write(outdir, format = "Rmd", edit = FALSE)
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

# Create lesson
cli::cli_h1("creating a new sandpaper lesson")
suppressWarnings(cfg <- yaml::read_yaml(here("_config.yml")))
create_lesson(lsn, name = cfg$title, open = FALSE)
file_delete(there("episodes", "01-introduction.Rmd"))
file_delete(there("index.md"))

# appending our gitignore file
file.append(there(".gitignore"), here(".gitignore"))

# Modify config file to match as close as possible to the one we have
cli::cli_h2("setting the configuration parameters in config.yaml")
set_config("title", cfg$title)
set_config("life_cycle", cfg$life_cycle)
set_config("contact", cfg$email)

if (length(gert::git_remote_list(repo = src)) == 0) {
  message("Cannot automatically set the following configuration values:\n source: <GITHUB URL>\n carpentry: <CARPENTRY ABBREVIATION>\n\nPlease edit config.yaml to set these values")
} else {
  rmt <- gert::git_remote_list(repo = src)
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
purrr::walk(pgap$episodes, ~try(transform(.x)))
set_episodes(lsn, order = names(pgap$episodes), write = TRUE)

# Modify the index to include our magic header
idx <- list.files(".", pattern = "^index.R?md")
if (length(idx)) {
  idx <- if (length(idx) == 2) "index.Rmd" else idx
  idx <- Episode$new(idx, fix_liquid = TRUE)
  idx$yaml[length(idx$yaml) + 0:1] <- c("site: sandpaper::sandpaper_site", "---")
  idx$unblock()$use_sandpaper()
}

# write index and readme
idx$write(path = path(lsn), format = "md")
file_copy(here("README.md"), there("README.md"), overwrite = TRUE)

# Transform non-episode MD files
cli::cli_h2("copying instructor and learner materials")
rewrite(here("_extras", "design.md"), there("instructors"))
rewrite(here("_extras", "guide.md"), there("instructors"))
rewrite(here("_extras", "discuss.md"), there("learners"))
rewrite(here("_extras", "exercises.md"), there("learners"))
rewrite(here("_extras", "figures.md"), there("learners"))
rewrite(here("reference.md"), there("learners"))
rewrite(here("setup.md"), there("learners"))

# Copy Figures (N.B. this was one of the pain points for the Jekyll lessons: figures lived above the RMarkdown documents)
cli::cli_h2("copying figures, files, and data")
fs::dir_copy(here("fig"), there("episodes/fig"), overwrite = TRUE)
fs::dir_copy(here("files"), there("episodes/files"), overwrite = TRUE)
fs::dir_copy(here("data"), there("episodes/data"), overwrite = TRUE)


cli::cli_h1("Copying transformed lesson to {repo_path}")
dir_copy(lsn, repo_path)
cli::cli_alert_info("Committing...")
git_add(".", repo = repo_path)
git_commit("Transfer lesson to sandpaper",
  committer = "Carpentries Apprentice <zkamvar+machine@gmail.com>",
  repo = repo_path
)
cli::cli_alert_info("The lesson is ready in {.file {repo_path}}")
