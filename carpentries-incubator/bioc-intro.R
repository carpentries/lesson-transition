# Available variables
#
# old        - path to the old lesson
# from()     - function that constructs a path to the old lesson
# new        - path to the new lesson
# to()       - function that constructs a path to the new lesson
# old_lesson - a pegboard::Lesson object containing the transformed files from
#              the old lesson

# Episode 6, visualisation includes a setup chunk after the first setup chunk,
# so we need to remove that one.
vis <- old_lesson$episodes[[6]]
code <- vis$code
xml2::xml_remove(code[grepl("chunk-options.R", xml2::xml_text(code))])
vis$write(to("episodes"), format = "Rmd")

