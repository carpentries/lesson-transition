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
# old        <- 'librarycarpentry/lc-shell'
# new        <- 'sandpaper/librarycarpentry/lc-shell'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)


# Fix setup, which has a bug where there is a missing block quote indentation
f <- fs::path(old, "setup.md")
stp <- readLines(f)
bad <- grep("^~~~", stp)
stp[bad] <- paste0(">", stp[bad])
writeLines(stp, f)
rewrite(f, fs::path(new, "learners"))

# fix episode 4, which had an extra nested block quote
ep4 <- old_lesson$episodes[[4]]
# isolate the bad div
bad_div <- ep4$get_divs(type = "language-bash", include = TRUE)[[1]]
# remove the fences and rewrite
n <- length(bad_div)
xml2::xml_remove(bad_div[c(1, 2, n-1, n)])
ep4$write(fs::path(new, "episodes"), format = "md")

# Reading new lesson to fix old sins -------------------------
new_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)
purrr::walk(new_lesson$get("links"), function(lnks) {
  dst <- xml2::xml_attr(lnks, "destination")
  no <- "https://raw.githubusercontent.com/LibraryCarpentry/lc-shell/gh-pages/"
  dst <- sub(no, "", dst)
  is_lc <- grepl("librarycarpentry.org", dst)
  dst[is_lc] <- sub("[/](index.html)?$", "", dst[is_lc])
  xml2::xml_set_attr(lnks, "destination", dst)
})

# Fix block quote in episode 6 that does not belong ----------
e6 <- new_lesson$episodes[["06-free-text.md"]]
pegboard:::elevate_children(e6$get_blocks()[[1]])

# Fix headings in episode 4 ----------------------------------
e4 <- new_lesson$episodes[["04-loops.md"]]
xml2::xml_set_attr(e4$headings[[1]], "level", 2)
# write out episodes
purrr::walk(new_lesson$episodes, write_out_md)

# Fix links in index -----------------------------------------
idx <- new_lesson$extra$index.md

dst <- xml2::xml_attr(idx$links, "destination")
no <- "https://raw.githubusercontent.com/librarycarpentry/lc-shell/gh-pages/"
dst <- sub(no, "episodes/", dst, ignore.case = TRUE)
xml2::xml_set_attr(idx$links, "destination", dst)
write_out_md(idx)


