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
# old        <- 'librarycarpentry/lc-spreadsheets'
# new        <- 'sandpaper/librarycarpentry/lc-spreadsheets'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

ep <- old_lesson$episodes[["02-common-mistakes.md"]]
lnks <- ep$validate_links(warn = FALSE)
to_fix <- lnks$node[!lnks$internal_anchor]
purrr::walk(to_fix, function(node) {
  dst <- xml2::xml_attr(node, "destination")
  xml2::xml_set_attr(node, "destination", gsub("_", "-", dst))
})
write_out_md(ep)

