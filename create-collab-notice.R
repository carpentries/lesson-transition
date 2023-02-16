r'{Create markdown for a collaboration notice

Usage: 
  create-collab-notice.R [-xqhv] [<repo>] [<issue>]

-h, --help         Show this information and exit
-v, --version      Print the version information of this script
-q, --quiet        Do not print any progress messages
-x, --restrict     Restrict permissions for users in this repo. 
<repo>  Name of a repository to list collaborators for. Defaults to `carpentries/instructor-training`
<issue> issue number. if this is not provided, the list will be printed to the console
}' -> doc
library("docopt")


`%||%` <- function(a, b) if (length(a) < 1L || identical(a, FALSE) || identical(a, "")) b else a
arguments <- docopt(doc, version = "Stunning Barnacle 2022-11", help = TRUE)
arguments$repo <- arguments$repo %||% "carpentries/instructor-training"


# Get core team members to exclude from list
to_ignore <- gh::gh("GET /organizations/19267758/team/2540882/members") |>
  purrr::map_chr("login")
to_ignore <- c(to_ignore, "carpentries-bot")

# gather list of collaborators with push access that are _not_ core team members
collabs <- gh::gh("GET /repos/{repo}/collaborators", 
  repo = arguments$repo,
  .params = list(permission = "push")) |>
  purrr::discard(\(member) member$login %in% to_ignore)


cli::cli_h1("Gathering collaborators for {arguments$repo} with at least push access")

collab_list <- purrr::map_chr(collabs, \(x) {
  glue::glue(" - [ ] @{x$login} ({names(which(unlist(x$permissions))[1])})")
}) |> glue::glue_collapse(sep = "\n")

msg <- c("This lesson will be converted to use The Carpentries Workbench",
  "To prevent accidental reversion of the changes, we are temporarily revoking",
  "write access for all collaborators on this lesson:",
  "",
  collab_list,
  "",
  "If you no longer wish to have write access to this repository, you do not",
  "need to do anything further", 
  "",
  "If you wish to regain write access, please re-clone the repository on your machine and",
  "then comment here with `I am ready for write access :rocket:` and the",
  "admin maintainer of this repository will restore your permissions.",
  "",
  "If you have any questions, please reply here and tag @core-team-curriculum")

if (is.null(arguments$issue) || isFALSE(arguments$issue)) {
  cli::cli_h1("displaying to screen")
  writeLines(msg)
} else {
  cli::cli_h1("writing to PR")
  writeLines(msg)
}


