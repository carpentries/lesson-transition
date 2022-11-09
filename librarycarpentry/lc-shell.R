# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

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

