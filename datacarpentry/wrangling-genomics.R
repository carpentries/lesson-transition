try(dir_delete(to("renv")))
dir_delete(to("episodes", "fig"))
dir_copy(to("episodes", "img"), to("episodes", "fig"))
options(custom.transformation.message = "move figures to correct folder")
