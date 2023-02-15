# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

fix_these_links <- function(lnks) {
  purrr::walk2(lnks$node, lnks$orig, 
    \(a, b) xml2::xml_set_attr(a, "destination", b))
}

remove_index_links <- function(lnks) {
  need_fixing <- lnks$scheme == "" & grepl("/index.html", lnks$path)
  lnks[need_fixing, ]$orig <- sub("/index", "", lnks[need_fixing, ]$orig, fixed = TRUE)
  fix_these_links(lnks[need_fixing, ])
}

make_raw_links_relative <- function(lnks) {
  raw_links <- grepl("githubusercontent", lnks$orig) &
    grepl("_episode", lnks$path)
  lnks[raw_links, ]$orig <- sub("https://.+?_episodes_rmd/", "", lnks[raw_links, ]$orig)
  fix_these_links(lnks[raw_links, ])
}


fix_lesson_links <- function(lsn) {
  lnks <- lsn$validate_links()
  remove_index_links(lnks)
  make_raw_links_relative(lnks)
}

remove_setup <- function(ep) {
  blocks <- ep$code
  txt <- xml2::xml_text(blocks)
  bad <- grepl("(chunk-options.R|knitr_fig_path)", txt)
  if (sum(bad) == 0L) {
    return(invisible(ep))
  }
  txt[bad] <- purrr::map_chr(txt[bad], \(x) {
    pt <- parse(text = x)
    paste(pt[!grepl("(chunk-options.R|knitr_fig_path)", pt)], collapse = "\n")
  })
  xml2::xml_set_text(blocks, txt)
  if (any(txt[bad] == "")) {
    xml2::xml_remove(blocks[bad])
  }
  invisible(ep)
}
write_out <- function(ep) {
  ep$write(fs::path(new, "episodes"), format = "Rmd")
}
cli::cli_h2("fixing broken links")
fix_lesson_links(old_lesson)
purrr::walk(old_lesson$episodes, remove_setup)
purrr::walk(old_lesson$episodes, write_out)
