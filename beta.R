#!/usr/bin/env Rscript
r'{Convert a repository to the beta stage of the Workbench Beta Phase

This will destructively convert a repository to use The Carpentries Workbench by
renaming branches and 

ASSUMPTIONS: using this script assumes that you have previously converted a
lesson snapshot to use The Carpentries Workbench and that you have access rights
to the github organisation in which you want to publish.

Usage: 
  beta.R <in> <out> <dates>
  beta.R -h | --help
  beta.R -v | --version

-h, --help      Show this information and exit
-v, --version   Print the version information of this script
-q, --quiet     Do not print any progress messages
<in>            Name of a repository to convert to pre-beta phase
<out>           A JSON file to write the GitHub log to
<dates>         A CSV file that has three columns, prebeta, beta, and prerelease
                containing dates of each of these phases with a repo column for
                looking up the dates from the repo key.
}' -> doc
library("fs")
library("sandpaper")
library("docopt")
library("gert")

arguments <- docopt(doc, version = "Stunning Barnacle 2022-10", help = TRUE)
dates <- read.csv(arguments$dates)
repo  <- arguments[["in"]]
new   <- paste0("beta/", repo)
logfile <- path_ext_set(new, "json")
commitfile <- path_ext_set(new, "hash")
invalidfile <- sub("\\.hash", "-invalid.hash", commitfile)
remote_exists <- file_exists(paste0(new, "-status.json"))
org_repo <- strsplit(repo, "/")[[1]]
url   <- paste0("https://", org_repo[1], ".github.io/", org_repo[2])
orig_branch <- gert::git_branch(repo = repo)


if (dir_exists(new)) {
  # if we've already done this, then we just exit
  message("Beta repository exists; exiting")
  fs::file_touch(logfile)
  quit(save = "no")
} else if (remote_exists) {
  # The remote exists, so we clone and exit
  message("Beta repository exists on GitHub; cloning and exiting")
  pbsrc   <- paste0("https://github.com/", org_repo[1], "/", org_repo[2])
  gert::git_clone(pbsrc, path = new, verbose = TRUE)
  fs::file_touch(logfile)
  quit(save = "no")
} else {
  # Nothing exists, so we build and move forward.
  message("No repository exists.")
  gfr <- path_abs("git-filter-repo")
  hash <- callr::run("git", c("rev-parse", paste0("HEAD:", repo)))$stdout
  writeLines(hash, commitfile)
  origin <- paste0("https://github.com/", repo, ".git")
  cmd <- c("filter-and-transform.sh", 
    logfile,
    path_ext_set(repo, "R"),
    fs::path_abs("filter-list.txt"), # include the file filters
    '"return message"'               # do _NOT_ edit commit messages
  )
  withr::with_dir(new, callr::run("git", c("remote", "set-url", origin)))
  gert::git_fetch(origin, refspec = "gh-pages:legacy", repo = new)
  callr::run("bash", cmd, echo_cmd = TRUE, echo = TRUE,
    env = c("current", PATH = paste0(gfr, ":", Sys.getenv("PATH")))
  )
  # pluck out a commit to exclude
  conversions <- read.table(path(new, ".git", "filter-repo", "commit-map"), 
    header = TRUE)
  suppressWarnings(excluded <- as.integer(conversions[["new"]]) %in% 0)
  bad_hashes <- conversions[["old"]][excluded]
  if (length(bad_hashes)) {
    writeLines(bad_hashes[1], invalidfile)
  }
}
this_lesson <- dates$repository == repo
set_config(c(
  "beta-date" = dates$beta[this_lesson],
  "old-url" = url
  ), 
  path = new,
  write = TRUE,
  create = TRUE
)

chchchchanges <- git_add(".", repo = new)
withr::with_dir(new, {
  callr::run("git", c("commit", "-m", "[automation] set beta stage of workbench"))
})

if (remote_exists) {
  git_push(repo = new)
} else {
  message("Beta repository created. Now upload it to GitHub")
}
