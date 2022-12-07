#' @export
ui_frontend <- function(id) {
  {
    box::use(shiny)
  }

  ns <- shiny$NS(id)

  html$ui_html(
    head$ui_head(
      title = "ndexr template",
      author = "Freddy Drennan",
      description = "just real good R"
    ),
    body$ui_body(
      shiny$withTags(
        div(
          class = "container",
          p("Welcome to ndexr"),
          p("Container Running ", as.character(!interactive())),
          p("You are here", pre(as.character(getwd())))
        )
      ),
      shiny$tags$script(src = "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"),
      shiny$tags$script(src = "https://cdn.startbootstrap.com/sb-forms-latest.js")
    )
  )
}

#' @export
server_frontend <- function(id) {
  {
    box::use(shiny = shiny[withTags, tags])
  }

  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

    }
  )
}
