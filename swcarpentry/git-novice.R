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
# old        <- 'swcarpentry/git-novice'
# new        <- 'sandpaper/swcarpentry/git-novice'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# add definition list links back into reference -----------------
dl_auto_id(to("learners/reference.md"))

# fix table in episode 2 ----------------------------------------
e2 <- readLines(to("episodes/02-setup.md"))
dash <- function(n, thing = "-") paste(rep(thing, n), collapse = "")
sp <- c("| :", dash(11), dash(25, " "), " | :", dash(30), " |")
e2[startsWith(e2, "| :")] <- paste(sp, collapse = "")
writeLines(e2, to("episodes/02-setup.md"))

# fix caption in episode 5 ---------------------------------------
e5 <- readLines(to("episodes/05-history.md"))
e5[startsWith(e5, "![http")] <- "![https://figshare.com/articles/How_Git_works_a_cartoon/1328266](fig/git_staging.svg)"
writeLines(e5, to("episodes/05-history.md"))
