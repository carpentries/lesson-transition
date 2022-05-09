# script to transform r-socialsci
# This lesson assumes that the learner has set up an RStudio project and is using it
# in the context where they have a script called `script.R` at the top of their
# project and all the data is in data/. 
#
# Sandpaper does something weird where it's assuming that `site/` is the root
# (instead of site/built), so placing a .here sentinel works. 
# sets download_data.R to live in the data folder
fs::file_copy(to("bin/download_data.R"), to("episodes/data/download_data.R"))
# gives a sentinel file for episodes to give an anchor for the build
fs::file_touch(to("episodes/.here"))
rewrite(to("_extras", "data-visualisation-handout.Rmd"), to("learners"))
rewrite(to("_extras", "data-wrangling-handout.Rmd"), to("learners"))
rewrite(to("_extras", "intro-R-handout.Rmd"), to("learners"))
rewrite(to("_extras", "starting-with-data-handout.Rmd"), to("learners"))

sandpaper::set_learners(new, 
  c("reference.md",
    "intro-R-handout.Rmd",
    "starting-with-data-handout.Rmd",
    "data-wrangling-handout.Rmd",
    "data-visualisation-handout.Rmd"), 
  write = TRUE)

# We don't like to store things outside of their context, so we moved bin to
# the episodes directory and are now sourcing it relative to there.
fix_setup <- function(ep) {
  src <- ep$code[[1]]
  if (!identical(xml2::xml_attr(src, "include"), "FALSE")) {
    return(ep)
  }
  xml2::xml_set_attr(src, "name", "setup")
  txt <- xml2::xml_text(src)
  xml2::xml_set_text(src, sub("../bin", "data", txt, fixed = TRUE))
}

protect_example <- function(node) {
  txt <- xml2::xml_text(node)
  if (grepl("`r", txt)) {
    txt <- gsub("`(?!r)", "\"`` ```", txt, perl = TRUE)
    txt <- gsub("`r", "``` ``r \"r", txt)
  }
  xml2::xml_set_attr(node, "asis", "true")
  xml2::xml_set_text(node, txt)
}

protect_examples <- function(ep) {
  ex <- xml2::xml_find_all(ep$body, 
    ".//md:text[contains(text(), '`')]",
    ep$ns)
  purrr::walk(ex, protect_example)
}
convert_blocks <- function(episode) {
  blocks <- episode$get_blocks()
  xml_set_attr(blocks, attr = "ktag", "{: .callout}")
  # hack to force unblock to perform its work
  episode$.__enclos_env__$private$mutations["unblock"] <- FALSE
  episode$unblock()
}

sql <- pegboard::Episode$new(to("episodes/.ignore-05-databases.Rmd"))
convert_blocks(sql)
sql$confirm_sandpaper()
sql$write(to("episodes"), format = "Rmd")

l <- Lesson$new(new, jekyll = FALSE)
purrr::walk(l$episodes, fix_setup)
convert_blocks(l$episodes[["04-ggplot2.Rmd"]])
protect_examples(l$episodes[["05-rmarkdown.Rmd"]])


purrr::walk(l$episodes, ~.x$write(to("episodes"), format = "Rmd"))

# Making sure we have the historic site available to us
gert::git_fetch("https://github.com/datacarpentry/r-socialsci.git", refspec = "gh-pages:legacy", repo = new)
