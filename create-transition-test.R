#!/usr/bin/env Rscript
r'{Destroy and recreate a test repository

This is a direct mirror of sgibson91/cross-stitch-carpentry

Usage: 
  create-test.R [repo]
  create-test.R -q [repo]
  create-test.R -h | --help
  create-test.R -v | --version

-h, --help         Show this information and exit
-v, --version      Print the version information of this script
-q, --quiet        Do not print any progress messages
[repo]  Name of a repository to test. Defaults to `zkamvar/transition-test-2`
}' -> doc
library("docopt")
`%||%` <- function(a, b) if (length(a) < 1L || identical(a, FALSE) || identical(a, "")) b else a
arguments <- docopt(doc, version = "Stunning Barnacle 2022-11", help = TRUE)
arguments$repo <- arguments$repo %||% "zkamvar/transition-test-2"
library("fs")
library("gh")
library("cli")
library("gert")
library("withr")
library("askpass")

# If the repository we want to test with exists, then we need to tell us to 
# delete it
no_repo <- tryCatch(gh("GET /repos/{repo}", repo = arguments$repo), 
  github_error = function(e) e)
if (inherits(no_repo, "gh_response")) {
  tkn <- Sys.getenv("DEL_PAT") %||% FALSE
  if (isFALSE(tkn)) {
    browseURL("https://github.com/settings/tokens/new?scopes=delete_repo&description=delete%20transition%2Dtest%2D2")
    tkn <- askpass::askpass("Create a temporary token\nPASTE YOUR TOKEN HERE: ")
  }
  res <- tryCatch(gh("DELETE /repos/{repo}", repo = arguments$repo, .token = tkn), 
    github_error = function(e) e
  )
  rm(tkn)
  (no_repo <- inherits(res, "gh_response"))
  if (!no_repo) {
    print(res)
  }
} else {
  no_repo <- TRUE
}

if (no_repo) {

  # create an empty repository
  cli::cli_alert_info("creating a new repository called {.code {arguments$repo}}")
  gh("POST /user/repos", name = fs::path_file(arguments$repo))

  # clone the test to our temporary directory
  cli::cli_alert_info("importing {.code sgibson91/cross-stitch-carpentry} to {.code {arguments$repo}}")
  cli::cli_status("Cloning a mirror of {.code sgibson91/cross-stitch-carpentry}")
  tmp <- withr::local_tempdir()
  git_clone("https://github.com/sgibson91/cross-stitch-carpentry/",
    path = tmp, mirror = TRUE)

  # set the URL
  cli::cli_status_update("setting the remote URL to {.code {arguments$repo}}")
  git_remote_set_url(paste0("https://github.com/", arguments$repo, ".git"),
    remote = "origin",
    repo = tmp)

  # push it up
  cli::cli_status_update("pushing the mirror to {.code {arguments$repo}}")
  git_push(remote = "origin", mirror = TRUE, repo = tmp)
  withr::defer()
  cli::cli_status_clear()

  # set gh-pages as the default branch
  cli::cli_alert_info("Setting gh-pages as default")
  gh("PATCH /repos/{repo}", repo = arguments$repo, default_branch = "gh-pages") 
  
  # test a pull request to default branch
  cli::cli_alert_info("Creating a test pull request")
  gh("POST /repos/{repo}/pulls", 
    repo = arguments$repo,
    head = "change-prereq-box",
    base = "gh-pages",
    title = "test pull request")
  
} else {
  stop(paste0("Delete https://github.com/", arguments$repo, " and try again"))
}
