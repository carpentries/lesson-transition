# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

# During iteration: use these to provision the variables and functions
# that would be normally available when this script is run
#
# library("fs")
# library("xml2")
# pandoc::pandoc_activate("2.19.2")
# source("functions.R")
# old        <- 'datacarpentry/astronomy-python'
# new        <- 'sandpaper/datacarpentry/astronomy-python'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

cli::cli_h2("Fixing missed links in <img> tags")
new_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)
suppressMessages(lnks <- new_lesson$validate_links())
to_fix <- !lnks$internal_file & lnks$type == "img"
files <- to(unique(lnks$filepath[to_fix]))
purrr::walk(files, function(f) {
  cli::cli_alert("reading {f}")
  l <- readLines(f)
  new <- gsub("../fig", "fig", l, fixed = TRUE)
  cli::cli_alert("writing changes to {f}")
  writeLines(new, f)
})

cli::cli_h2("Fixing link in instructor notes")
ino <- readLines(to("instructors/instructor-notes.md"))
ino <- sub("/astronomy-python/calculating_MIST_isochrone", "calculating_MIST_isochrone.md", ino, fixed = TRUE)
writeLines(ino, to("instructors/instructor-notes.md"))

cli::cli_h2("Increasing the size of the HTTP postBuffer to 500MB")
cli::cli_alert_info("Ref: {.url https://medium.com/swlh/everything-you-need-to-know-to-resolve-the-git-push-rpc-error-1a865fd1ebea}")
# increase the level of the postbuffer due to large objects
gert::git_config_set(name = "http.postBuffer", value = "524288000", repo = new)
