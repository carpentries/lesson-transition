# Functions --------------------------------------------------------------------
#
# The following lines are functions that I need to transform the lessons
#
# transform the image links to be local
fix_images <- function(episode, from = "([.][.][/])?(img|fig|images)/", to = "fig/") {
  blocks <- xml_find_all(episode$body, 
    ".//md:code_block[contains(text(), 'knitr::include_graphics')]",
    ns = episode$ns
  )
  if (length(blocks)) {
    txt <- xml_text(blocks)
    xml_set_text(blocks, sub(from, to, txt))
  }
  images <- episode$get_images(process = TRUE)
  images <- episode$images
  if (length(images)) {
    dest <- xml_attr(images, "destination")
    xml_set_attr(images, "destination", sub(from, to, dest))
  }
  episode
}

# Fix all links that are http and not https because that's just kind of an annoying
# thing to have to fix manually when we know what the solution is.
fix_https_links <- function(episode) {
  # extract the table of links that do not pass checks
  
  links <- episode$validate_links(warn = FALSE)
  if (length(links) == 0 || nrow(links) == 0) {
    return(invisible(episode))
  }
  # extract the nodes that specifically fail the https test
  http <- links[!links$enforce_https, ]$node
  # loop through the nodes and fix.
  purrr::map(http, \(x) {
    dest <- sub("^http\\:", "https:", xml2::xml_attr(x, "destination"))
    xml2::xml_set_attr(x, "destination", dest)
  })
  invisible(episode)
}

fix_html_indents <- function(episode) {
  html <- xml_find_all(episode$body, ".//md:html_block", episode$ns)
  if (length(html)) {
    # we allow markdown in html blocks because it can be useful for folks to 
    # express block-level html syntax. However, this can clash with the output
    # of some python programs, so we replace all gaps greater than or equal to
    # four spaces with three spaces.
    txt <- gsub("[>]\\s{4,}[<]", ">   <", xml_text(html))
    xml_set_text(html, txt)
  }
  episode
}

# fix headings that start at greater than two and are all greater than level 2
#
# In this case, headings should all be decreased by one level
fix_small_headings <- function(episode) {
  headings <- episode$headings
  if (length(headings)) {
    hlevels <- as.integer(xml2::xml_attr(headings, "level"))
    greater_than_two <- hlevels > 2
    if (greater_than_two[1] && all(greater_than_two)) {
      hlevels <- hlevels - 1L
      xml2::xml_set_attr(headings, "level", as.character(hlevels))
    }
  }
  return(episode)
}

# fix headings that are at level 1
#
# if there is only a single heading at level one, we increase the level of this
# heading and only this heading
#
# if there are multiple level 1 headings, then we assume that all the headings
# flow from there and increase the level of all the headings.
fix_level_one_headings <- function(episode) {
  headings <- episode$headings
  hlevels <- xml2::xml_attr(headings, "level")
  first_levels <- hlevels == "1"
  if (sum(first_levels) == 0) {
    return(episode)
  }
  if (sum(first_levels) == 1) {
    hlevels[first_levels] <- "2"
  } else {
    hlevels <- as.character(as.integer(hlevels) + 1L)
  }
  xml2::xml_set_attr(headings, "level", hlevels)
}



# transform the episodes via pegboard with reporters
transform <- function(e, out = new) {
  outdir <- fs::path(out, "episodes/")
  cli::cli_process_start("Converting {.file {fs::path_rel(e$path, getwd())}} to {.emph sandpaper}")
  cli::cli_status_update("converting block quotes to pandoc fenced div")
  e$unblock()

  cli::cli_status_update("removing Jekyll syntax")
  e$use_sandpaper()

  cli::cli_status_update("moving yaml items to body")
  e$move_questions()
  e$move_objectives()
  e$move_keypoints()
  cli::cli_process_done()

  cli::cli_status_update("fixing math blocks")
  tryCatch(e$protect_math(),
    error = function(e) {
      cli::cli_alert_warning("Some math could not be parsed... likely because of shell variable examples")
      cli::cli_alert_info("Below is the error")
      cli::cli_alert_warning(e$message)
    })

  cli::cli_status_update("fixing image links") 
  fix_images(e)

  cli::cli_status_update("fixing html indents")
  fix_html_indents(e)

  cli::cli_status_update("fixing http -> https")
  fix_https_links(e)

  cli::cli_status_update("fixing level 1 headings")
  fix_level_one_headings(e)

  cli::cli_status_update("fixing low-level headings")
  fix_small_headings(e)

  cli::cli_process_start("Writing {.file {fs::path_rel(outdir, getwd())}/{e$name}}")
  e$write(outdir, format = path_ext(e$name), edit = FALSE)
  cli::cli_process_done()
}

# Read and and transform additional files
rewrite <- function(x, out) {
  tryCatch({
    ref <- pegboard::Episode$new(x, 
      process_tags = TRUE, 
      fix_links = TRUE, 
      fix_liquid = TRUE)
    ref$unblock()$use_sandpaper()$write(out, format = fs::path_ext(x))
  }, error = function(e) {
    cli::cli_alert_warning("Could not process {.file {x}}: {e$message}")
  })
}

# Copy a directory if it exists
copy_dir <- function(x, out) {
  tryCatch(fs::dir_copy(x, out, overwrite = TRUE),
    error = function(e) {
      cli::cli_alert_warning("Could not copy {.file {x}}")
      cli::cli_alert_warning(e$message)
    })
}

del_dir <- function(x) {
  tryCatch(fs::dir_delete(x), 
    error = function(e) {
      cli::cli_alert_warning("Could not delete {.file {x}}")
    })
}

del_file <- function(x) {
  tryCatch(fs::file_delete(x), 
    error = function(e) {
      cli::cli_alert_warning("Could not delete {.file {x}}")
    })
}



add_experiment_info <- function(episode) {
  # Modify the index to include our magic header
  experiment <- "> **ATTENTION** This is an experimental test of [The Carpentries Workbench](https://carpentries.github.io/workbench) lesson infrastructure.
> It was automatically converted from the source lesson via [the lesson transition script](https://github.com/carpentries/lesson-transition/).
>
> If anything seems off, please contact Zhian Kamvar <zkamvar@carpentries.org>
"
  episode$add_md(experiment, 0L)
}

#' Retrieve a GitHub token for a given user
#'
#' Use this function to provision an alternate account password or a temporary
#' token for use in either github API calls or passing the password to {gert}.
#'
#' @param username the user name from which to retrieve the token. 
#' @param scopes if a new token should be created, a vector of scopes for that
#'   token, defaults to public_repo
#' @param description a meaningful description of the new token
#' @param write if `TRUE`, the new token profile is written to the credentials
#'   helper. Defaults to `FALSE`
#' @param reset if `TRUE` an existing token will be replaced with the new token.
#'   Defaults to `FALSE`.
#'
#' @note I have noticed that `gh::gh_token()` becomes confused after this is
#'   used and uses the first token in alphabetical order, so it might be better
#'   to use this function to store the token in an environment instead of the
#'   local storage cache. 
#'
#' If you use `get_token()`, it will give you the token for ravmakz, if it
#' exists on your local machine. If it does not, you will be prompted to
#' generate the token manually.
#'
#' `get_token(reset = TRUE)` will prompt you to generate a token and then it
#' will reset the value on your machine. 
#' 
#' To generate a temporary token for your account without saving it, use a fake
#' username: `get_token("fakename")`. Because reset and write are set to FALSE,
#' this token is strictly temporary. 
get_token <- function(username = "ravmakz", scopes = c("public_repo"),
  description = "fork transtion test", write = FALSE, reset = FALSE) {
  pwd <- gitcreds::gitcreds_fill(list(
      url = "https://github.com", 
      username = username))
  # get the password output from gitcreds. It will default to `dummy get` if no
  # password exists
  pwd <- strsplit(pwd[grepl('^password', pwd)], "=")[[1]][2]
  if (pwd == "dummy get" || reset) {
    # prompt to create a new token 
    base <- "https://github.com/settings/tokens/new"
    description <- xml2::url_escape(description)
    scopes <- paste(scopes, collapse = ",")
    url <- glue::glue("{base}?scopes={scopes}&description={description}")
    browseURL(url)
    msg <- glue::glue("Create a temporary token with `{scopes}` scopes:\nPASTE YOUR TOKEN HERE: ")
    # askpass prevents the system from seeing the value of the pasted token
    pwd <- askpass::askpass(msg)
    if (write || reset) {
      gitcreds::gitcreds_approve(list(
          url = "https://github.com", 
          username = username, 
          password = pwd))
    }
  }
  invisible(pwd)
}
#' Set up a given GitHub repository to recieve the Workbench
#'
#' @param path path to a transformed lesson
#' @param owner the github repo owner name
#' @param repo the name of the repository
#'
#' Transforming a lesson repository invovlves a couple of steps:
#'
#' 1. renaming the default branch and, if needed, the gh-pages branch to have
#'   `legacy/` prefixes 
#' 2. enabling GitHub actions to run (that should not be too much of an issue)
#' 3. pushing the main branch
#' 4. setting the main branch as default
#' 5. protecting the main branch
setup_github <- function(path = NULL, owner, repo, action = "close-pr.yaml") {
  # get default branch
  cli::cli_h1("Setting up repository")
  REPO <- glue::glue("GET /repos/{owner}/{repo}")
  repo_info <- gh::gh(REPO)
  default <- repo_info$default_branch
  action <- if (is.null(action)) NULL else fs::path_abs(action)

  # rename default branch
  cli::cli_alert_info("renaming {default} to legacy/{default}")
  RENAME <- glue::glue("POST /repos/{owner}/{repo}/branches/{default}/rename") 
  print(RENAME)
  gh::gh(RENAME, new_name = glue::glue("legacy/{default}"))

  # rename gh-pages if not default
  if (default == "main") {
    cli::cli_alert_info("renaming gh-pages to legacy/gh-pages")
    RENAME <- glue::glue("POST /repos/{owner}/{repo}/branches/gh-pages/rename") 
    gh::gh(RENAME, new_name = glue::glue("legacy/gh-pages"))
  }
  # GITHUB ACTIONS ------------------------------------------------------------
  # Set up actions for a repository
  cli::cli_alert_info("enabling github actions to be run")
  ACTIONS <- glue::glue("PUT /repos/{owner}/{repo}/actions/permissions")
  gh::gh(ACTIONS, enabled = TRUE, allowed_actions = "all")

  cli::cli_alert_info("fetching and pruning branches")
  withr::with_dir(path, {
    callr::run("git", c("fetch", "--prune", "origin"), echo = TRUE, echo_cmd = TRUE)
  })

  cli::cli_h1("Setting up default branch")
  # FORCE push main branch ----------------------------------------------------
  cli::cli_alert_info("pushing the main branch")
  gert::git_push(repo = path, set_upstream = TRUE, force = TRUE)
  # refspec = "refs/heads/main" 

  # set the main branch to be the default branch
  cli::cli_alert_info("setting main branch as default")
  gh::gh("PATCH /repos/{owner}/{repo}", owner = owner, repo = repo, 
    default_branch = "main") 

  # Protect the main branch from becoming sausage -----------------------------
  # 
  # https://docs.github.com/en/rest/branches/branch-protection?apiVersion=2022-11-28#update-branch-protection
  cli::cli_alert_info("protecting the main branch")
  PROTECT <- glue::glue("PUT /repos/{owner}/{repo}/branches/main/protection") 
  falsy <- structure(FALSE, class = c("scalar", "logical"))
  pr_reviews <- list( 
    dismiss_stale_reviews = falsy, 
    require_code_owner_reviews = falsy,
    require_last_push_approval = falsy,
    required_approving_review_count = 0L 
  ) 
  gh::gh(PROTECT,  
    required_status_checks = NA, 
    enforce_admins = TRUE, 
    required_pull_request_reviews = pr_reviews, 
    restrictions = NA 
  ) 

  # gh-pages branch -----------------------------------------------------------
  # setting a new, empty gh-pages branch 
  cli::cli_alert_info("creating empty gh-pages branch and forcing it up")
  withr::with_dir(path, {
    callr::run("git", c("checkout", "--orphan", "pages"), 
      echo = TRUE, echo_cmd = TRUE)
    callr::run("git", c("rm", "-rf", "."), 
      echo = FALSE, echo_cmd = TRUE)
    # we want to add a workflow to prevent pushes
    if (inherits(action, "fs_path")) {
      cli::cli_alert_info("Adding the workflow to prevent pull requests")
      fs::dir_create(".github/workflows", recurse = TRUE)
      fs::file_copy(action, ".github/workflows")
      callr::run("git", c("add", fs::path(".github/workflows", fs::path_file(action))), 
          echo = TRUE, echo_cmd = TRUE)
    }
    callr::run("git", c("commit", "--allow-empty", "-m", "Intializing gh-pages branch"), 
      echo = TRUE, echo_cmd = TRUE)
    callr::run("git", c("push", "--force", "origin", "HEAD:gh-pages"), 
      echo = TRUE, echo_cmd = TRUE)
    callr::run("git", c("switch", "main"), 
      echo = TRUE, echo_cmd = TRUE)
  })

  # LOCKING legacy branches ---------------------------------------------------
  cli::cli_alert_info("locking legacy branches")
  if (default == "main") {
    PROTECT <- glue::glue("PUT /repos/{owner}/{repo}/branches/legacy/main/protection") 
    gh::gh(PROTECT, 
      required_status_checks = NA, 
      enforce_admins = TRUE, 
      required_pull_request_reviews = NA, 
      restrictions = NA,
      lock_branch = TRUE
    ) 
  }
  PROTECT <- glue::glue("PUT /repos/{owner}/{repo}/branches/legacy/gh-pages/protection") 
  gh::gh(PROTECT, 
    required_status_checks = NA, 
    enforce_admins = TRUE, 
    required_pull_request_reviews = NA, 
    restrictions = NA,
    lock_branch = TRUE
  ) 


}

