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
# old        <- 'datacarpentry/sql-ecology-lesson'
# new        <- 'sandpaper/datacarpentry/sql-ecology-lesson'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

cli::cli_alert("fixing broken links to setup")
suppressMessages(lnks <- old_lesson$validate_links())
to_fix <- lnks$node[!lnks$internal_file & grepl("setup", lnks$orig)]
purrr::walk(to_fix, function(link) {
  xml2::xml_set_attr(link, "destination", "../learners/setup.md")
})

# add highlighting to code 
cli::cli_alert("add highlighting to code")
purrr::walk(old_lesson$episodes, function(x) {
  xml2::xml_set_attr(x$code, "info", "sql")
  write_out_md(x)
})

cli::cli_alert("Fixing broken link in setup.md")

stp <- pegboard::Episode$new(to("learners/setup.md"))
lnks <- stp$validate_links(warn = FALSE)
to_fix <- lnks$node[!lnks$internal_file & grepl("^[/]sql[-]ecology", lnks$orig)]

purrr::walk(to_fix, function(link) {
  f <- fs::path_file(xml2::xml_attr(link, "destination"))
  f <- fs::path_ext_set(f, "md")
  xml2::xml_set_attr(link, "destination", paste0("../episodes/", f))
})

write_out_md(stp, "learners")

cli::cli_alert("fixing http -> https in contributors")

ctb <- sub("http[:]", "https:", readLines(to("CONTRIBUTORS.md")))
writeLines(ctb, to("CONTRIBUTORS.md"))


