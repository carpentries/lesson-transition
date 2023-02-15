# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

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
purrr::walk(old_lesson$episodes, remove_setup)
purrr::walk(old_lesson$episodes, write_out)
