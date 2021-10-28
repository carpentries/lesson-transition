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
set_config(c("source" = "https://github.com/data-lessons/r-novice-gapminder"), new, write = TRUE)
