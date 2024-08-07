#!/usr/bin/env bash

FILE=${1:-empty}

if [[ ${FILE} != "empty" && ! -e "${FILE}.R" ]]; then

  echo '# Available variables' >> "${FILE}.R"
  echo '#' >> "${FILE}.R"
  echo '# old        - path to the old lesson' >> "${FILE}.R"
  echo '# from()     - function that constructs a path to the old lesson' >> "${FILE}.R"
  echo '# new        - path to the new lesson' >> "${FILE}.R"
  echo '# to()       - function that constructs a path to the new lesson' >> "${FILE}.R"
  echo '# old_lesson - a pegboard::Lesson object containing the transformed files from' >> "${FILE}.R"
  echo '#              the old lesson' >> "${FILE}.R"
  echo '' >> "${FILE}.R"
  echo '# During iteration: use these to provision the variables and functions' >> "${FILE}.R"
  echo '# that would be normally available when this script is run' >> "${FILE}.R"
  echo '#' >> "${FILE}.R"
  echo '# library("fs")' >> "${FILE}.R"
  echo '# library("xml2")' >> "${FILE}.R"
  echo '# pandoc::pandoc_activate("3.1.2")' >> "${FILE}.R"
  echo '# source("functions.R")' >> "${FILE}.R"
  echo "# old        <- '${FILE}'" >> "${FILE}.R"
  echo "# new        <- 'sandpaper/${FILE}'" >> "${FILE}.R"
  echo '# from       <- function(...) fs::path(old, ...)' >> "${FILE}.R"
  echo '# to         <- function(...) fs::path(new, ...)' >> "${FILE}.R"
  echo '# old_lesson <- pegboard::Lesson$new(new, jekyll = FALSE)' >> "${FILE}.R"
  echo '' >> "${FILE}.R"


else

  echo
  echo 'Add a lesson to the transformation process'
  echo '------------------------------------------'
  echo
  echo 'This will create a new file in an _existing_ directory that will direct'
  echo 'the transformation process to create a submodule of the lesson.'
  echo
  echo 'Usage:'
  echo
  echo '  bash add-lesson.sh <ORG>/<LESSON>'
  echo


fi
