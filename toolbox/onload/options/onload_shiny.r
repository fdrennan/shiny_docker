options(
  shiny.port = 8000,
  shiny.host = "0.0.0.0",
  shiny.maxRequestSize = 200,
  shiny.json.digits = 7,
  shiny.suppressMissingContextError = FALSE,
  shiny.table.class = NULL,
  shiny.fullstacktrace = FALSE
)

if (isFALSE(getOption("production"))) {
  message("Using Shiny Development Options")
  options(
    shiny.autoreload = FALSE,
    shiny.reactlog = FALSE,
    shiny.minified = FALSE,
    # shiny.error = utils::recover,
    shiny.deprecation.messages = TRUE,
    shiny.sanitize.errors = FALSE
  )
}
