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
arguments$repo <- arguments$repo %||% "fishtree-attempt/znk-transition-test"
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
    tkn <- askpass::askpass("Create a temporary token to DELETE existing repository\nPASTE YOUR TOKEN HERE: ")
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
  rp <- setNames(strsplit(arguments$repo, "/")[[1]], c("org", "repo"))
  user_type <- switch(gh("GET /users/{usr}", usr = rp["org"])$type,
    Organization = paste0("orgs/", rp["org"]),
    User = "user"
  )
  gh("POST /{type}/repos", 
    type = user_type, 
    name = fs::path_file(arguments$repo),
    .params = list(homepage = glue::glue("https://{rp['org']}.github.io/{rp['repo']}")))

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

  Sys.sleep(2)
  # set gh-pages as the default branch
  cli::cli_alert_info("Setting gh-pages as default")
  res <- gh("PATCH /repos/{repo}", repo = arguments$repo, 
    .params = list(default_branch = "gh-pages"))
  if (res$default_branch != "gh-pages") {
    stop("the default branch could not be set to gh-pages")
  }
  
  # test a pull request to default branch
  cli::cli_alert_info("Creating a test pull request")
  gh("POST /repos/{repo}/pulls", 
    repo = arguments$repo,
    .params = list(
      head = "change-prereq-box",
      base = "gh-pages",
      title = "test pull request")
  )

  if (startsWith(arguments$repo, "fishtree-attempt")) {
    cli::cli_alert_info("Setting permissions")
    gh("PUT /orgs/{ORG}/teams/{REPO}-maintainers/repos/{ORG}/{REPO}",
      ORG = rp["org"],
      REPO = rp["repo"],
      .params = list(permission = "push"))
    gh("PUT /orgs/{ORG}/teams/bots/repos/{ORG}/{REPO}",
      ORG = rp["org"],
      REPO = rp["repo"],
      .params = list(permission = "push"))
  }

  Sys.sleep(2)
  tmp <- withr::local_tempdir()
  git_clone(glue::glue("https://github.com/{arguments$repo}"), path = tmp)
  run_styles <- withr::local_tempfile()
  download.file("https://github.com/carpentries/actions/raw/main/update-styles/update-styles.sh", run_styles)
  withr::with_dir(tmp, {
    try(callr::run("bash", run_styles, echo = TRUE, echo_cmd = TRUE))
  })
  cfg <- readLines(fs::path(tmp, "_config.yml"))
  lc <- which(startsWith(cfg, "life_cycle"))
  writeLines(c(
    cfg[1:(lc-1)],
    "life_cycle: 'transition-step-2'",
    "transition_date_prebeta: '2022-10-31' # pre-beta stage (two repos, two sites)",
    "transition_date_beta: '2023-02-06' # beta stage (one repo, two sites)",
    "transition_date_prerelease: '2023-04-03' # pre-release stage (one repo, one site)",
    cfg[(lc+1):length(cfg)]
  ), fs::path(tmp, "_config.yml"))
  git_add(".", repo = tmp)
  git_commit("update styles", repo = tmp)
  git_push(repo = tmp)

  
} else {
  stop(paste0("Delete https://github.com/", arguments$repo, " and try again"))
}
