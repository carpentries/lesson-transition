# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

# old        <- "librarycarpentry/lc-r/"
# new        <- "sandpaper/librarycarpentry/lc-r/"
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)


# Fix Episode 3 discontinuous block quotes --------------------
sandbox <- tempfile()
dir.create(sandbox)

# There is a situation where the authors have placed discontinuous block quotes
# in their lesson for convenience of authoring. It is completely understandable
# because writing `> >` for every solution is a PITA, but it leads to situations
# where commonmark cannot parse it:
#
# > text
# > text
#   more txt
#   more text
# > more text
#
# To commonmark, the above looks like two block quotes.
# This function takes a path to a file, finds these discontinuous block quotes
# (with assumptions of proximity) and fills the gaps, returning a new file
fix_discontinuous_blocks <- function(path, newfile = fs::path(sandbox, fs::path_file(path))) {
  lines <- readLines(path)
  # create a list of block quote runs. 
  block_quotes <- cumsum(startsWith(lines, ">"))
  run_table <- table(block_quotes)
  # gaps will appear as short runs of the same number. We can find these
  # by filtering out all the numbers that occur in greater frequency than
  # one and a smaller frequency than the mean.
  gaps <- run_table[run_table > 1 & run_table < mean(run_table)]
  if (length(gaps) == 0)
    return(invisible())
  gaps <- as.integer(names(gaps))
  for (gap in gaps) {
    # find the lines that belong to this gap
    gap_lines <- which(block_quotes %in% gap)
    # cut the reference line from the top
    ref <- lines[gap_lines][1]
    gap_lines <- gap_lines[-1]
    # find the position of the indent and extract it
    indent <- gregexpr("[^ >]", ref)[[1]][1] - 1L
    ref <- substring(ref, 1L, indent)
    # replace whitespace intents with the reference
    has_indent <- trimws(substring(lines[gap_lines], 1L, indent)) == ""
    substring(lines[gap_lines][has_indent], 1L, indent) <- ref
    if (any(!has_indent)) {
      # append the reference to any lines that do not have the indent
      lines[gap_lines][!has_indent] <- paste0(ref, lines[gap_lines][!has_indent])
    }
  }
  writeLines(lines, newfile)
  newfile 
}
e3 <- old_lesson$episodes[[4]]
# fill the gaps and write a new file
e3tmp <- fix_discontinuous_blocks(e3$path)
# re-load and re-transform that file
old_lesson$episodes[[4]] <- pegboard::Episode$new(e3tmp)
transform(old_lesson$episodes[[4]])

# Fix preamble code ---------------------------------------------
fs::dir_create(to("episodes/files/"))
fs::file_copy(from("bin/download_data.R"), to("episodes/files/download_data.R"))
replace_source <- function(ep) {
  setup <- ep$code[1]
  txt <- sub("../bin/", "files/", xml2::xml_text(setup))
  xml2::xml_set_text(setup, txt)
  write_out_rmd(ep)
}
purrr::walk(old_lesson$episodes, replace_source)

