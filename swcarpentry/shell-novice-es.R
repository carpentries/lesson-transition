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
# old        <- 'swcarpentry/shell-novice-es'
# new        <- 'sandpaper/swcarpentry/shell-novice-es'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# add definition list links back into reference -----------------
dl_auto_id(to("learners/reference.md"))

ref <- pegboard::Episode$new(to("learners/reference.md"))$confirm_sandpaper()
ank <- ref$validate_links(warn = FALSE)
to_fix <- ank$node[!ank$internal_anchor]
txts <- paste("##", purrr::map_chr(to_fix, xml2::xml_text))
headings <- pandoc::pandoc_convert(text = txts, to = "html")
ids <- paste(headings, collapse = "\n")
ids <- xml2::xml_text(xml2::xml_find_all(xml2::read_html(ids), ".//h2/@id"))
purrr::walk2(to_fix, ids, function(node, id) {
  xml2::xml_set_attr(node, "destination", paste0("#", id))
})
write_out_md(ref, "learners")
sandpaper::set_config(c(lang = "'es'"), path = to(), write = TRUE)
