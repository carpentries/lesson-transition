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
# old        <- 'swcarpentry/shell-novice'
# new        <- 'sandpaper/swcarpentry/shell-novice'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# transform shell-novice

# Fix episode 3, which has a div for a figure and it's messing up my parser :(
f <- fs::path(new, "episodes", "03-create.md")
ep3 <- readLines(f)
ep3_lines <- startsWith(ep3, "<div") | endsWith(ep3, "div>")
fig <- paste(ep3[ep3_lines], collapse = "")
if (fig != "") {
  img <- xml2::read_html(fig) |> xml2::xml_find_first(".//img")
  img_markdown <- paste0("![", xml2::xml_attr(img, "alt"), "](", 
    sub("../", "", xml2::xml_attr(img, "src")), ")")
  ep3[ep3_lines] <- c(img_markdown, rep("", sum(ep3_lines) - 1L))
}
writeLines(ep3, f)
ep <- Episode$new(f, fix_liquid = TRUE)
transform(ep, new)

# fix rerference definition list styling -------------------------------------
dl_auto_id(to("learners/reference.md"))

# fix dang HTML --------------------------------------------------------------
stp <- readLines(from("setup.md"))
stp[startsWith(stp, "{::options")] <- ""
stp[startsWith(stp, "3.")] <- paste0("\n", stp[startsWith(stp, "3.")])
html_like <- function(x) startsWith(x, "<") | (endsWith(x, ">") & !startsWith(x, ">"))
htmls <- which(html_like(stp))
hopen <- htmls[stp[htmls + 1L] != "" & !html_like(stp[htmls + 1L])]
hclose <- htmls[stp[htmls - 1L] != "" & !html_like(stp[htmls - 1L])]
osnames <- stp[hopen] |> 
  paste(collapse = "\n") |>
  xml2::read_html() |>
  xml2::xml_find_all(".//@id") |>
  xml2::xml_text() |>
  purrr::map_chr(function(x) switch(x, windows = "Windows {#windows}", macos = "MacOS {#macos}", linux = "Linux {#linux}"))
stp[hopen] <- glue::glue(":::::::::::: solution\n\n### {osnames}\n\n")
stp[hclose] <- "\n::::::::::::"
stp <- stp[-setdiff(htmls, c(hopen, hclose))]
tmp <- withr::local_tempdir()
writeLines(stp, path(tmp, "setup.md"))

rewrite(path(tmp, "setup.md"), to("learners"))
