#!/usr/bin/env Rscript
r'{Convert a repository to The Workbench

This will destructively convert a repository to use The Carpentries Workbench by
renaming branches and 

ASSUMPTIONS: using this script assumes that you have previously converted a
lesson snapshot to use The Carpentries Workbench and that you have access rights
to the github organisation in which you want to publish.

Usage: 
  final-transition.R <in> <out>
  final-transition.R -h | --help
  final-transition.R -v | --version

-h, --help      Show this information and exit
-v, --version   Print the version information of this script
-q, --quiet     Do not print any progress messages
<in>            Name of a repository to convert to The Workbench
<out>           A JSON file to write the GitHub log to
}' -> doc
library("fs")
library("gh")
library("sandpaper")
library("docopt")
library("gert")
source("functions.R")
`%||%` <- function(a, b) if (length(a) < 1L) b else a
arguments <- docopt(doc, version = "Stunning Barnacle 2023-02", help = TRUE)
repo  <- arguments[["in"]]
new   <- paste0("release/", repo)
fs::dir_create(fs::path_dir(new))
logfile <- path_ext_set(new, "json")
commitfile <- path_ext_set(new, "hash")
invalidfile <- sub("\\.hash", "-invalid.hash", commitfile)
remote_exists <- file_exists(paste0(new, "-status.json"))
org_repo <- strsplit(repo, "/")[[1]]
url   <- paste0("https://", org_repo[1], ".github.io/", org_repo[2])
orig_branch <- gert::git_branch(repo = repo)


if (dir_exists(new)) {
  # if we've already done this, then we just exit
  message("Repository exists; exiting")
  fs::file_touch(logfile)
  quit(save = "no")
} else if (remote_exists) {
  # The remote exists, so we clone and exit
  message("Repository exists on GitHub; cloning and exiting")
  pbsrc   <- paste0("https://github.com/", org_repo[1], "/", org_repo[2])
  gert::git_clone(pbsrc, path = new, verbose = TRUE)
  fs::file_touch(logfile)
  quit(save = "no")
} else {
  # Nothing exists, so we build and move forward.
  message("No repository exists.")
  gfr <- path_abs("git-filter-repo")
  old  <- fs::path(".git", "modules", repo)
  hash <- withr::with_dir(old, {
    callr::run("pwd")
    callr::run("git", c("rev-parse", "HEAD"), echo = TRUE, echo_cmd = TRUE)$stdout
  })
  writeLines(hash, commitfile)
  origin <- paste0("https://github.com/", repo, ".git")
  cmd <- c(#"-x", 
    "filter-and-transform.sh", 
    logfile,
    path_ext_set(repo, "R"),
    fs::path_abs("filter-list.txt"), # include the file filters
    "return message\n"               # do _NOT_ edit commit messages
  )
  callr::run("bash", cmd, echo_cmd = TRUE, echo = TRUE,
    env = c("current", PATH = paste0(gfr, ":", Sys.getenv("PATH")))
  )
  cli::cli_alert_info("Copying filter output")
  for (f in c("commit-map", "ref-map", "suboptimal-issues")) {
    fs::file_copy(
      path(new, ".git", "filter-repo", f),
      paste0(sub("[/]?$", paste0("-", f, ".hash"), new))
    )
  }
  # pluck out a commit to exclude
  conversions <- read.table(path(new, ".git", "filter-repo", "commit-map"), 
    header = TRUE)
  suppressWarnings(excluded <- as.integer(conversions[["new"]]) %in% 0)
  bad_hashes <- conversions[["old"]][excluded]
  if (length(bad_hashes)) {
    cli::cli_alert_info("recording {substr(bad_hashes[1], 1, 7)} to {.file {invalidfile}}")
    writeLines(bad_hashes[1], invalidfile)
  }
}

cli::cli_alert_info("removing workbench beta phase yaml (inserted by template)")
fs::file_delete(fs::path(new, ".github", "workflows", "workbench-beta-phase.yml"))
set_config(c(
  "source" = paste0("https://github.com/", repo),
  "url" = url
  ), 
  path = new,
  write = TRUE,
  create = TRUE
)
cfg <- readLines(fs::path(new, "config.yaml"))
cfg <- cfg[!grepl("^workbench-beta", cfg)]
writeLines(cfg, fs::path(new, "config.yaml"))

chchchchanges <- git_add(".", repo = new)
withr::with_dir(new, {
  callr::run("git", c("commit", "-m", "[automation] final workbench updates"))
})

refs <- gert::git_remote_ls(repo = old)
gert::git_remote_set_url(origin, remote = "origin", repo = new)
prepare_for_execution <- function(cmd) {
  cli::cli_alert("preparing to run {.code {cmd}} in")
  for (step in 5:1) {
    Sys.sleep(1)
    cli::cli_alert("{step}...")
  }
}
cmd <- glue::glue("setup_github(path = '{new}', owner = '{org_repo[1]}', repo = '{org_repo[2]}')")
prepare_for_execution(cmd)

tkn <- Sys.getenv("RELEASE_PAT", unset = "")
tkn <- if (tkn == "") NULL else tkn
setup_github(path = new, owner = org_repo[1], repo = org_repo[2], .token = tkn)
