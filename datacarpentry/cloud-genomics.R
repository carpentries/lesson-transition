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
# old        <- 'datacarpentry/cloud-genomics'
# new        <- 'sandpaper/datacarpentry/cloud-genomics'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

fs::file_move(to("instructors/LaunchingInstances.md"), to("learners/LaunchingInstances.md"))

e2 <- old_lesson$episodes[[2]]
dst <- xml2::xml_attr(e2$links, "destination")
xml2::xml_set_attr(e2$links, "destination", sub("instructors", "learners", dst))
write_out_md(e2)
