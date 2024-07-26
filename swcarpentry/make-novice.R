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
# old        <- 'swcarpentry/make-novice'
# new        <- 'sandpaper/swcarpentry/make-novice'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

dl_auto_id(to("learners/reference.md"))

# fix code dir kerfuffle ---------------------------------------
fs::dir_create(to("episodes/files"))
copy_dir(to("code"), to("episodes/files/code"))
del_dir(to("code"))

suppressMessages(lnks <- old_lesson$validate_links())
to_fix <- startsWith(lnks$orig, "code/")
purrr::walk(lnks$node[to_fix], function(node) {
  dst <- xml2::xml_attr(node, "destination")
  xml2::xml_set_attr(node, "destination", fs::path("files", dst))
})
eps <- unique(lnks$episode[to_fix])
purrr::walk(old_lesson$episodes[eps], write_out_md, "episodes")
