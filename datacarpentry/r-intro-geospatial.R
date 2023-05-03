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
# old        <- 'datacarpentry/r-intro-geospatial'
# new        <- 'sandpaper/datacarpentry/r-intro-geospatial'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# tranform gap in challenge block ------------------------------
e7path <- old_lesson$episodes[["07-plot-ggplot2.Rmd"]]$path
tmp <- withr::local_tempdir()
tmpfile <- fs::path(tmp, "07-plot-ggplot2.Rmd")
e7 <- readLines(e7path)
if (!startsWith(e7[96], ">")) {
  e7[96] <- paste0("> >", e7[96])
  writeLines(e7, tmpfile)
  old_lesson$episodes[["07-plot-ggplot2.Rmd"]] <- pegboard::Episode$new(tmpfile)
  transform(old_lesson$episodes[["07-plot-ggplot2.Rmd"]])
}


# add definition list links back into reference -----------------
dl_auto_id(to("learners/reference.md"))

# fix bad download links in code
e4 <- old_lesson$episodes[[4]]
to_fix <- e4$code[grepl("raw.github", xml2::xml_text(e4$code))]
purrr::walk(to_fix, function(node) {
  txt <- xml2::xml_text(node)
  bad <- "raw.githubusercontent.com/datacarpentry/r-intro-geospatial/master/_episodes_rmd/"
  txt <- gsub(bad, "datacarpentry.org/r-intro-geospatial/", txt)
  xml2::xml_set_text(node, txt)
})
