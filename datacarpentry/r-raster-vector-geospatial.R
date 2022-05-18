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

purrr::walk(old_lesson$episodes, fix_setup_link)

setup <- readLines(fs::path(new, "setup.R"))
unlink(fs::path(new, "setup.R"))

writeLines(c("options(timeout = max(300, getOption('timeout')))", setup), 
  fs::path(new, "episodes", "setup.R"))
