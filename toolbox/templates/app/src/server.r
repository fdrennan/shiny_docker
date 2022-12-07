#' @export
server <- function(input, output, session) {
  box::use(. / modules / frontend)
  frontend$server_frontend("frontend")
}
