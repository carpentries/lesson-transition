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
# old        <- 'swcarpentry/r-novice-gapminder-es'
# new        <- 'sandpaper/swcarpentry/r-novice-gapminder-es'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# Episode 15 has a problem with the translation because they used the HTML code
# for the backtic, but commonmark "helpfully" translated it back to a backtic.
#
# Instead, what we can do here is to wrap it in sets of backtics because knitr
# will check for `r code` and replace that with the output of the code, which
# means that ``r code`` will become `code`. 
#
# markdown allows displaying backtics inside code as long as the number of 
# backtics are fewer than the number of backtics to define the code element so
# ``` `code` ``` becomes <code>`code`</code> in the HTML.
f <- fs::path(new, "episodes", "15-knitr-markdown.Rmd")
k <- readLines(f)
k <- sub(
  '<code>\\`r round(some\\_value, 2)\\`</code>',
  '``` ``r "r round(some_value, 2)"`` ```',
  k, fixed = TRUE)
writeLines(k, f)

# Find the position of a node in the XML document
find_position <- function(body, node) {
  lines <- xml2::xml_attr(xml2::xml_children(body), "sourcepos")
  which(lines %in% xml2::xml_attr(node, "sourcepos"))
}
# Episode 13 has a solution block that was not entirely translated, so it needs
# extra processing to remove the block quotes
e <- pegboard::Episode$new(fs::path(new, "episodes", "13-dplyr.Rmd"))
e$confirm_sandpaper()
blocks <- e$get_blocks() # rogue block quotes
# Find the adjacent solution
pos <- pegboard:::get_linestart(blocks[[1]])
solutions <- e$solutions
spos <- purrr::map_int(solutions, ~rev(pegboard:::get_linestart(.x))[1])
the_solution <- solutions[[which.min(pos - spos[spos < pos])]]
the_fence <- the_solution[length(the_solution)]

# remove the block quotes and append a solution
chillins <- purrr::map(blocks, pegboard:::elevate_children)
end_block <- find_position(e$body, chillins[[length(chillins)]])
# remove the code fence
xml2::xml_remove(the_fence)
e$add_md(xml2::xml_text(the_fence), where = end_block)

e$write(path = to("episodes"), format = "Rmd")

# Episode 06 has a stray NA block that used to be output --------------
e6 <- old_lesson$episodes[["06-data-subsetting.Rmd"]]
code <- e6$code
offender <- code[grepl("NA", code, fixed = TRUE)]
xml2::xml_remove(offender)
e6$write(path = to("episodes"), format = "Rmd")

# add definition list links back into reference -----------------
dl_auto_id(to("learners/reference.md"))

# fix instructor notes ------------------------------------------------
inote <- pegboard::Episode$new(to("instructors/instructor-notes.md"))
targets <- xml2::xml_attr(inote$links, "destination")
targets <- sub("https://raw.githubusercontent.com/swcarpentry/r-novice-gapminder/gh-pages/_episodes_rmd/", "", targets, fixed = TRUE)
xml2::xml_set_attr(inote$links, "destination", targets)
write_out_md(inote, "instructors")

sandpaper::set_config(c(lang = "'es'"), path = to(), write = TRUE)
