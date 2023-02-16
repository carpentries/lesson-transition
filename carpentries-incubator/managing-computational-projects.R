# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson


# remove empty episode from list
cli::cli_alert_info("Removing {.file 06-ITtools.md} from schedule")
sandpaper::move_episode("06-ITtools.md", 0, path = new, write = TRUE)

cli::cli_alert_info("Fixing broken extras link to {.file 04-FAIRHowTo.md} in {.file 09-rdm.md}")
rdm <- old_lesson$episodes[["09-rdm.md"]]
rdm_links <- rdm$validate_links(warn = FALSE)
bad_extra <- which(startsWith(rdm_links$orig, "_extra/"))
xml2::xml_set_attr(rdm_links$node[[bad_extra]], "destination", 
  "learners/04-FAIRHowTo.md")
rdm$write(path = to("episodes"), format = "md")

# move extras to learners
cli::cli_alert_info("Moving extras to learners")
extras <- sandpaper::get_instructors(new)
extras <- extras[extras != "instructor-notes.md"]
learn  <- sandpaper::get_learners(new)
fs::file_move(fs::path(new, "instructors", extras), fs::path(new, "learners"))
sandpaper::set_learners(new, order = c(learn, extras), write = TRUE)


