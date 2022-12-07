#' @export
ndexr_directory_review <- function() {
  {
    box::use(dplyr)
    box::use(fs)
    box::use(stringr)
    box::use(cli)
    box::use(shiny)
    box::use(markdown)
  }

  all_files <- fs::dir_info(".", recurse = T, regexp = "[.]r$")

  all_files <- dplyr$filter(all_files, !stringr$str_detect(path, "renv"))

  all_files <-
    dplyr$transmute(all_files,
      path = path,
      minutes_ago = difftime(Sys.time(), modification_time, units = "mins"),
      hours_ago = minutes_ago / 60
    )
  all_files <- dplyr$arrange(all_files, minutes_ago)
  all_files <- dplyr$rowwise(all_files)
  all_files <- dplyr$mutate(all_files, n_lines = length(readLines(path)))
  all_files <- dplyr$mutate(all_files, line_limit = ifelse(n_lines < 65, "good", "decrease file length"))

  # fs$path_dir(all_files)
  print(all_files)
  # Number of directories touched
  # Number of lines in each file
  # File line widths
}

#' @export
ndexr_directory_style <- function() {
  {
    box::use(styler)
  }

  styler$style_dir("./toolbox/templates/app")
}


ndexr_directory_review()

if (interactive()) {
  ndexr_template_app <- function() rstudioapi::restartSession("source('./toolbox/templates/app/app.r')")
} else {
  ndexr_template_app <- function() source("./toolbox/templates/app/app.r")
}
