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
# old        <- 'swcarpentry/r-novice-gapminder'
# new        <- 'sandpaper/swcarpentry/r-novice-gapminder'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)
#
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

e$write(path = fs::path(new, "episodes"), format = "Rmd")

# fix anchor links ------------------------------------------
dl_auto_id(to("learners/reference.md"))

# fix raw links ---------------------------------------------
lsn <- pegboard::Lesson$new(new, jekyll = FALSE)
suppressMessages(lnks <- lsn$validate_links())
to_fix <- startsWith(lnks$server, "raw.github")
purrr::walk(lnks$node[to_fix], function(node) {
  target <- xml2::xml_attr(node, "destination")
  new <- sub("https://raw.githubusercontent.com/swcarpentry/r-novice-gapminder/gh-pages/_episodes_rmd/", "", target, fixed = TRUE)
  xml2::xml_set_attr(node, "destination", new)
})

to_write <- unique(lnks$filepath[to_fix])
purrr::walk(to_write, function(ep) {
  folder <- fs::path_dir(ep)
  file   <- fs::path_file(ep)
  cli::cli_alert("writing {ep}")
  if (folder == "episodes") {
    write_out_rmd(lsn$episodes[[file]], folder)
  } else {
    write_out_md(lsn$extra[[file]], folder)
  }
})

