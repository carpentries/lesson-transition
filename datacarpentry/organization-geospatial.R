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
# old        <- 'datacarpentry/organization-geospatial'
# new        <- 'sandpaper/datacarpentry/organization-geospatial'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# Fix preamble code ---------------------------------------------
fs::dir_create(to("episodes/files/"))
fs::file_move(to("setup.R"), to("episodes/files/setup.R"))
replace_source <- function(ep) {
  setup <- ep$code[1]
  txt <- sub("../setup.R", "files/setup.R", xml2::xml_text(setup))
  xml2::xml_set_text(setup, txt)
  write_out_rmd(ep)
}
purrr::walk(old_lesson$episodes, replace_source)
