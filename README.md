# Transitioning Carpentries Lessons

This repository will contain scripts for transitioning Carpentries lessons built
from [the all-in-one infrastructure](https://github.com/carpentries/styles) (aka 
"The Lesson Template") to [the decoupled/centralised 
infrastructure](https://carpentries.github.io/sandpaper-docs) (aka "The Lesson
Infrastructure"). 

These scripts require a setup with R and access to the internet. It is currently
a work in progress and may evolve in the future.

The makefile controls translations of our lessons, with more to be added.

These are the parameters for the lesson translation scripts:

```
Transform a lesson from styles template to sandpaper infrastructure

This script will download a lesson repository from GitHub, translate it to the
new lesson infrastructure, {sandpaper}, and apply any post-translation scripts
that need to be applied in order to fix any issues that occurred in the
process.

Usage: 
  transform-lesson.R -o <dir> <repo> [<script>]
  transform-lesson.R -h | --help
  transform-lesson.R -v | --version
  transform-lesson.R [-qnfb] [-s <dir>] -o <dir> <repo> [<script>]

-h, --help                Show this information and exit
-v, --version             Print the version information of this script
-q, --quiet               Do not print any progress messages
-n, --dry-run             Perform the translation, but do not create the output
                          directory.
-f, --fix-liquid          Fix liquid tags that may not be processed normally
-b, --build               Build the lesson after translation. This can be useful
                          when writing scripts to see what needs to be fixed.
-s <dir>, --save=<dir>    The directory to save the repository for later use,
                          defaults to a temporary directory
-o <dir>, --output=<dir>  The output directory for the new sandpaper repository
<repo>                    The GitHub repository that contains the lesson. E.g.
                          carpentries/lesson-example
<script>                  Additional script to run after the transformation.
                          Important variables to use will be `old` = path to the
                          lesson we just downloaded and `new` = path to the new
                          sandpaper lesson. `old_lesson` = the Lesson object 

```
