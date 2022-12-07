#' @export
ui_current_servers <- function(id = "current_servers") {
  box::use(shiny)
  box::use(shinyWidgets)
  ns <- shiny$NS(id)
  shiny$fluidRow(
    shiny$div(
      class = "col-12 p-1 border-bottom",
      shiny$div(
        class = "d-flex justify-content-end align-items-center",
        shiny$actionButton(
          ns("pullServers"),
          shiny$icon("refresh"),
          class = "btn btn-sm btn-secondary btn-block"
        )
      ),
      shiny$fluidRow(
        class = "p-1",
        id = ns("serverPanel")
      )
    )
  )
}



#' @export
server_current_servers <- function(id = "current_servers", ns_common_store_user) {
  box::use(shiny)
  box::use(. / ec2)
  box::use(dplyr)
  box::use(glue[glue])
  box::use(uuid)
  box::use(. / instance)
  box::use(.. / .. / .. / connections / redis)
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns
      shiny$observeEvent(input$pullServers, {
        aws_credentials <- redis$get_state(ns_common_store_user("aws_credentials"))
        instances <- instance$describe_instances(aws_credentials = aws_credentials)
        instances <-
          instances |>
          dplyr$filter(state != "terminated") |>
          dplyr$select(state, PublicIpAddress, KeyName, InstanceType, PublicDnsName, InstanceId)
        InstanceId <- instances$InstanceId


        shiny$removeUI(paste0("#", ns("servers")))
        shiny$insertUI(
          selector = paste0("#", ns("serverPanel")),
          where = "beforeEnd",
          ui = shiny$column(12, id = ns("servers"))
        )
        uuid <- uuid$UUIDgenerate()
        for (id in InstanceId) {
          # TODO Hacked by creating new namespace i believe since it's not working
          ui_id <- paste0(uuid, id)
          shiny$removeUI(
            selector = paste0("#", ui_id)
          )

          remove_shiny_inputs <- function(id, .input) {
            box::use(glue[glue])
            lapply(grep(id, names(.input), value = TRUE), function(i) {
              .subset2(.input, "impl")$.values$remove(i)
              is_removed <- i %in% .subset2(.input, "impl")$.values$keys()
              if (is_removed) print("removed") else "that didnt get removed"
            })
          }

          remove_shiny_inputs(ns(ui_id), input)

          shiny$insertUI(
            selector = paste0("#", ns("servers")),
            where = "beforeEnd",
            ec2$ui_ec2(ns(ui_id), id)
          )

          out <- ec2$server_ec2(ui_id, id, instances, aws_credentials = aws_credentials)
          out()
        }
      })
    }
  )
}
