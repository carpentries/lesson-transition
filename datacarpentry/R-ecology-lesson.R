# Convert DataCarpentry R-ecology lesson to use the {sandpaper} infrastructure
# ============================================================================
#
# author: Zhian N. Kamvar
# date: 2021-09-15
#
# This script will do _most_ of the work to convert this lesson into something
# that can be deployed immediately. There are a couple of quirks that need to
# be fixed to get things working smoothly that I don't know yet if I want to fix
# programmatically:
#  - The note on episode 2 will need the heading increased or the <aside> tags
#    will not work :(
#
# TODO: write code handout extractor
# see https://github.com/ropensci/tinkr/pull/52 for details on how to do this

library("sandpaper")
# NOTE: this version of pegboard needs this PR from tinkr: 
#  https://github.com/ropensci/tinkr/pull/54 
library("pegboard")
library("purrr")
library("dplyr")
library("xml2")
library("gert")
library("fs")

repo_path <- "../R-ecology-lesson"

eps <- dir_ls(".", regexp = "^0.+?Rmd$")
names(eps) <- eps
eps <- map(eps, Episode$new)

# This lesson uses block quotes differently than other lessons... it does not 
# have specific labels, but instead labels the block quotes with headings and
# treats them all the same.
#
# Because our converter relied on the presence of a kramdown postfix tag, which
# we converted to an attribute, we can read the headings and convert them to
# xml attributes so we can use our converter (unblock) to convert them into 
# pandoc fenced divs.
convert_blocks <- function(episode) {
  blocks <- episode$get_blocks()
  block_types <- map_chr(blocks, 
    ~xml_text(xml_find_first(.x, ".//md:heading", episode$ns))
  )
  ktags <- case_when(
    grepl("^Challenge", block_types)           ~ "{: .challenge}",
    grepl("^Learning Objectives", block_types) ~ "{: .objectives}",
    is.na(block_types)                         ~ "{: .blockquote}",
    TRUE                                       ~ "{: .callout}"
  )
  xml_set_attr(blocks, attr = "ktag", ktags)
  episode$unblock()$use_sandpaper()
}


# Convert answer code chunks to solutions 
find_answers <- function(episode) {
  lines <- xml_attr(xml_children(episode$body), "sourcepos")
  ep <- episode$code
  answers <- keep(ep, ~!is.na(xml_attr(.x, "answer")))
  which(lines %in% xml_attr(answers, "sourcepos"))
}

# add pandoc fenced-div tags to surround our answers
wrap_solutions <- function(episode) {
  answers <- find_answers(episode)
  n <- 0L
  for (a in answers) {
    episode$add_md(":::::::::::::::::", where = a + n)
    episode$add_md(":::::::: solution", where = a + n - 1L)
    n <- n + 2L
  }
  episode$label_divs()
}

# fix knitr graphics that use img/ 
fix_images <- function(episode, from = "img/", to = "fig/") {
  blocks <- xml_find_all(episode$body, 
    ".//md:code_block[contains(text(), 'knitr::include_graphics')]",
    ns = episode$ns
  )
  if (length(blocks)) {
    txt <- xml_text(blocks)
    xml_set_text(blocks, sub(from, to, txt))
  }
  images <- episode$images
  if (length(images)) {
    dest <- xml_attr(images, "destination")
    xml_set_attr(images, "destination", sub("img/", "fig/", dest))
  }
  episode
}
experiment <- "> **ATTENTION** This is an experimental test of the [{sandpaper}](https://carpentries.github.io/sandpaper-docs) lesson infrastructure.
If anything seems off, please contact Zhian Kamvar <zkamvar@carpentries.org>
"
# Convert information in Episodes
walk(eps, convert_blocks)
walk(eps, wrap_solutions)
walk(eps, fix_images)

# Fix an error in episode 5 where there is a stray `>` at the end of the code
# block.
cb <- eps[[6]]$code
extra_alligator <- cb[xml_attr(cb, "name") == "left_join_answer"]
ea_txt <- xml_text(extra_alligator)
invisible(xml_set_text(extra_alligator, sub("\\n[>]\\n$", "\n", ea_txt)))

# Modify the index to include our magic header
idx <- Episode$new("index.Rmd")
idx$add_md(experiment, 0L)
idx$yaml[length(idx$yaml) + 0:1] <- c("site: sandpaper::sandpaper_site", "---")
idx$label_divs() # fee our image from it's HTML prison
invisible(fix_images(idx))

# add notice in README
rdm <- Episode$new("README.md")
rdm$add_md(experiment, 0L)

# Create lesson
lsn <- tempfile()
create_lesson(lsn, open = FALSE)
file_delete(path(lsn, "episodes", "01-introduction.Rmd"))
file_delete(path(lsn, "index.md"))

# write episodes, index, and readme
walk(eps, ~.x$write(path = path(lsn, "episodes"), format = "Rmd"))
set_episodes(lsn, order = names(eps), write = TRUE)
idx$write(path = path(lsn), format = "Rmd")
rdm$write(path = path(lsn), format = "md")

# hack: copy the included file in both places
file_copy("_page_built_on.Rmd", path(lsn, "episodes"))
file_copy("_page_built_on.Rmd", lsn)

# copy setup.R script and make modifications to avoid our folder preferences
SEQ <- function(a) a[1]:a[2]
setup <- readLines("setup.R")
answers <- grep("^(knitr::knit_hook|\\}\\))", setup)
setup[SEQ(answers)] <- paste("#", setup[SEQ(answers)])
setup <- sub("fig.path", "# fig.path", setup, fixed = TRUE)
writeLines(setup, path(lsn, "episodes", "setup.R"))


# copy learner reference
ref <- Episode$new("reference.md")
ref$yaml <- c("---", "title: Learners' Reference", "---")
ref$write(path(lsn, "learners"), format = "md")
set_learners(lsn, order = "reference.md", write = TRUE)

# copy instructor notes
file_copy("instructor-notes.md", path(lsn, "instructors"), overwrite = TRUE)
set_instructors(lsn, order = "instructor-notes.md", write = TRUE)

# copy AUTHORS file
file_copy("AUTHORS", lsn)

# ignore the index.Rmd (which contains the sandpaper::sandpaper_site)
writeLines("index.Rmd", path(lsn, ".renvignore"))

# copy over images
dir_delete(path(lsn, "episodes", "fig"))
dir_copy("img", path(lsn, "episodes", "fig"))

# Fix config items
set_config <- function(key, value, path = lsn) {
  cfg <- sandpaper:::path_config(path)
  l <- readLines(cfg)
  what <- grep(glue::glue("^{key}:"), l)
  l[what] <- glue::glue("{key}: {shQuote(value)}")
  writeLines(l, cfg)
}
set_config("carpentry", "dc")
set_config("title", "Data Analysis and Visualisation in R for Ecologists")
set_config("life_cycle", "stable")
set_config("source", "https://github.com/data-lessons/R-ecology-lesson")

# delete detritus
detritus <- dir_ls(path(lsn, "episodes", "fig"), regexp = "R-ecology-*")
file_delete(detritus)

# move over temporary lesson
dir_copy(lsn, repo_path)
git_add(".", repo = repo_path)
git_commit("migrate DC R-ecology", repo = repo_path)
manage_deps(path = repo_path)
git_add(".", repo = repo_path)
git_commit("update dependencies", repo = repo_path)
