#!/usr/bin/env Rscript
r'{Create comment for a transitioned lesson repository 

Usage: 
  create-success-comment.R [-xqhv] [<repo>] [<issue>]

-h, --help         Show this information and exit
-v, --version      Print the version information of this script
-q, --quiet        Do not print any progress messages
<repo>  Name of a repository to list collaborators for. Defaults to `cp/instructor-training-bonus-modules`
}' -> doc
library("docopt")
source("functions.R")

`%||%` <- function(a, b) if (length(a) < 1L || identical(a, FALSE) || identical(a, "")) b else a
arguments <- docopt(doc, version = "Stunning Barnacle 2022-11", help = TRUE)
arguments$repo <- arguments$repo %||% "cp/instructor-training-bonus-modules"



txt <- "

The Workbench version is now live: https://{org}.github.io/{repo}/

In addition, here is [map of commits that were changed during the transition](https://github.com/carpentries/lesson-transition/blob/release_{arguments$repo}/release/{org}/{repo}-commit-map.hash)

"

org <- switch(strsplit(arguments$repo, "/")[[1]][1], 
  cp = "carpentries",
  lc = "librarycarpentry",
  dc = "datacarpentry",
  swc = "swcarpentry"
)
repo <- strsplit(arguments$repo, "/")[[1]][2]

writeLines(glue::glue(txt))


