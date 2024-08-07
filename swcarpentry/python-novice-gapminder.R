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
# old        <- 'swcarpentry/python-novice-gapminder'
# new        <- 'sandpaper/swcarpentry/python-novice-gapminder'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# fix broken link in Episode 2 -----------------------------------
e2 <- old_lesson$episodes[["02-variables.md"]]
lnks <- e2$validate_links(warn = FALSE)
to_fix <- lnks$node[[which(!lnks$internal_file)]]
dst <- xml2::xml_attr(to_fix, "destination")
xml2::xml_set_attr(to_fix, "destination", 
  sub("15-scope", "17-scope.md", dst, fixed = TRUE))
write_out_md(e2)

# fix path to zip ------------------------------------------------
idx <- pegboard::Episode$new(to("index.md"))$confirm_sandpaper()
lnks <- idx$validate_links(warn = FALSE)
to_fix <- lnks$node[[which(!lnks$internal_file)]]
dst <- xml2::xml_attr(to_fix, "destination")
xml2::xml_set_attr(to_fix, "destination", paste0("episodes/", dst))
# remove liquid declaration {% include gh_variables %}
spill <- xml2::xml_find_first(idx$body,
  ".//md:paragraph[md:text[starts-with(text(), '{')]]",
  ns = idx$ns
)
xml2::xml_remove(spill)
write_out_md(idx, ".")

# re-add links.md ------------------------------------------------
lnks <- readLines(from("_includes/links.md"))
lnks <- sub("http:", "https:", lnks, fixed = TRUE)
lnks <- lnks[!grepl("{", lnks, fixed = TRUE)]
writeLines(lnks, to("links.md"))

# fix setup instructions -----------------------------------------
stp <- readLines(to("learners/setup.md"))
stp[stp == "<br>"] <- ""
stp[startsWith(stp, "{%")] <- "Please refer to the [Python section of the workshop website for installation instructions.](https://carpentries.github.io/workshop-template/#python)"
writeLines(stp, to("learners/setup.md"))





