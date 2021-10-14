# Transitioning Carpentries Lessons

This repository will contain scripts for transitioning Carpentries lessons built
from [the all-in-one infrastructure](https://github.com/carpentries/styles) (aka 
"The Lesson Template") to [the decoupled/centralised 
infrastructure](https://carpentries.github.io/sandpaper-docs) (aka "The Lesson
Infrastructure"). 

These scripts require a setup with R and access to the internet. It is currently
a work in progress and may evolve in the future.


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
  transform-lesson.R [-qnf] [-s <dir>] -o <dir> <repo> [<script>]

-h, --help                show this information and exit
-v, --version             print the version information of this script
-q, --quiet               do not print any progress messages
-n, --dry-run             perform the translation, but do not create the output directory
-f, --fix-liquid          fix liquid tags that may not be processed normally
-s <dir>, --save=<dir>    the directory to save the repository for later use,
                          defaults to a temporary directory
-o <dir>, --output=<dir>  the output directory for the new sandpaper repository
<repo>                    the GitHub repository that contains the lesson. E.g.
                          carpentries/lesson-example
<script>                  additional script to run after the transformation.
                          Important variables to use will be `old` = path to the
                          lesson we just downloaded and `new` = path to the new
                          sandpaper lesson. 
```
