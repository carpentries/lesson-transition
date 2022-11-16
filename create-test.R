library("fs")
library("gh")
library("cli")
library("gert")
library("withr")
library("askpass")

# If the repository we want to test with exists, then we need to tell us to 
# delete it
no_repo <- tryCatch(gh("GET /repos/zkamvar/transition-test-2"), 
  github_error = function(e) e)

if (inherits(no_repo, "gh_response")) {
  browseURL("https://github.com/settings/tokens/new?scopes=delete_repo&description=delete%20transition%2Dtest%2D2")
  tkn <- askpass::askpass("Create a temporary token\nPASTE YOUR TOKEN HERE: ")
  res <- tryCatch(gh("DELETE /repos/zkamvar/transition-test-2", .token = tkn), 
    github_error = function(e) e
  )
  rm(tkn)
  (no_repo <- inherits(res, "gh_response"))
} else {
  no_repo <- TRUE
}

if (no_repo) {

  # create an empty repository
  cli::cli_alert_info("creating a new repository called transition-test-2")
  gh("POST /user/repos", name = "transition-test-2")

  # clone the test to our temporary directory
  cli::cli_alert_info("importing sgibson91/cross-stitch-carpentry to zkamvar/transition-test-2")
  cli::cli_status("Cloning a mirror of sgibson91/cross-stitch-carpentry")
  tmp <- withr::local_tempdir()
  git_clone("https://github.com/sgibson91/cross-stitch-carpentry/",
    path = tmp, mirror = TRUE)

  # set the URL
  cli::cli_status_update("setting the remote URL to zkamvar/transition-test-2")
  git_remote_set_url("https://github.com/zkamvar/transition-test-2/",
    remote = "origin",
    repo = tmp)

  # push it up
  cli::cli_status_update("pushing the mirror to zkamvar/transition-test-2")
  git_push(remote = "origin", mirror = TRUE, repo = tmp)
  withr::defer()
  cli::cli_status_clear()

  # set gh-pages as the default branch
  cli::cli_alert_info("Setting gh-pages as default")
  gh("PATCH /repos/zkamvar/transition-test-2", default_branch = "gh-pages") 
  
  # test a pull request to default branch
  cli::cli_alert_info("Creating a test pull request")
  gh("POST /repos/zkamvar/transition-test-2/pulls", 
    head = "change-prereq-box",
    base = "gh-pages",
    title = "test pull request")
  
} else {
  stop("Delete https://github.com/zkamvar/transition-test-2/ and try again")
}
