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
# pandoc::pandoc_activate("3.1.2")
# source("functions.R")
# old        <- 'datacarpentry/python-ecology-lesson'
# new        <- 'sandpaper/datacarpentry/python-ecology-lesson'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# fix glossary ids -----------------------------------------------------------
dl_auto_id(to("learners/reference.md"))

# fix dang HTML --------------------------------------------------------------
stp <- readLines(from("setup.md"))
stp[startsWith(stp, "{::options")] <- ""
stp[startsWith(stp, "3.")] <- paste0("\n", stp[startsWith(stp, "3.")])
html_like <- function(x) startsWith(x, "<") | (endsWith(x, ">") & !startsWith(x, ">"))
htmls <- which(html_like(stp))
arts <- htmls[startsWith(stp[htmls], "<article")]
closers <- htmls[startsWith(stp[htmls], "</article")]
osnames <- stp[arts] |> 
  paste(collapse = "\n") |>
  xml2::read_html() |>
  xml2::xml_find_all(".//@id") |>
  xml2::xml_text() |>
  purrr::map_chr(function(x) switch(x, 
      "anaconda-windows" = "Windows {#anaconda-windows}", 
      "anaconda-macos" = "MacOS {#anaconda-macos}", 
      "anaconda-linux" = "Linux {#anaconda-linux}"))
stp[arts] <- glue::glue(":::::::::::: solution\n\n### {osnames}\n\n")
stp[closers] <- "\n::::::::::::"
stp <- stp[-htmls[c(1:7, 25:26)]]
conda <- which(stp == "## Installing Anaconda")
stp[conda - 1L] <- ":::::::::::::::::::: discussion\n\n"
stp[conda + 1L] <- "\n\nSelect your operating system from the options below.\n\n:::::::::::::::::::::::::::::::::"
stp <- sub("raw.githubusercontent.com/datacarpentry/python-ecology-lesson/gh-pages", "../episodes/files/environment.yml", stp)
stp[startsWith(stp, "[Introduction to")] <- "[Introduction to Jupyter Notebooks](jupyter_notebooks.md) page."
tmp <- withr::local_tempdir()
writeLines(stp, path(tmp, "setup.md"))

rewrite(path(tmp, "setup.md"), to("learners"))

fs::dir_create(to("episodes/files/"))
fs::file_move(to("environment.yml"), to("episodes/files/"))
fs::file_move(to("instructors/jupyter_notebooks.md"), to("learners/"))

copy_dir(from("_includes/scripts"), to("episodes/files/scripts"))
ino <- pegboard::Episode$new(to("instructors/instructor-notes.md"))
dst <- xml2::xml_attr(ino$links, "destination")
ndst <- sub("gh-pages/sample", "main/sample", dst, fixed = TRUE)
ndst <- sub("https://github.com/datacarpentry/python-ecology-lesson/tree/gh-pages/_includes/scripts", 
  "../episodes/files/scripts/check_env.py", 
  ndst)
xml2::xml_set_attr(ino$links, "destination", ndst)
xml2::xml_set_text(ino$links[[1]], "episodes/files/scripts/check_env.py")
write_out_md(ino, "instructors")
# re-add links.md ------------------------------------------------
lnks <- readLines(from("_includes/links.md"))
lnks <- sub("http:", "https:", lnks, fixed = TRUE)
lnks <- lnks[!grepl("{", lnks, fixed = TRUE)]
lnks <- c(lnks, "[lesson-setup]: ../learners/setup.md")
writeLines(lnks, to("links.md"))

