#' @export
ui_terminal <- function(id) {
  {
    box::use(shiny = shiny[tags])
    box::use(shinyAce)
  }
  ns <- shiny$NS(id)

  tags$div(
    class = "container",
    tags$div(
      class = "row", style = "height: 300px",
      tags$div(
        class = "col-4",
        shinyAce$aceEditor(
          ns("code"),
          mode = "r",
          theme = "crimson_editor",
          height = "100%",
          autoComplete = "live",
          autoCompleters = "rlang",
          vimKeyBinding = TRUE,
          showLineNumbers = TRUE,
          hotkeys = list(
            runKey = list(
              win = "Ctrl-Enter",
              mac = "CMD-ENTER"
            )
          )
        )
      ),
      tags$div(
        class = "col-8",
        shiny$verbatimTextOutput(ns("codeOutput"))
      )
    )
  )
}

#' @export
server_terminal <- function(id) {
  {
    box::use(shiny = shiny[tags])
    box::use(shinyAce)
    box::use(jsonlite)
  }
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      shinyAce$aceAutocomplete("code")
      tmpFile <- tempfile()

      output$codeOutput <- shiny$renderPrint({
        if (is.null(input)) {
          return("Execute [R] chunks with Ctrl/Cmd-Enter")
        } else {
          input <- shiny$reactiveValuesToList(input)
          input <- jsonlite$toJSON(input, pretty = TRUE)
          return(input)
        }
      })
    }
  )
}
