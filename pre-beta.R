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
<in>            A repository to upload
<out>           A JSON file to write the GitHub log to
<dates>         A CSV file that has three columns, prebeta, beta, and prerelease
                containing dates of each of these phases with a repo column for
                looking up the dates from the repo key.
}' -> doc
library("fs")
library("docopt")

arguments <- docopt(doc, version = "Stunning Barnacle 2022-10", help = TRUE)
print("Nothing to do")
