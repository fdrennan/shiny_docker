#' @export
server_cookies <- function(id) {
  box::use(shinyjs[js])
  box::use(shiny)
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns
      cookieStored <- shiny$reactive({
        session$sendCustomMessage("cookie-get", list(id = ns("cookie")))
        shiny$req(length(input$cookie) > 0)
      })

      shiny$observe({
        msg <- list(
          name = "logintime",
          value = as.numeric(Sys.time()),
          id = ns("cookie")
        )
        session$sendCustomMessage("cookie-set", msg)
      })

      shiny$observe({
        shiny$req(cookieStored())
        shiny$showNotification(
          "You are already logged in, redirecting you to the console."
        )

        shiny$showNotification("Cookies storing, you can use these to create the next page.")
      })
    }
  )
}
