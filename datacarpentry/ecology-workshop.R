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
# old        <- 'datacarpentry/ecology-workshop'
# new        <- 'sandpaper/datacarpentry/ecology-workshop'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

child_from_include <- function(from, to = NULL) {
  to <- if (is.null(to)) fs::path_ext_set(from, "Rmd") else to
  rlang::inform(c(i = from))
  ep <- pegboard::Episode$new(from)
  # find all the {% include file.ext %} statements
  includes <- xml2::xml_find_all(ep$body, 
    ".//md:text[starts-with(text(), '{% include')]", ns = ep$ns)
  # trim off everything but our precious file path
  f <- gsub("[%{ }]|include", "", xml2::xml_text(includes))
  # give it a name 
  fname <- paste0("include-", fs::path_ext_remove(f))
  # make sure the file path is correct
  f <- sQuote(fs::path("files", f), q = FALSE)
  p <- xml2::xml_parent(includes)
  xml2::xml_remove(includes)
  xml2::xml_set_name(p, "code_block")
  xml2::xml_set_attr(p, "language", "r")
  xml2::xml_set_attr(p, "child", f)
  xml2::xml_set_attr(p, "name", fname)
  fs::file_move(from, to)
  ep$write(fs::path_dir(to), format = "Rmd")
}

child_from_include(to("learners/setup.md"))
child_from_include(to("setup-r-workshop.md"))
child_from_include(to("setup-python-workshop.md"))
fs::file_move(to("instructors/data.md"), to("learners/data.md"))

new_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

fix_destinations <- function(nodes) {
  if (is.null(nodes)) {
    return(NULL)
  }
  dest <- xml2::xml_attr(nodes, "destination")
  dest <- sub("[/]guide[/](index.html)?", "instructor/instructor-notes.html", dest)
  dest <- sub("[/]setup.html", "/index.html#setup", dest)
  xml2::xml_set_attr(nodes, "destination", dest)
  nodes
}

lnks <- new_lesson$get("links", "extra")
purrr::walk(names(lnks), function(i) {
  res <- fix_destinations(lnks[[i]])
  if (length(res)) {
    ep <- new_lesson$extra[[i]]
    path <- ep$path
    ep$write(fs::path_dir(path), format = fs::path_ext(path))
  }
})

idx <- readLines(fs::path(new, "index.md"))
fix_table_head <- function(x) {
  y <- sub(" | ", "---", x, fixed = TRUE)
  substring(y, floor(nchar(y)/2) - 1L, floor(nchar(y)/2) + 1L) <- " | "
  y
}
heads <- grepl("| ---", idx, fixed = TRUE)
idx[heads] <- purrr::map_chr(idx[heads], fix_table_head)
writeLines(idx, fs::path(new, "index.md"))


sandpaper::set_config(
  c("created" = "2015-12-12"),
  path = new,
  write = TRUE
)

to_find <- paste0("$(find ", new, "/ -name '*md')")
system2("sed", c("-i -r -e", "'s/[^a-z] solution/: spoiler/g'", to_find))
system2("sed", c("-i -r -e", "'s_https://example.com/FIXME_https://github.com/datacarpentry/ecology-workshop_g'", fs::path(new, "CONTRIBUTING.md")))
