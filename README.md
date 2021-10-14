# Transitioning Carpentries Lessons

This repository will contain scripts for transitioning Carpentries lessons built
from [the all-in-one infrastructure](https://github.com/carpentries/styles) (aka 
"The Lesson Template") to [the decoupled/centralised 
infrastructure](https://carpentries.github.io/sandpaper-docs) (aka "The Lesson
Infrastructure"). 

These scripts require a setup with R and access to the internet. It is currently
a work in progress and may evolve in the future.

## Usage

To add a lesson for translation, there are two steps:

1. add an R script with the repository name under a folder with the organisation
   name (e.g. `swcarpentry/r-novice-gapminder.R` or 
  `datacarpentry/R-ecology-lesson.R`). 
2. run `make`

### Notes

The `transform-lesson.R` script is meant to serve as a generalized method for
converting lesson content from one engine to the other. It does the majority of
the heavy lifting, but it can not completely convert lessons perfectly. Because
each lesson is built in a _slightly_ different way and kramdown (Jekyll's 
markdown parser) allows for patterns that would be invalid in any other parser,
the conversion is not 100%. This additional R script allows you to make
additional changes such as moving files or fixing errors. This file can be blank
if there are no changes you wish to make

If your lesson is in a repository that does not belong to an official carpentries
account, you will need to append the `DIRS` varaible in the makefile.


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
