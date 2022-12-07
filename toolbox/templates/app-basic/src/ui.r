#' @export
ui <- function() {
  box::use(. / modules / frontend)
  frontend$ui_frontend("frontend")
}
