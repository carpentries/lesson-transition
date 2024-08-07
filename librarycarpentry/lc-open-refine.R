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
# old        <- 'librarycarpentry/lc-open-refine'
# new        <- 'sandpaper/librarycarpentry/lc-open-refine'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

assets <- dir_ls(from("assets/img"))
figs <- assets[!grepl('^(cp|dc|lc|swc|carp)', fs::path_file(assets))]
fs::dir_create(to("episodes/fig"))
fs::file_copy(figs, to("episodes/fig", fs::path_file(figs)))
