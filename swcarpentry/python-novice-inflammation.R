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
# old        <- 'swcarpentry/python-novice-inflammation'
# new        <- 'sandpaper/swcarpentry/python-novice-inflammation'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)


# Renamed files ---------------------------------------
# episodes/11-debugging.md:93 [missing file] 01-numpy/
# episodes/12-cmdline.md:707 [missing file] 04-files/
links <- old_lesson$get("links")
ep11 <- links[["11-debugging.md"]]
dst <- xml2::xml_attr(ep11, "destination")
to_fix <- dst =="01-numpy/"
xml2::xml_set_attr(ep11[to_fix], "destination", "02-numpy.html")
write_out_md(old_lesson$episodes[["11-debugging.md"]])
ep12 <- links[["12-cmdline.md"]]
dst <- xml2::xml_attr(ep12, "destination")
to_fix <- dst =="04-files/"
xml2::xml_set_attr(ep12[to_fix], "destination", "06-files.html")
write_out_md(old_lesson$episodes[["12-cmdline.md"]])


