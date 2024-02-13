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
# old        <- 'datacarpentry/openrefine-socialsci'
# new        <- 'sandpaper/datacarpentry/openrefine-socialsci'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

dl_auto_id(to("learners/reference.md"))
stp <- readLines(to("learners/setup.md"))
to_fix <- grepl("^[- ] ", stp)
stp[to_fix] <- paste0(" ", stp[to_fix])
callouts <- grepl("^   [:]{3,}", stp)
the_tail <- grepl("^   [:]+$", stp)
the_head <- which(callouts & !the_tail)
the_tail <- which(the_tail)
stp <- c(stp[1:(the_head - 1L)], 
  "   ", 
  stp[the_head:the_tail],
  "   ",
  stp[(the_tail + 1):length(stp)]
)
writeLines(stp, to("learners/setup.md"))
