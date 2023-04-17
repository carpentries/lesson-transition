# Functions --------------------------------------------------------------------
write_out_rmd <- function(ep, where = "episodes") {
  ep$write(fs::path(new, where), format = "Rmd")
}
write_out_md <- function(ep, where = "episodes") {
  ep$write(fs::path(new, where), format = "md")
}

#
# The following lines are functions that I need to transform the lessons
#
# fix definition lists in a file. Kramdown had auto-identifiers for its
# definition lists, which pandoc does not have. Here, we use the new {pandoc}
# package to create these identifiers for the definition list.
# 
dl_auto_id <- function(path) {
  ref_lines <- readLines(path)
  # The definitions will always be immediately proceeding the line 
  # that starts with ":"
  defs <- which(startsWith(ref_lines, ":")) - 1L
  defs <- defs[!startsWith(ref_lines[defs], "[")]
  # get identifiers from pandoc
  headings <- pandoc::pandoc_convert(text = paste("#", ref_lines[defs]), to = "html")
  ids <- paste(headings, collapse = "\n")
  ids <- xml2::xml_text(xml2::xml_find_all(xml2::read_html(ids), ".//h1/@id"))
  ref_lines[defs] <- sprintf('[%s]{#%s}', ref_lines[defs], ids)
  ref_lines <- ref_lines[!grepl("[{][:]\\s?auto", ref_lines)]
  writeLines(ref_lines, path)
}
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

# Fix all link problems that remain.
fix_all_links <- function(episode) {
  links <- episode$validate_links(warn = FALSE)
  if (length(links) == 0 || nrow(links) == 0) {
    return(invisible(episode))
  }
  # make sure all links have https and not http
  fix_https_links(links)
  # make sure links do not start with _episodes or _extras
  fix_link_directories(links)
  # make sure  internal links do not end in /index.html or /
  fix_internal_slash_links(links)
  # make sure links out (e.g. to data via the raw directive are relative)
  fix_actually_internal_links(links, episode$lesson)

  # rerun to re-parse links
  links <- episode$validate_links(warn = FALSE)
  rename_local_links(links, from = "setup.html", to = "learners/setup.md")
  rename_local_links(links, from = "guide.html", to = "instructors/instructor-notes.md")
  invisible(episode)
}

rename_local_links <- function(links, from = "setup.html", to = "learners/setup.md") {
  needs_fixing <- links$server == "" & 
    links$scheme == "" & 
    links$path == from
  nodes <- links$node[needs_fixing]
  # loop through the nodes and fix.
  purrr::map(nodes, \(x) {
    dest <- xml2::xml_attr(x, "destination")
    new <- sub(from , to, dest, fixed = TRUE)
    xml2::xml_set_attr(x, "destination", new)
  })
  invisible(links)
}

# Fix all links that are http and not https because that's just kind of an annoying
# thing to have to fix manually when we know what the solution is.
fix_https_links <- function(links) {
  # extract the nodes that specifically fail the https test
  http <- links$node[!links$enforce_https]
  # loop through the nodes and fix.
  purrr::map(http, \(x) {
    dest <- sub("^http\\:", "https:", xml2::xml_attr(x, "destination"))
    xml2::xml_set_attr(x, "destination", dest)
  })
  invisible(links)
}

# Fix all links that are http and not https because that's just kind of an annoying
# thing to have to fix manually when we know what the solution is.
fix_internal_slash_links <- function(links) {
  # extract the nodes that specifically fail the https test
  needs_fixing <- links$server == "" & 
    links$scheme == "" & 
    (endsWith(links$path, "/") | endsWith(links$path, "/index.html"))
  nodes <- links$node[needs_fixing]
  # loop through the nodes and fix.
  purrr::map(nodes, \(x) {
    dest <- xml2::xml_attr(x, "destination")
    new <- sub("/(index.html)?(([#].+?)?([?].+?)?$)", ".html\\2", dest)
    xml2::xml_set_attr(x, "destination", new)
  })
  invisible(links)
}

fix_link_directories <- function(links) {
  # extract the nodes that specifically fail the https test
  needs_fixing <- links$server == "" & 
    links$scheme == "" & 
    (startsWith(links$path, "_episodes") | startsWith(links$path, "_extras"))
  this_file <- unique(links$filepath)
  nodes <- links$node[needs_fixing]
  # loop through the nodes and fix.
  purrr::map(nodes, \(x, the_file) {
    new <- xml2::xml_attr(x, "destination")
    this_dir <- fs::path_dir(this_file)
    nest <- this_dir != "."
    is_episode <- grepl("episodes[_]?", this_dir)
    if (nest) {
      ep <- if (is_episode) "" else "../episodes"
      lrn <- "../learners/"
    } else {
      ep <- "episodes/"
      lrn <- "learners/"
    }
    cat(glue::glue("Fixing {this_file}, nested: {nest} episode: {is_episode}"))
    new <- sub("_episodes(_rmd)?[/]", ep, new)
    new <- sub("_extras[/]", lrn, new)
    xml2::xml_set_attr(x, "destination", new)
  }, the_file = this_file)
  invisible(links)
}

become_self_aware <- function(node, org, lesson) {
  dst <- xml2::url_parse(xml2::xml_attr(node, "destination"))$path
  if (fs::path_file(dst) == "index.html") {
    dst <- fs::path_dir(dst)
  }
  if (fs::path_ext(dst) %in% c("html", "")) {
    dst <- fs::path_ext_set(dst, "md")
  }
  # regex to find and replace paths from either github or the lesson site
  branches <- "([/](raw[/])?(gh.pages|main|master))?"
  trkt <- glue::glue("[/]?({org})?[/]?{gsub('-', '.', lesson)}{branches}[/]")
  local_dst <- sub(trkt, "", dst, ignore.case = TRUE)
  # only update the node if the destination has changed
  if (local_dst != dst) {
    xml2::xml_set_attr(node, "destination", local_dst)
  }
  return(invisible(node))
}

# @param links a data frame returned by the `$validate_links()` method in
#   {pegboard}
# @param lesson the path to the lesson from which the episode originated.
fix_actually_internal_links <- function(links, lesson) {
  dst <- tolower(links$path)
  srv <- tolower(links$server)
  ext <- fs::path_ext(links$filepath[[1]])
  # determine the lesson 
  lsn <- tolower(fs::path_file(lesson))
  org <- tolower(fs::path_file(fs::path_dir(lesson)))
  this_org <- paste0(org, c(".org", ".github.io"))
  github   <- c("github.com", "raw.githubusercontent")
  in_this_org <- srv %in% this_org
  in_github   <- srv %in% github
  # The links are coming from inside the house if they are in this org and
  # the first part of the URL is this lesson
  raw_gh1 <- startsWith(dst, fs::path(org, lsn, "raw"))
  raw_gh2 <- grepl(glue::glue("{org}/{lsn}[/](raw[/])?(gh.pages|main|master)"), dst)
  in_this_lesson <- in_this_org & startsWith(dst, lsn)
  is_raw_link <-  in_github & ( raw_gh1 | raw_gh2 )
  if (!any(in_this_lesson | is_raw_link)) {
    return(invisible(links))
  }
  cli::cli_alert("processing {sum(in_this_lesson)} links in this lesson")
  purrr::walk(links$node[in_this_lesson], become_self_aware, org, lsn)
  cli::cli_alert("processing {sum(is_raw_link)} github raw links")
  purrr::walk(links$node[is_raw_link], become_self_aware, org, lsn)
}


# fix HTML that is indented and accidentally becomes code blocks
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

# Jekyll never provided a clear way to create custom anchors for headings
# so folks found some advice to add empty anchor tags to the headings so that
# they could reliably name them like:
#
# ## <a id='janky'></a> Janky heading with a weird anchor link
#
# This is inaccessible design. This function will change this heading to be
#
# ## Janky heading with a weird anchor link {#janky}
#
#
fix_janky_heading_ids <- function(episode) {
  # Find ONLY the nodes that start with an `<a>` tag. 
  headings <- xml2::xml_find_all(episode$body,
    ".//md:heading[md:html_inline[starts-with(text(), '<a')]]", 
    ns = episode$ns)
  for (this_heading in headings) {
    # parse the text into HTML, find the first anchor tag, and extract the 
    # id/name attribute
    txt    <- xml2::xml_text(this_heading)
    anchor <- xml2::xml_find_first(xml2::read_html(txt), 
      ".//a/@id | .//a/@name")
    id <- xml2::xml_text(anchor)
    # remove the HTML inline elements of this heading
    children <- xml2::xml_children(this_heading)
    xml2::xml_remove(children[xml2::xml_name(children) == "html_inline"])
    # append the id to the heading text
    this_text <- trimws(xml2::xml_text(this_heading))
    xml2::xml_set_text(this_heading, paste0(this_text, " {#", id, "}"))
  }
}



# transform the episodes via pegboard with reporters
transform <- function(e, out = new, verbose = getOption("carpentries.transition.loud", TRUE)) {
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

  cli::cli_status_update("fixing links (http -> https)")
  fix_all_links(e)

  cli::cli_status_update("fixing level 1 headings")
  fix_level_one_headings(e)

  cli::cli_status_update("fixing low-level headings")
  fix_small_headings(e)

  cli::cli_status_update("fixing inaccessible anchor links in headings")
  fix_janky_heading_ids(e)

  cli::cli_process_start("Writing {.file {fs::path_rel(outdir, getwd())}/{e$name}}")
  e$write(outdir, format = path_ext(e$name), edit = FALSE)
  cli::cli_process_done()
}

# Read and and transform additional files
rewrite <- function(x, out, verbose = getOption("carpentries.transition.loud", TRUE)) {
  tryCatch({
    ref <- pegboard::Episode$new(x, 
      process_tags = TRUE, 
      fix_links = TRUE, 
      fix_liquid = TRUE)
    ref$unblock()$use_sandpaper()
    if (ref$yaml[2] == "{}") {
      ref$yaml[2] = "title: 'FIXME'"
    }
    if (length(xml2::xml_children(ref$body)) == 0L) {
      ref$add_md("FIXME This is a placeholder file. Please add content here.")
    }
    if (fs::path_file(x) == "reference.md") {
      ref$add_md("## Glossary")
    }
    fix_all_links(ref)
    ref$write(out, format = fs::path_ext(x))
  }, error = function(e) {
    if (verbose) cli::cli_alert_warning("Could not process {.file {x}}: {e$message}")
  })
}

# Copy a directory if it exists
copy_dir <- function(x, out, verbose = getOption("carpentries.transition.loud", TRUE)) {
  tryCatch(fs::dir_copy(x, out, overwrite = TRUE),
    error = function(e) {
      if (verbose) {
        cli::cli_alert_warning("Could not copy {.file {x}}")
        cli::cli_alert_warning(e$message)
      }
    })
}

del_dir <- function(x, verbose = getOption("carpentries.transition.loud", TRUE)) {
  tryCatch(fs::dir_delete(x), 
    error = function(e) {
      if (verbose) cli::cli_alert_warning("Could not delete {.file {x}}")
    })
}

del_file <- function(x, verbose = getOption("carpentries.transition.loud", TRUE)) {
  tryCatch(fs::file_delete(x), 
    error = function(e) {
      if (verbose) cli::cli_alert_warning("Could not delete {.file {x}}")
    })
}



add_experiment_info <- function(episode) {
  if (Sys.getenv("PROD") == "true") {
    return(invisible(episode))
  }
  # Modify the index to include our magic header
  experiment <- "> **ATTENTION** This is an experimental test of [The Carpentries Workbench](https://carpentries.github.io/workbench) lesson infrastructure.
> It was automatically converted from the source lesson via [the lesson transition script](https://github.com/carpentries/lesson-transition/).
>
> If anything seems off, please contact Zhian Kamvar <zkamvar@carpentries.org>
"
  episode$add_md(experiment, 0L)
}

# REPOSITORY FUNCTIONS ---------------------------------------------------------
#
# In this section, we have functions that help modify the source repository.
# 
# As with all projects, these functions really should be sent into a different
# file, but it is a little late for that now.

#' Retrieve a GitHub token for a given user
#'
#' Use this function to provision an alternate account password or a temporary
#' token for use in either github API calls or passing the password to {gert}.
#'
#' @param username the user name from which to retrieve the token. 
#' @param scopes if a new token should be created, a vector of scopes for that
#'   token, defaults to public_repo
#' @param description a meaningful description of the new token
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
create_token <- function() {
  pwd <- NULL
  function(username = "ravmakz", scopes = c("public_repo"),
    description = "fork transtion test", reset = FALSE) {
    if (is.null(pwd) || reset) {
      # prompt to create a new token 
      base <- "https://github.com/settings/tokens/new"
      description <- xml2::url_escape(description)
      scopes <- paste(scopes, collapse = ",")
      url <- glue::glue("{base}?scopes={scopes}&description={description}")
      browseURL(url)
      msg <- glue::glue("Create a temporary token with `{scopes}` scopes:\nPASTE YOUR TOKEN HERE: ")
      # askpass prevents the system from seeing the value of the pasted token
      pwd <<- askpass::askpass(msg)
    }
    invisible(pwd)
  }
}
get_token <- create_token()

setup_gert_url <- function(user, url) {
  gert_url <- sub("github.com", paste0(user, "@github.com"), url)
  paste0(gert_url, ".git")
}

#' Set up a given GitHub repository to recieve the Workbench
#'
#' @param path path to a transformed lesson
#' @param owner the github repo owner name
#' @param repo the name of the repository
#' @param action the action to insert into the gh-pages branch to prevent
#'   new pull requests
#' @param .token the GitHub API token
#'
#' Transforming a lesson repository invovlves a couple of steps:
#'
#' 1. renaming the default branch and, if needed, the gh-pages branch to have
#'   `legacy/` prefixes 
#' 2. enabling GitHub actions to run (that should not be too much of an issue)
#' 3. pushing the main branch
#' 4. setting the main branch as default
#' 5. protecting the main branch
setup_github <- function(path = NULL, owner, repo, action = "close-pr.yaml", .token = NULL) {

  creds <- gh::gh_whoami(.token = .token)
  cli::cli_h1("Credentials")
  print(creds)
  user <- creds$login
  stopifnot("Token must be a character" = is.character(.token))

  # get default branch
  cli::cli_h1("Setting up repository")
  REPO <- glue::glue("GET /repos/{owner}/{repo}")
  repo_info <- gh::gh(REPO, .token = .token)
  jsonlite::write_json(repo_info, sub("[/]?$", "-status.json", path))
  default <- repo_info$default_branch
  date_created <- as.character(as.Date(repo_info$created_at))
  sandpaper::set_config(c(created = date_created), write = TRUE, path = path)
  withr::with_dir(path, {
    callr::run("git", c("add", "config.yaml"), 
      echo = TRUE, echo_cmd = TRUE)
    callr::run("git", c("commit", "--amend", "--no-edit"), 
      echo = TRUE, echo_cmd = TRUE)
  })

  action <- if (is.null(action)) NULL else fs::path_abs(action)

  # rename default branch
  cli::cli_alert_info("renaming default branch ({default}) to legacy/{default}")
  RENAME <- glue::glue("POST /repos/{owner}/{repo}/branches/{default}/rename") 
  print(RENAME)
  gh::gh(RENAME, new_name = glue::glue("legacy/{default}"), .token = .token)

  # rename gh-pages if not default
  if (default == "main") {
    cli::cli_alert_info("renaming gh-pages to legacy/gh-pages")
    RENAME <- glue::glue("POST /repos/{owner}/{repo}/branches/gh-pages/rename") 
    gh::gh(RENAME, new_name = glue::glue("legacy/gh-pages"), .token = .token)
  }
  # GITHUB ACTIONS ------------------------------------------------------------
  # Set up actions for a repository
  cli::cli_alert_info("enabling github actions to be run")
  ACTIONS <- glue::glue("PUT /repos/{owner}/{repo}/actions/permissions")
  gh::gh(ACTIONS, enabled = TRUE, allowed_actions = "all", .token = .token)

  cli::cli_alert_info("fetching and pruning branches")
  withr::with_dir(path, {
    callr::run("git", c("fetch", "--prune", "origin"), echo = TRUE, echo_cmd = TRUE)
  })

  cli::cli_h1("Setting up default branch")

  default_origin <- glue::glue("https://github.com/{owner}/{repo}")
  new_origin <- setup_gert_url(user, default_origin)
  on.exit(
    gert::git_remote_set_url(default_origin, remote = "origin", repo = path),
    add = TRUE)
  cli::cli_alert("New origin: {.url {new_origin}}")
  gert::git_remote_set_url(new_origin, remote = "origin", repo = path)
  # FORCE push main branch ----------------------------------------------------
  cli::cli_alert_info("pushing the main branch")
  gert::git_push(repo = path, remote = "origin", 
    set_upstream = TRUE, force = TRUE, password = .token)
  # refspec = "refs/heads/main" 

  # set the main branch to be the default branch
  cli::cli_alert_info("setting main branch as default")
  gh::gh("PATCH /repos/{owner}/{repo}", owner = owner, repo = repo, 
    default_branch = "main", .token = .token) 

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
    restrictions = NA,
    .token = .token
  )

  # gh-pages branch -----------------------------------------------------------
  # setting a new, empty gh-pages branch 
  cli::cli_alert_info("creating empty gh-pages branch and forcing it up")
  withr::with_dir(path, {
    callr::run("git", c("checkout", "--orphan", "gh-pages"), 
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
    cli::cli_alert_info("locking legacy/main")
    PROTECT <- glue::glue("PUT /repos/{owner}/{repo}/branches/legacy/main/protection") 
    gh::gh(PROTECT, 
      required_status_checks = NA, 
      enforce_admins = TRUE, 
      required_pull_request_reviews = NA, 
      restrictions = NA,
      lock_branch = TRUE,
      .token = .token
    ) 
  }
  cli::cli_alert_info("locking legacy/gh-pages")
  PROTECT <- glue::glue("PUT /repos/{owner}/{repo}/branches/legacy/gh-pages/protection") 
  gh::gh(PROTECT, 
    required_status_checks = NA, 
    enforce_admins = TRUE, 
    required_pull_request_reviews = NA, 
    restrictions = NA,
    lock_branch = TRUE,
    .token = .token
  ) 

  # CLOSING any remaining pull requests
  close_open_prs(owner, repo, .token)
}

close_open_prs <- function(owner, repo, .token = NULL) {

  cli::cli_alert_info("Closing open pull requests")
  pulls <- gh::gh("GET /repos/{owner}/{repo}/pulls", 
    owner = owner,
    repo = repo,
    per_page = 100,
    .token = .token,
    .limit = Inf
  )
  if (length(pulls) == 0) {
    cli::cli_alert("No pull requests!")
    return(invisible())
  }
  cli::cli_alert("Found {length(pulls)} pull requests")

  # read in PR closer message and tag the appropriate team
  msg <- paste(readLines("close-pr-msg.md"), collapse = "\n")
  team_tag <- switch(tolower(owner), 
    swcarpentry = "@swcarpentry/staff-curriculum",
    librarycarpentry = "@librarycarpentry/staff-curriculum",
    datacarepentry = "@datacarpentry/core-team-curriculum",
    carpentries = "@carpentries/core-team-curriculum",
    `carpentries-lab` = "@carpentries-lab/core-team-curriculum"
  )
  msg <- sub("@core-team-curriculum", team_tag, msg, fixed = TRUE)
  # comment on each PR, tag it, and close it
  purrr::walk(pulls, function(x, msg) {
    cli::cli_status("{cli::symbol$play} Processing #{x$number} ({x$title})")
    cli::cli_status_update("{cli::symbol$info} Commenting on #{x$number} ({x$title})")
    gh::gh("POST /repos/{owner}/{repo}/issues/{number}/comments", 
      owner = owner,
      repo = repo,
      number = x$number,
      .token = .token,
      .params = list(
        body = msg
    ))
    gh::gh("POST /repos/{owner}/{repo}/issues/{number}/labels", 
      owner = owner,
      repo = repo,
      number = x$number,
      .token = .token,
      .params = list(
        labels = list("pre-workbench")
    ))
    cli::cli_status_update("{cli::symbol$stop} Closing #{x$number} ({x$title})")
    gh::gh("POST /repos/{owner}/{repo}/pulls/{number}", 
      owner = owner,
      repo = repo,
      .token = .token,
      number = x$number,
      .params = list(
        state = "closed"
      )
    )
  }, msg = msg)
  cli::cli_alert("Pull Requests Managed")
}

# Create a team for maintainers who have confirmed that they have prepared for
# the transition. The default maintainer team will be locked until they match.
create_workbench_team <- function(owner, repo, .token = NULL) {
  parent_ids <- c(carpentries = 3296124L,
    datacarpentry = 3267328L,
    librarycarpentry = 3276234L,
    swcarpentry = 3276177L)

  # check if the team already exists
  team <- tryCatch({
    gh::gh("GET /orgs/{owner}/teams/{repo}-maintainers-workbench",
      owner = owner,
      repo = repo,
      .token = .token
    )
  }, http_error_404 = function(e) {
    # a 404 error from github means that the team does not exist
    NULL
  })

  if (is.null(team)) {
    cli::cli_alert_info("Creating a workbench team for {.path {owner}/{repo}}")
    # if it does not exist, create the team and then add the repository to it
    team <- gh::gh("POST /orgs/{org}/teams",
      org = owner,
      .token = .token,
      .params = list(
        name = glue::glue("{repo}-maintainers-workbench"),
        description = "A repo", 
        parent_team_id = parent_ids[tolower(owner)] + 2023L + 05L + 01L,
        repo_name = glue::glue("{owner}/{repo}")
      )
    )
    gh::gh("PUT /orgs/{org}/teams/{repo}-maintainers-workbench/repos/{org}/{repo}",
      org = owner,
      repo = repo,
      .token = .token,
      .params = list(permission = "maintain")
    )
  }
  cli::cli_alert_info("Adding Carpentries Apprentice to repository")
  add_bot_to_repo(owner, repo, .token)
  team
}

# Make sure The Carpentries Bot is allowed to access the repository
add_bot_to_repo <- function(owner, repo, .token = NULL) {
  res <- tryCatch({
    gh::gh("PUT /orgs/{org}/teams/bots/repos/{org}/{repo}",
      org = owner,
      repo = repo,
      .token = .token,
      .params = list(permission = "push")
    )
  }, http_error_422 = function(e) {
    cli::cli_alert_danger("could not add bots to repo")
    print(e)
  })
  res
}

# restrict team access to read
set_team_to_read <- function(owner, repo, .token = NULL) {
  res <- tryCatch({
    gh::gh("PUT /orgs/{org}/teams/{repo}-maintainers/repos/{org}/{repo}",
      org = owner,
      repo = repo,
      .token = .token,
      .params = list(permission = "read")
    )
  }, http_error_422 = function(e) {
    cli::cli_alert_danger("could not modify @{org}/{repo}-maintainers")
    print(e)
  })
  res
}

add_workflow_token <- function(owner, repo, .token) {
  scope <- gh::gh_whoami(.token = .token)$scopes
  if (!grepl("admin[:]org", scope)) {
    cli::cli_alert_danger("need the admin token for this")
    return(NULL)
  }
  id <- gh::gh("GET /repos/{org}/{repo}", 
    org = owner, repo = repo, .token = .token)$id
  tryCatch({
    gh::gh("PUT /orgs/{org}/actions/secrets/SANDPAPER_WORKFLOW/repositories/{id}",
    org = owner,
    id = id,
    .token = .token)
  }, 
  http_error_403 = function(e) {
    cli::cli_alert_danger("need the admin token for this")
    print(e)
  },
  http_error_409 = function(e) {
    cli::cli_alert_danger("visibility error")
    print(e)
  })
}


# Add team members who have confirmed that they are able to use The Workbench
add_workbench_team_members <- function(members, owner, repo) {
  purrr::map(members, function(user) {
    tryCatch({
    gh::gh("PUT /orgs/{org}/teams/{repo}-maintainers-workbench/memberships/{user}",
      org = owner,
      repo = repo,
      user = user
    )
    }, error = function(e) {
      e
    })
  })
}

# STORAGE ESTIMATION FOR THIS REPOSITORY --------------------------------------
# https://stackoverflow.com/a/63543936/2752888
file_size_formatted <- function(size){
  
  k = size/1024.0 ^ 1
  m = size/1024.0 ^ 2
  g = size/1024.0 ^ 3
  t = size/1024.0 ^ 4
  
    if (t > 1) {
      outSize = paste0(round(t,2),"TB")
    } else if (g > 1) {
      outSize = paste0(round(g,2),"GB")
    } else if (m > 1) {
      outSize = paste0(round(m,2),"MB")
    } else if (k > 1) {
      outSize = paste0(round(k,2),"KB")
    } else{
      outSize = paste0(round(size,2),"B")
    }
    
  return(outSize)
}

#' Return the size of public organisation repositories in Bytes.
#'
#' @param org the name of the github organisation
org_repo_sizes <- function(org, update = FALSE) {
  csv <- fs::path_ext_set(org, "csv")
  if (!update && fs::file_exists(csv)) {
    return(tibble::tibble(read.csv(csv, header = TRUE)))
  }
  res <- gh::gh("GET /orgs/{org}/repos", org = org, 
    .limit = Inf, per_page = 100, .params = list(type = "public"))
  out <- purrr::map_dfr(res, function(x) {
    tibble::tibble(repo = x$name, size = x$size * 1024)
  })
  write.csv(out, csv, row.names = FALSE)
  out
}

get_active_lessons <- function(json) {
  json <- purrr::discard(json, function(x) {
    x$life_cycle == "on-hold" |
    x$repo %in% c("workbench-template-md", "workbench-template-rmd", "lesson-development-training", "sandpaper-docs", "lesson-example")
  })
  purrr::map_dfr(json, function(x) tibble::tibble(org = x$carpentries_org, repo = x$repo))
}

lesson_size_summary <- function(lessons, orgs, summarise = TRUE) {
  res <- dplyr::inner_join(lessons, orgs, by = c("org", "repo"))
  if (summarise) {
    res <- dplyr::group_by(res, org) |>
      dplyr::summarize(size = sum(size))
  }
  res <- tibble::add_row(res, org = "TOTAL", size = sum(res$size))
  res$readable <- vapply(res$size, file_size_formatted, character(1))
  res$required <- vapply(res$size * 3, file_size_formatted, character(1))
  res
}

print_storage <- function(size_table, title = "Lessons") {
  cols <- c("GitHub Organisation", "Repo Size", "Required (3x Repo Size)")
  align <- "lrr"
  print(knitr::kable(size_table[-2], 
      col.names = cols, 
      align = align,
      label = title))
}

estimate_storage <- function() {
  orgs <- c("carpentries", "carpentries-incubator", "carpentries-lab",
    "datacarpentry", "librarycarpentry", "swcarpentry")
  names(orgs) <- orgs
  sizes <- purrr::map_dfr(orgs, org_repo_sizes, .id = "org")
  lessons <- jsonlite::read_json("https://feeds.carpentries.org/lessons.json")
  incubator <- jsonlite::read_json("https://feeds.carpentries.org/community_lessons.json")
  lessons <- get_active_lessons(lessons)
  incubator <- get_active_lessons(incubator)
  print_storage(lesson_size_summary(lessons, sizes), "Official Lessons")
  print_storage(lesson_size_summary(incubator, sizes), "Community Lessons")
  official_size_table <- lesson_size_summary(lessons, sizes, summarise = FALSE)
  write.csv(official_size_table, "official-repo-sizes.csv", row.names = FALSE)
  community_size_table <- lesson_size_summary(incubator, sizes, summarise = FALSE)
  write.csv(community_size_table, "community-repo-sizes.csv", row.names = FALSE)
}

create_release_checklist <- function() {
  lessons <- read.csv("official-repo-sizes.csv")
  lessons <- lessons[lessons$org != "TOTAL", ]
  lessons <- lessons[order(lessons$org, lessons$repo), ]
  releases <- gh::gh("GET /repos/carpentries/lesson-transition/tags")
  releases <- purrr::map_chr(releases, "name")
  tag <- vapply(lessons$org, switch, character(1), carpentries = "cp", datacarpentry = "dc", swcarpentry = "swc", librarycarpentry = "lc")
  tag <- glue::glue("{ifelse(lessons$repo %in% c('r-socialsci', 'instructor-training', 'python-ecology-lesson-es', 'r-raster-vector-geospatial'), 'beta', 'release')}_{tag}/{lessons$repo}")
  print(tag)
  blob_prefix <- "[commit map](https://github.com/carpentries/lesson-transition/blob/"
  blob_postfix <- glue::glue_data(lessons, 
    "/beta/{org}/{repo}-commit-map.hash)")
  lessons$status <- ifelse(tag %in% releases, 
    paste0(blob_prefix, tag, blob_postfix),
    "unprocessed"
  )
  lessons$released <- ifelse(tag %in% releases, ":ok:", ":hourglass_flowing_sand:")
  lessons$lesson <- glue::glue_data(lessons, "[{org}/{repo}](https://github.com/{org}/{repo})")
  lessons$issue <- ""
  lessons$date  <- "2023-05-07"
  lessons$number <- seq(nrow(lessons))
  res <- lessons[c("number", "lesson", "released", "date", "status", "issue")]
  print(knitr::kable(res, col.names = c("#", "Lesson", "Released", "Date", "Artifacts", "Issue"), align = "rlcrll", row.names = FALSE))

  invisible(res)
}


# extract tasks for all the lessons in 
get_tasks <- function(repo = "carpentries/lesson-transition", tags = "lesson") {
  issues <- gh::gh("GET /repos/{repo}/issues", per_page = 100, .limit = Inf,
    repo = repo, .params = list(labels = tags))
  purrr::map_dfr(issues, extract_tasklist)
}

extract_tasklist <- function(issue) {
  title <- issue$title
  nr <- issue$number
  url <- issue$html_url
  f <- textConnection(issue$body)
  on.exit(close(f), add = TRUE)
  y <- tinkr::yarn$new(f)
  status <- as.logical(NA)
  complete <- 0
  total    <- 0
  tasks <- xml2::xml_find_all(y$body, ".//md:tasklist", ns = y$ns)
  if (length(tasks)) {
    status <- xml2::xml_attr(tasks, "completed") == "true"
    complete <- sum(status)
    total <- length(status)
    tasks <- xml2::xml_text(tasks)
  } else {
    tasks <- NA_character_
  }
  msg <- "{complete}/{total} tasks complete: (#{sprintf('%02d', nr)}) {title}"
  if (complete == total) {
    complete <- cli::style_bold(cli::col_blue(complete))
    cli::cli_alert_success(msg)
  } else {
    cli::cli_alert_info(msg)
  }

  tibble::tibble(lesson = title, issue = nr, task = tasks, complete = status, url = url)

}


# make the test calls for a given set of lessons
make_test_calls <- function(tags = "early transition") {
  # get nested list of orgs and lessons.
  tasks <- get_tasks(tags = tags)
  lsn  <- purrr::transpose(strsplit(unique(tasks$lesson), "/"))
  names(lsn) <- c("org", "lesson")
  lsn <- lapply(lsn, as.character)
  make_bash_nest(split(lsn$lesson, lsn$org))
}

make_bash_nest <- function(lst) {
  json <- as.character(jsonlite::toJSON(lst))
  json <- gsub('[:"]', "", json)
  json <- gsub("\\[", "/{", json)
  json <- gsub("\\]", "}", json)
  json <- gsub("[{]([^/,]+?)[}]", "\\1", json)
  usethis::ui_code_block("make -n -Bj 7 sandpaper/{json}.json") 
}
