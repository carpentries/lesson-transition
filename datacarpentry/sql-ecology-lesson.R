# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson


lnks <- old_lesson$validate_links()
to_fix <- lnks$node[!lnks$internal_file & grepl("setup", lnks$orig)]
purrr::walk(to_fix, function(link) {
  xml2::xml_set_attr(link, "destination", "../learners/setup.md")
})
purrr::walk(old_lesson$episodes, function(x) {
  xml2::xml_set_attr(x$code, "info", "sql")
  write_out_md(x)
})

