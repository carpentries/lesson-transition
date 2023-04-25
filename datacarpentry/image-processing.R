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
# old        <- 'datacarpentry/image-processing'
# new        <- 'sandpaper/datacarpentry/image-processing'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

cli::cli_alert("Moving files intended for learners")
fs::file_move(to("instructors/prereqs.md"), to("learners/prereqs.md"))
fs::file_move(to("instructors/edge-detection.md"), to("learners/edge-detection.md"))

cli::cli_alert("fixing setup file link")
idx <- sub("(setup.md", "(learners/setup.md", readLines(to("index.md")), fixed = TRUE)
writeLines(idx, to("index.md"))

stp <- readLines(to("learners/setup.md"))
to_fix <- grepl("  [^ ]", stp)
stp[to_fix] <- sub("^  ", "   ", stp[to_fix])
writeLines(stp, to("learners/setup.md"))
