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
# old        <- 'datacarpentry/genomics-r-intro'
# new        <- 'sandpaper/datacarpentry/genomics-r-intro'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# Episode 07 has a problem with the translation because they used the HTML code
# for the backtic, but commonmark "helpfully" translated it back to a backtic.
#
# Instead, what we can do here is to wrap it in sets of backtics because knitr
# will check for `r code` and replace that with the output of the code, which
# means that ``r code`` will become `code`. 
#
# markdown allows displaying backtics inside code as long as the number of 
# backtics are fewer than the number of backtics to define the code element so
# ``` `code` ``` becomes <code>`code`</code> in the HTML.
f <- fs::path(new, "episodes", "07-knitr-markdown.Rmd")
k <- readLines(f)
k <- sub(
  '<code>\\`r round(some\\_value, 2)\\`</code>',
  '``` ``r "r round(some_value, 2)"`` ```',
  k, fixed = TRUE)
writeLines(k, f)

codes <- old_lesson$get("code") 

to_fix <- purrr::map(codes, function(x) grepl("../data", xml2::xml_text(x), fixed = TRUE))

purrr::walk2(codes, to_fix, function(blocks, fix) {
  if (any(fix)) {
    for (block in blocks[fix]) {
      txt <- xml2::xml_text(block)
      xml2::xml_set_text(block, gsub("../data/", "data/", txt))
    }
  }
  return(blocks)
})

to_write <- purrr::map_lgl(to_fix, any)
purrr::walk(old_lesson$episodes[to_write], write_out_rmd)

