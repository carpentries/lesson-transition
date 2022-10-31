fix_setup_link <- function(ep) {
  setup <- ep$code[[which(xml2::xml_attr(ep$code, "name") == "setup")[1]]]
  txt <- xml2::xml_text(setup)
  xml2::xml_set_text(setup, gsub("\\.\\./setup.R", "setup.R", txt))
  ep$write(fs::path(new, "episodes"), format = "Rmd")
}
ep <- old_lesson$episodes[["03-raster-reproject-in-r.Rmd"]]
is_solution <- ep$get_blocks()[[1]]
xml2::xml_set_attr(is_solution, "ktag", "{: .solution}")
pegboard:::replace_with_div(is_solution)
ep$label_divs()

# We have some links that were not detected in our setup 
transform_missing_links <- function(ep) {
  braces <- ".//md:text[contains(text(), '{{')]"
  to_fix <- xml2::xml_find_all(ep$body, braces, ep$ns)
  if (length(to_fix) == 0L) {
    # if we did not find anything, bail early
    return(to_fix)
  }
  txt <- xml2::xml_text(to_fix)
  # Find the pattern of {{ site.baseurl }}
  base <- "[{][{]\\s*?site\\.baseurl\\s*?[}][}]"
  # if it is by itself, it is the index page
  index <- paste0(base, "[)]")
  txt <- sub(index, "../index.md)", txt)
  # otherwise, it is a link to a specific page
  page  <- paste0(base, "[/]([^/]+?)[/]")
  txt <- sub(page, "\\1.Rmd", txt)
  xml2::xml_set_text(to_fix, txt)
}

fix_raster_episodes <- function(ep) {
  transform_missing_links(ep)
  fix_setup_link(ep)
}

purrr::walk(old_lesson$episodes, fix_raster_episodes)

# Make sure that fetching the data does not timeout 
setup <- readLines(fs::path(new, "setup.R"))
unlink(fs::path(new, "setup.R"))
writeLines(c("options(timeout = max(300, getOption('timeout')))", setup), 
  fs::path(new, "episodes", "setup.R"))
