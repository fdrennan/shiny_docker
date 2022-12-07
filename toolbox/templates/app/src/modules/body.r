#' @export
ui_body <- function(...) {
  box::use(shiny[tags])
  tags$body(id = "page-top", ...)
}
