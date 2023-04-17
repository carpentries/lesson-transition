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
# old        <- 'datacarpentry/spreadsheet-ecology-lesson'
# new        <- 'sandpaper/datacarpentry/spreadsheet-ecology-lesson'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

dl_auto_id(to("learners/reference.md"))

mistakes <- old_lesson$episodes[[3]]
lnks <- mistakes$validate_links(warn = FALSE)
to_fix <- lnks$node[!lnks$internal_anchor]
purrr::walk(to_fix, \(x) {
  dest <- xml2::xml_attr(x, "destination")
  xml2::xml_set_attr(x, "destination", gsub("_", "-", dest))
})
xml2::xml_set_text(mistakes$headings, 
  gsub("_", "-", xml2::xml_text(mistakes$headings)))

write_out_md(mistakes)

