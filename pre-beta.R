#!/usr/bin/env Rscript
r'{Enter a repository into the beta phase for The Carpentries Workbench

This will enter a converted lesson into the pre-beta stage of the carpentries
workbench. 

ASSUMPTIONS: using this script assumes that you have previously converted a
lesson snapshot to use The Carpentries Workbench and that you have access rights
to the github organisation in which you want to publish.

Usage: 
  pre-beta.R <in> <out> <dates>
  pre-beta.R -h | --help
  pre-beta.R -v | --version

-h, --help      Show this information and exit
-v, --version   Print the version information of this script
-q, --quiet     Do not print any progress messages
-o, --org       GitHub organisation in which to publish the snapshot. This will
                default to fishtree-attempt
<in>            Name of a repository to convert to pre-beta phase
<out>           A JSON file to write the GitHub log to
<dates>         A CSV file that has three columns, prebeta, beta, and prerelease
                containing dates of each of these phases with a repo column for
                looking up the dates from the repo key.
}' -> doc
library("fs")
library("sandpaper")
library("docopt")

arguments <- docopt(doc, version = "Stunning Barnacle 2022-10", help = TRUE)
dates <- read.csv(arguments$dates)
repo  <- arguments[["in"]]
old   <- paste0("sandpaper/", repo)
new   <- paste0("prebeta/", repo)
org_repo <- strsplit(repo, "/")[[1]]
url   <- paste0("https://", org_repo[1], ".github.io/", org_repo[2])
# moving the repository
if (dir_exists(old)) {
  if (!dir_exists(path_dir(new))) {
    dir_create(path_dir(new), recurse = TRUE)
  }
  file_move(old, new)
}
this_lesson <- dates$repository == repo
set_config(c(
  "pre-beta-date" = dates$pre.beta[this_lesson],
  "old-url" = url
  ), 
  path = new,
  write = TRUE,
  create = TRUE
)

