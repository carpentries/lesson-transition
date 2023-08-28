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
# old        <- 'datacarpentry/socialsci-workshop'
# new        <- 'sandpaper/datacarpentry/socialsci-workshop'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

child_from_include <- function(from, to = NULL) {
  to <- if (is.null(to)) fs::path_ext_set(from, "Rmd") else to
  rlang::inform(c(i = from))
  ep <- pegboard::Episode$new(from)
  # find all the {% include file.ext %} statements
  includes <- xml2::xml_find_all(ep$body, 
    ".//md:text[starts-with(text(), '{% include')]", ns = ep$ns)
  # trim off everything but our precious file path
  f <- gsub("[%{ }]|include", "", xml2::xml_text(includes))
  # give it a name 
  fname <- paste0("include-", fs::path_ext_remove(f))
  # make sure the file path is correct
  f <- sQuote(fs::path("files", f), q = FALSE)
  p <- xml2::xml_parent(includes)
  xml2::xml_remove(includes)
  xml2::xml_set_name(p, "code_block")
  xml2::xml_set_attr(p, "language", "r")
  xml2::xml_set_attr(p, "child", f)
  xml2::xml_set_attr(p, "name", fname)
  fs::file_move(from, to)
  ep$write(fs::path_dir(to), format = "Rmd")
}

child_from_include(to("learners/setup.md"))
child_from_include(to("setup-r-workshop.md"))
child_from_include(to("setup-python-workshop.md"))
fs::file_move(to("instructors/data.md"), to("learners/data.md"))

