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
# old        <- 'swcarpentry/python-novice-inflammation'
# new        <- 'sandpaper/swcarpentry/python-novice-inflammation'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)


# Renamed files ------------------------------------------------
# episodes/11-debugging.md:93 [missing file] 01-numpy.html
# episodes/12-cmdline.md:707 [missing file] 04-files.html
links <- old_lesson$get("links")
ep11 <- links[["11-debugging.md"]]
dst <- xml2::xml_attr(ep11, "destination")
to_fix <- dst =="01-numpy"
xml2::xml_set_attr(ep11[to_fix], "destination", "02-numpy.html")
write_out_md(old_lesson$episodes[["11-debugging.md"]])

ep12 <- links[["12-cmdline.md"]]
dst <- xml2::xml_attr(ep12, "destination")
to_fix <- dst =="04-files"
xml2::xml_set_attr(ep12[to_fix], "destination", "06-files.html")
write_out_md(old_lesson$episodes[["12-cmdline.md"]])

inote <- pegboard::Episode$new(to("instructors/instructor-notes.md"))
to_fix <- xml2::xml_attr(inote$links, "destination") == "01-numpy"
xml2::xml_set_attr(inote$links[to_fix], "destination", "02-numpy.html")
write_out_md(inote, "instructors")

# add definition list links back into reference -----------------
ref_lines <- readLines(to("learners/reference.md"))
defs <- which(startsWith(ref_lines, ":")) - 1L
# get identifiers from pandoc
headings <- pandoc::pandoc_convert(text = paste("#", ref_lines[defs]), to = "html")
ids <- paste(headings, collapse = "\n")
ids <- xml2::xml_text(xml2::xml_find_all(xml2::read_html(ids), ".//h1/@id"))
ref_lines[defs] <- sprintf("[%s]{#%s}", ref_lines[defs], ids)
writeLines(ref_lines, to("learners/reference.md"))

# fix bum quotation
numpy <- readLines(to("episodes/02-numpy.md"))
numpy <- sub('[\\]{2}["]data[\\]{2}["]', "'data'", numpy)
writeLines(numpy, to("episodes/02-numpy.md"))

# fix wonky setup fields
stp <- pegboard::Episode$new(to("learners/setup.md"))$confirm_sandpaper()
cols <- paste(rep(":", 40), collapse = "")
open <- paste(cols, '{.empty-div style="margin-bottom: 50px"}')
empty_div <- c(open, "<!-- This div is intentionally empty to allow the solution to float alone-->", cols, "\n")
find_node_position <- function(node, body) {
  children <- xml2::xml_children(body)
  which(purrr::map_lgl(children, identical, node))
}
solutions <- stp$get_divs() |> 
  purrr::map(1) |>
  purrr::map_int(find_node_position, stp$body)
positions <- solutions + (1L:length(solutions) - 1L) * 3
purrr::walk(positions, function(i) stp$add_md(empty_div, where = i - 1L))
write_out_md(stp, "learners")


# fix index 
idx <- sub("fig/lesson-overview.svg", "episodes/fig/lesson-overview.svg", readLines(to("index.md")))
writeLines(idx, to("index.md"))

