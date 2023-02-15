# requested at https://github.com/carpentries-incubator/bioc-project/issues/48
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

fix_bib_code <- function(ep) {
  bib_code <- ep$code 
  bib_code <- bib_code[grepl("bibliography.bib", xml2::xml_text(bib_code))]
  txt <- parse(text = xml2::xml_text(bib_code))
  new_txt <- gsub("../bibliography.bib", "files/bibliography.bib", txt)
  xml2::xml_set_text(bib_code, paste(new_txt, collapse = "\n"))
  invisible(ep)
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

stop_install_codes <- function(ep) {
  inst_code <- ep$code 
  inst_code <- inst_code[grepl("BiocManager::install", xml2::xml_text(inst_code))]
  if (length(inst_code)) {
    xml2::xml_set_attr(inst_code, "eval", "FALSE")
  }
  invisible(ep)
}

write_out <- function(ep) {
  ep$write(fs::path(new, "episodes"), format = "Rmd")
}

fix_lesson_links(old_lesson)

fs::dir_create(to("episodes/files/"))
fs::file_move(to("bibliography.bib"), to("episodes/files/bibliography.bib"))
fix_bib_code(old_lesson$episodes[["02-introduction-to-bioconductor.Rmd"]])
fix_bib_code(old_lesson$episodes[["07-genomic-ranges.Rmd"]])

purrr::walk(old_lesson$episodes, stop_install_codes)
purrr::walk(old_lesson$episodes, remove_setup)
purrr::walk(old_lesson$episodes, write_out)
