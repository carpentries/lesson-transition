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
# pandoc::pandoc_activate("3.1.2")
# source("functions.R")
# old        <- 'datacarpentry/spreadsheets-socialsci'
# new        <- 'sandpaper/datacarpentry/spreadsheets-socialsci'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

e2 <- readLines(to("episodes/02-common-mistakes.md"))
e2 <- sub("[_](name|pretty)", "-\\1", e2)
writeLines(e2, to("episodes/02-common-mistakes.md"))
