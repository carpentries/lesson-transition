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
# old        <- 'librarycarpentry/lc-sql'
# new        <- 'sandpaper/librarycarpentry/lc-sql'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

assets <- dir_ls(from("assets/img"))
figs <- assets[!grepl('^(cp|dc|lc|swc|carp)', fs::path_file(assets))]
fs::dir_create(to("episodes/fig"))
fs::file_copy(figs, to("episodes/fig", fs::path_file(figs)))
fs::file_move(to("instructors/learner_profile.md"), to("profiles"))
profile <- pegboard::Episode$new(to("profiles/learner_profile.md"))$confirm_sandpaper()
profile$yaml[2] <- "title: 'Elias'"
profile$write(to("profiles"), format = "md")

new_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)
suppressMessages(lnks <- new_lesson$validate_links())
to_fix <- lnks$node[!lnks$internal_file][[1]]
dst <- xml2::xml_attr(to_fix, "src")
dst <- sub("assets/", "", dst)

xml2::xml_set_attr(to_fix, "src", dst)
xml2::xml_set_attr(to_fix, "destination", dst)

to_fix <- grepl("^[/].+?[/]\\d{2}-", lnks$path)
lc_fix <- lnks$node[to_fix & lnks$server == "librarycarpentry.org"]
purrr::walk(lc_fix, function(node) {
  dst <- xml2::url_parse(xml2::xml_attr(node, "destination"))
  lnk <- fs::path_ext_set(fs::path_split(dst$path)[[1]][[3]], "md")
  if (lnk == "05-ordering-commenting.md") {
    # episode name was changed at some point in the past
    lnk <- "04-ordering-commenting.md"
  }
  lnk <- ifelse(dst$fragment == "", lnk, paste0(lnk, "#", dst$fragment))
  xml2::xml_set_attr(node, "destination", lnk)
})

swc_fix <- lnks$node[to_fix & lnks$server == "swcarpentry.github.io"]
purrr::walk(swc_fix, function(node) {
  dst <- xml2::url_parse(xml2::xml_attr(node, "destination"))
  lnk <- fs::path(dst$server, fs::path_dir(dst$path))
  lnk <- paste0("https://", lnk)
  xml2::xml_set_attr(node, "destination", lnk)
})

to_write <- unique(lnks$filepath[to_fix])
purrr::walk(to_write, function(ep) {
  folder <- fs::path_dir(ep)
  file   <- fs::path_file(ep)
  if (folder == "episodes") {
    write_out_md(new_lesson$episodes[[file]], folder)
  } else {
    write_out_md(new_lesson$extra[[file]], folder)
  }
})

# fix eventually broken link to source
ep9 <- readLines(to("episodes/09-create.md"))
ep9[grepl("gh-pages", ep9)] <- "<https://swcarpentry.github.io/sql-novice-survey/09-create>"
writeLines(ep9, to("episodes/09-create.md"))


# fix damn assets link that just won't go away :weary:
ep8 <- readLines(to("episodes/08-database-design.md"))
ep8 <- sub("assets[/]img", "fig", ep8)
writeLines(ep8, to("episodes/08-database-design.md"))
