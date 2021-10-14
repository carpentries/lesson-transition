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
