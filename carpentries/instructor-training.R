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
cli::cli_alert("fixing link outs to official site")
purrr::walk(selfies$node, become_self_aware)

purrr::walk(selfies$filepath, write_out)

cli::cli_alert("adding instructor notes to How We Operate")

titles <- purrr::map_chr(l$episodes, ~.x$get_yaml()$title)
oper <- l$episodes[[grep("How We Operate", titles)]]
oper_note <- r'{
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: instructor
  
- CK: Not an "official" exercise, but after explaining the workshops and how to run them,
  go around the room, asking each person if they have a question + then answer them.

- Exercise: Creating a Workshop Website
  
  - CK: This takes some time, so some people opt to skip this section.  Inevitably,
    when working with a group of mixed experience with GitHub, some will be able
    to zip through this exercise, where others will struggle.  We **have** gotten
    positive feedback about this exercise as well, where learners felt like it was
    a valuable experience. Can be especially valuable for groups that will probably
    be running workshops on their own (so open trainings, or trainings for folks
    who are ready to get started right away).

- CK: The coffee break after this would be a great time for an "Ask and Offer" if the
  group is interested.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}'
oper$add_md(oper_note, 1)
write_out(oper$path)


idx <- pegboard::Episode$new(fs::path(new, "index.md"))
idx_note <- r'{
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: instructor

### A note about instructor view

The instructor view has a few features that the learner view does not have:

1. instructor notes like this one where instructors can provide guidance about
   how the particular episode is taught in practice **(you can find an example of
   this in the [How We Operate episode](15-carpentries.md))**.
2. aggregated timing estimates
3. a schedule integrated into the index page

You can enter instructor view at any time by selecting the dropdown menu at the
top right of the page or you can edit the URL and place `/instructor/` before
the html page. 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}'
idx$confirm_sandpaper()
idx$add_md(idx_note, 1)
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
