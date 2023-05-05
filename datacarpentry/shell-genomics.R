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
# old        <- 'datacarpentry/shell-genomics'
# new        <- 'sandpaper/datacarpentry/shell-genomics'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# add definition list links back into reference -----------------
dl_auto_id(to("learners/reference.md"))

# fix weird thing in episode 5

e5 <- old_lesson$episodes[[5]]
e5$reset()
xml2::xml_set_attr(e5$get_blocks(level = 2)[[1]], "ktag", "{: .solution}")
transform(e5)


# Reading new lesson to fix old sins -------------------------
new_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)
purrr::walk(new_lesson$get("links"), function(lnks) {
  if (length(lnks) == 0) {
    return(NULL)
  }
  dst <- xml2::xml_attr(lnks, "destination")
  no <- "https...(www.)?datacarpentry.org[/]shell-genomics[/]([^/]+?)[/]?(index.html)?$"
  dst <- sub(no, "\\2.md", dst)
  no <- "https://www.datacarpentry"
  dst <- sub(no, "https://datacarpentry", dst)
  to_fix <- startsWith(dst, "https://datacarpentry")
  dst[to_fix] <- sub("[/](index.html)?([#].+?)?$", "\\2", dst[to_fix])
  xml2::xml_set_attr(lnks, "destination", dst)
})

# write out episodes
purrr::walk(new_lesson$episodes, write_out_md)
