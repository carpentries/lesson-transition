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
# old        <- 'datacarpentry/sql-socialsci'
# new        <- 'sandpaper/datacarpentry/sql-socialsci'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

inot <- readLines(to("instructors/instructor-notes.md"))
inot <- sub("episodes08_sqlite-command-lines.md", "episodes/08-sqlite-command-line.md", inot, fixed = TRUE)
writeLines(inot, to("instructors/instructor-notes.md"))
