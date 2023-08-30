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
# old        <- 'librarycarpentry/lc-overview'
# new        <- 'sandpaper/librarycarpentry/lc-overview'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

sandpaper::set_config(
  pairs = c(
    sandpaper = "carpentries/sandpaper#496", 
    varnish = "carpentries/varnish#87"
  ),
  write = TRUE,
  create = TRUE,
  path = new
)

to_find <- paste0("$(find ", new, "/ -name '*md')")
system2("sed", c("-i -r -e", "'s/[^a-z] solution/: spoiler/g'", to_find))
