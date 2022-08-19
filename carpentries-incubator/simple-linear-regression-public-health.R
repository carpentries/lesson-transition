# copy over the necessary data files and modify the setup chunks
dir_create(path(new, 'episodes', c('data', 'files')))
file_copy(path(old, "bin", "data.RData"), path(new, 'episodes', 'data', 'data.RData'), overwrite = TRUE)
file_copy(path(old, "bin", "obtain_data.R"), path(new, 'episodes', 'files', 'obtain_data.R'), overwrite = TRUE)
l <- Lesson$new(new, jekyll = FALSE)
fix_setup <- function(ep) {
  setup <- ep$code[[1]]
  loader <- xml2::xml_text(setup)
  xml2::xml_set_text(setup, sub("../bin/data", "data/data", loader))
}
write_out <- function(ep) {
  ep$protect_math()$write(path_dir(ep$path), format = path_ext(ep$path))
}
purrr::walk(l$episodes, fix_setup)
e5 <- l$episodes[[5]]
missed <- e5$get_blocks()
xml_set_attr(missed, attr = "ktag", "{: .solution}")
pegboard:::replace_with_div(missed)

purrr::walk(l$episodes, write_out)
options("custom.transformation.message" = "fix path to data and missed solution")
