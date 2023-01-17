#!/usr/bin/env Rscript
r'{Create a pull request using a dummy account

This assumes that you have registered a token for this account with

library("gitcreds")
gitcreds_approve(list(url = "https://github.com", 
  username = "ravmakz",
  password = askpass::askpass("PASTE GITHUB PAT HERE:\n"))
)

Usage: 
  create-test.R [repo] [user]
  create-test.R -q [repo] [user]
  create-test.R -h | --help
  create-test.R -v | --version

-h, --help         Show this information and exit
-v, --version      Print the version information of this script
-q, --quiet        Do not print any progress messages
[repo]  Name of a repository to test. Defaults to `fishtree-attempt/znk-transition-test`
[user]  Name of user to use. Defaults to ravmakz
}' -> doc
library("docopt")
`%||%` <- function(a, b) if (length(a) < 1L || identical(a, FALSE) || identical(a, "")) b else a
arguments <- docopt(doc, version = "Stunning Barnacle 2022-11", help = TRUE)
arguments$repo <- arguments$repo %||% "fishtree-attempt/znk-transition-test"
arguments$user <- arguments$user %||% "ravmakz"
library("fs")
library("gh")
library("cli")
library("gert")
library("withr")
library("askpass")
source("functions.R")

# get the token for the bot account
cli::cli_h1("Setting up GitHub")
cli::cli_h2("Provisining token")
get_token(username = "ravmakz",
  write = TRUE, 
  scopes = c("delete_repo", "public_repo"))
hub <- setNames(strsplit(arguments$repo, "/")[[1]], c("owner", "repo"))

# remove the existing fork
cli::cli_h2("Provisioning repository")
tryCatch(gh("DELETE /repos/{owner}/{repo}", 
    owner = arguments$user, 
    repo = hub["repo"], 
    .token = get_token()), 
  github_error = function(e) e
)

# recreate the fork
res <- gh::gh("POST /repos/{owner}/{repo}/forks",
  owner = hub["owner"],
  repo  = hub["repo"],
  .params = list(name = hub["repo"], default_branch_only = FALSE),
  .token = get_token()
)
cli::cli_alert_info("New fork: {.url {res$html_url}}")

# download the repository locally and create the branch
cli::cli_h1("Creating Pull Request")
new_branch <- "outdated-pr-test"
cli::cli_h2("creating {.code {new_branch} branch}")
tmp <- withr::local_tempdir(pattern = "git")
gert_url <- sub("github.com", paste0(arguments$user, "@github.com"), res$html_url)
gert_url <- paste0(gert_url, ".git")
gert::git_clone(gert_url, path = tmp, password = get_token())
gert::git_branch_create(new_branch, repo = tmp)
idx <- sub("otivation", "ortivation", readLines(fs::path(tmp, "index.md")))
writeLines(idx, fs::path(tmp, "index.md"))
gert::git_commit_all("replace one letter", repo = tmp, 
  author = gert::git_signature("Kian Zhamvar", "76448200+ravmakz@users.noreply.github.com"))
gert::git_push(set_upstream = TRUE, password = get_token(), repo = tmp)

# create a new pull request
cli::cli_h2("Creating pull request")
res <- gh("POST /repos/{repo}/pulls", 
  repo = arguments$repo,
  .params = list(
    head = paste0(arguments$user, ":", new_branch),
    base = "gh-pages",
    title = "test styles pull request"),
  .token = get_token()
)
cli::cli_alert_info("Pull Request: {.url {res$html_url}}")

