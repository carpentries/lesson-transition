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
# old        <- 'carpentries-incubator/good-enough-practices'
# new        <- 'sandpaper/carpentries-incubator/good-enough-practices'
# from       <- function(...) fs::path(old, ...)
# to         <- function(...) fs::path(new, ...)
# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)

# remove the Liquid comment that becomes visible in Workbench lesson
landing_page <- readLines(to("index.md"))
landing_page <- sub('\\{% comment %\\} This is a comment in Liquid \\{% endcomment %\\}', '', landing_page)
writeLines(landing_page, to("index.md"))

# remove double quotes in alt text
## data management episode
dataman <- readLines(to("episodes/02-data_management.md"))
dialogue = c('The four stages of data loss',
             'dealing with accidental deletion of months of hard-earned data',
             'stage 1: denial',
             'I did not just erase all my data. I surely made a back-up somewhere',
             'stage 2: anger',
             'you stupid piece of crap! Where\'s my data\\?!',
             'stage 3: depression',
             'Why\\? Why me\\?',
             'stage 4: acceptance',
             'I\'m never going to graduate')
for (d in dialogue) {
    dataman <- sub(paste0('[\\]{2}["]', d, '[\\]{2}["]'), paste0("'", d, "'"), dataman)
}
writeLines(dataman, to("episodes/02-data_management.md"))
## software episode
software <- readLines(to("episodes/03-software.md"))
q <- 'I\'m conscious that lots of people would like to see and run the pandemic simulation code we are using to model control measures against COVID-19. To explain the background — I wrote the code \\(thousands of lines on undocumented C\\) 13 plus years ago to model flu pandemics…'
software <- sub(paste0('[\\]{2}["]', q, '[\\]{2}["]'), paste0("'", q, "'"), software)
writeLines(software, to("episodes/03-software.md"))

# escape dollar signs to avoid USD amounts being mistaken for LaTeX syntax
track_changes <- readLines(to("episodes/06-track_changes.md"))
track_changes <- gsub('\\$5', '\\\\\\\\$5', track_changes)
writeLines(track_changes, to("episodes/06-track_changes.md"))



