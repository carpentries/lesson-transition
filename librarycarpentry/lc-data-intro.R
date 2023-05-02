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
# old        <- 'librarycarpentry/lc-data-intro'
# new        <- 'sandpaper/librarycarpentry/lc-data-intro'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

new_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)
suppressMessages(lnks <- new_lesson$validate_links())

to_fix <- grepl("^[/].+?[/]\\d{2}-", lnks$path)
lc_fix <- lnks$node[to_fix & lnks$server == "librarycarpentry.org"]
purrr::walk(lc_fix, function(node) {
  dst <- xml2::url_parse(xml2::xml_attr(node, "destination"))
  if (!startsWith(dst$path, "/lc-data-intro")) {
    lnk <- fs::path(dst$server, fs::path_dir(dst$path))
    lnk <- paste0(dst$scheme, "://", lnk)
  } else {
    lnk <- fs::path_ext_set(fs::path_split(dst$path)[[1]][[3]], "md")
  }
  if (lnk == "05-ordering-commenting.md") {
    # episode name was changed at some point in the past
    lnk <- "04-ordering-commenting.md"
  }
  lnk <- ifelse(dst$fragment == "", lnk, paste0(lnk, "#", dst$fragment))
  xml2::xml_set_attr(node, "destination", lnk)
})

all_fix <- to_fix

this <- "/librarycarpentry/lc-data-intro/tree/gh-pages/"
that <- "/librarycarpentry/lc-data-intro/blob/gh-pages/"
to_fix <- startsWith(tolower(lnks$path), this) | startsWith(tolower(lnks$path), that)
purrr::walk(lnks$node[to_fix], function(node) {
  dst <- xml2::xml_attr(node, "destination")
  new <- sub("gh-pages", "main", dst)
  if (endsWith(new, "files")) {
    xml2::xml_set_text(node, "episodes/files")
  }
  xml2::xml_set_attr(node, "destination", new)
})
all_fix <- to_fix | all_fix

to_write <- unique(lnks$filepath[all_fix])
purrr::walk(to_write, function(ep) {
  folder <- fs::path_dir(ep)
  file   <- fs::path_file(ep)
  if (folder == "episodes") {
    write_out_md(new_lesson$episodes[[file]], folder)
  } else {
    write_out_md(new_lesson$extra[[file]], folder)
  }
})
