l <- pegboard::Lesson$new(new, jekyll = FALSE)

# update links that are pointing to the old material
links <- l$validate_links()
have_this_url <- grep("carpentries.github.io/instructor-training/", links$orig)
selfies <- links[have_this_url, , drop = FALSE]
become_self_aware <- function(node) {
  dst <- xml2::url_parse(xml2::xml_attr(node, "destination"))$path
  if (fs::path_file(dst) == "index.html") {
    dst <- fs::path_dir(dst)
  }
  dst <- fs::path_ext_set(dst, "md")
  dst <- sub("[/]?instructor-training/", "", dst)
  xml2::xml_set_attr(node, "destination", dst)
}
write_out <- function(path) {
  ep <- fs::path_file(path)
  out <- fs::path(new, "episodes")
  type <- fs::path_ext(ep)
  l$episodes[[ep]]$write(path = out, format = type)
}
purrr::walk(selfies$node, become_self_aware)
purrr::walk(selfies$filepath, write_out)

idx <- pegboard::Episode$new(fs::path(new, "index.md"))
idx$confirm_sandpaper()
ilinks <- idx$validate_links()
iselfies <- ilinks[grep("carpentries.github.io/instructor-training/", ilinks$orig), , drop = FALSE]
purrr::walk(iselfies$node, become_self_aware)
idx$write(new, format = "md")

# modify break episodes
cli::cli_alert("modifying breaks episodes")
breaks <- purrr::keep(l$episodes, ~length(xml2::xml_children(.x$body)) == 0)
break_message <- "Take a break. If you can, move around and look at something away from your screen to give your eyes a rest.\n"
purrr::walk(breaks, ~write_out(.x$add_md(break_message)$path))

cli::cli_alert("arranging extras")
# move over extras into learners and instructors
oextra <- function(x) fs::path(new, "_extras", x)
instr <- fs::path(new, "instructors")
learn <- fs::path(new, "learners")
rewrite(oextra("checkout.md"), learn)
rewrite(oextra("demo_lessons.md"), learn)
rewrite(oextra("demos_rubric.md"), learn)
fs::file_move(oextra("glossary.md"), fs::path(learn, "reference.md"))
rewrite(oextra("members.md"), learn)
rewrite(oextra("training_calendar.md"), learn)
rewrite(oextra("fromthelearners.md"), learn)
set_learners(new, c("training_calendar.md", "checkout.md", "demo_lessons.md", "demos_rubric.md", "members.md", "fromthelearners.md", "reference.md"), write = TRUE)

rewrite(oextra("registration_confirmation.md"), instr)
fs::file_move(oextra("etherpad.md"), instr)
rewrite(oextra("additional_exercises.md"), instr)
rewrite(oextra("icebreakers.md"), instr)
set_instructors(new, c("icebreakers.md", "additional_exercises.md", "etherpad.md", "registration_confirmation.md"), write = TRUE)
