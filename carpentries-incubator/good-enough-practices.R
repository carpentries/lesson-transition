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
# old        <- 'carpentries-incubator/good-enough-practices'
# new        <- 'sandpaper/carpentries-incubator/good-enough-practices'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# remove the Liquid comment that becomes visible in Workbench lesson
landing_page <- readLines(to("index.md"))
landing_page <- sub('\\{% comment %\\} This is a comment in Liquid \\{% endcomment %\\}', '', landing_page)
writeLines(landing_page, to("index.md"))

# remove double quotes in alt text
## data management episode
dataman <- readLines(to("episodes/02-data_management.md"))
dataman <- gsub('[\\]{2}["]', "'", dataman)
writeLines(dataman, to("episodes/02-data_management.md"))
## software episode
software <- readLines(to("episodes/03-software.md"))
software <- gsub('[\\]{2}["]', "'", software)
writeLines(software, to("episodes/03-software.md"))

# escape dollar signs to avoid USD amounts being mistaken for LaTeX syntax
track_changes <- readLines(to("episodes/06-track_changes.md"))
track_changes <- gsub('\\$5', '\\\\\\\\$5', track_changes)
writeLines(track_changes, to("episodes/06-track_changes.md"))



