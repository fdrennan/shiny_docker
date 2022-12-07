#' @export
ui_html <- function(...) {
  box::use(shiny[tags])
  tags$html(lang = "en", ...)
}
