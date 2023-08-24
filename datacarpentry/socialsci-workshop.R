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

child_from_include <- function(ep) {
  rlang::inform(c(i = ep$path))
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
  path <- fs::path_ext_set(ep$path, "Rmd")
  fs::file_move(ep$path, path)
  ep$write(fs::path_dir(path), format = "Rmd")
}

child_from_include(old_lesson$extra$setup.md)
child_from_include(old_lesson$extra$"setup-r-workshop.md")
child_from_include(old_lesson$extra$"setup-python-workshop.md")

