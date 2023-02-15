# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

# Episode 6, visualisation includes a setup chunk after the first setup chunk,
# so we need to remove that one.
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

cli::cli_h2("Fixing backtics figure caption for 30-dplyr.Rmd")
cli::cli_alert_info("See {.url https://github.com/ropensci/tinkr/issues/89}")
dplyr_ep_path <- old_lesson$episodes[["30-dplyr.Rmd"]]$path
dplyr_ep_text <- readLines(dplyr_ep_path)
baddies <- grepl("```[{].+?`", dplyr_ep_text)
dplyr_ep_text[baddies] <- gsub("([^`])([`])([^`])", "\\1&#96;\\3", dplyr_ep_text[baddies])

tmp <- tempfile()
fs::dir_create(tmp)
new_dplyr_ep_path <- fs::path(tmp, fs::path_file(dplyr_ep_path))
writeLines(dplyr_ep_text, new_dplyr_ep_path)
old_lesson$episodes[["30-dplyr.Rmd"]] <- pegboard::Episode$new(new_dplyr_ep_path)
transform(old_lesson$episodes[["30-dplyr.Rmd"]])

cli::cli_h2("Removing stray setup chunks")
purrr::walk(old_lesson$episodes, remove_setup)
purrr::walk(old_lesson$episodes, write_out)

