# Functions --------------------------------------------------------------------
#
# The following lines are functions that I need to transform the lessons
#
# transform the image links to be local
fix_images <- function(episode, from = "([.][.][/])?(img|fig)/", to = "fig/") {
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

# transform the episodes via pegboard with reporters
transform <- function(e, out = new) {
  outdir <- fs::path(out, "episodes/")
  cli::cli_process_start("Converting {.file {e$path}} to {.emph sandpaper}")
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

  cli::cli_process_start("Writing {.file {outdir}/{e$name}}")
  e$write(outdir, format = path_ext(e$name), edit = FALSE)
  cli::cli_process_done()
}

# Read and and transform additional files
rewrite <- function(x, out) {
  tryCatch({
    ref <- Episode$new(x, process_tags = TRUE, fix_links = TRUE, fix_liquid = TRUE)
    ref$unblock()$use_sandpaper()$write(out)
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
  tryCatch(dir_delete(x), 
    error = function(e) {
      cli::cli_alert_warning("Could not delete {.file {x}}")
    })
}


add_experiment_info <- function(episode) {
  # Modify the index to include our magic header
  experiment <- "> **ATTENTION** This is an experimental test of the [{sandpaper}](https://carpentries.github.io/sandpaper-docs) lesson infrastructure
> with automated conversion via [the lesson transition script](https://github.com/data-lessons/lesson-transition/).
>
> If anything seems off, please contact Zhian Kamvar <zkamvar@carpentries.org>
"
  episode$add_md(experiment, 0L)
}

