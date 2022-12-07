#' @export
ui_head <- function(title, author, description) {
  {
    box::use(shiny = shiny[tags])
    box::use(shinyjs)
  }

  getOption("app_dir")
  shiny$addResourcePath(prefix = "www", directoryPath = "./www")

  tags$head(
    shinyjs$useShinyjs(),
    tags$meta(charset = "utf-8"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1, shrink-to-fit=no"),
    tags$title(title),
    tags$meta(name = "author", content = author),
    tags$meta(name = "description", content = description),
    tags$link(rel = "icon", type = "image/png", href = "www/img/ndexrsym.png"),
    tags$script(src = "https://use.fontawesome.com/releases/v6.1.0/js/all.js", crossorigin = "anonymous"),
    tags$link(href = "https://fonts.googleapis.com/css?family=Montserrat:400,700", rel = "stylesheet", type = "text/css"),
    tags$link(href = "https://fonts.googleapis.com/css?family=Roboto+Slab:400,100,300,700", rel = "stylesheet", type = "text/css"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@rc/dist/js.cookie.min.js"),
    shiny$includeScript(path = "./www/scripts/cookies.js"),
    shiny$includeCSS(path = "./www/styles.css", rel = "stylesheet")
  )
}
