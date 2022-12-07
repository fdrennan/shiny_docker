
#' @export
ui_aws_credentials <- function(id = "aws_credentials", ns_common_store_user) {
  {
    box::use(shiny)
    box::use(.. / .. / .. / state / setDefault[setDefault])
    box::use(.. / .. / .. / connections / redis)
  }
  ns <- shiny$NS(id)
  aws_credentials <- redis$get_state(ns_common_store_user("aws_credentials"))

  awsAccess <- setDefault(aws_credentials$awsAccess, "")
  awsSecret <- setDefault(aws_credentials$awsSecret, "")
  defaultRegion <- setDefault(aws_credentials$defaultRegion, "")
  shiny$fluidRow(
    shiny$column(
      12,
      shiny$wellPanel(
        shiny$div(
          class = "d-flex justify-content-end",
          shiny$tags$a(
            href = "https://console.aws.amazon.com/iam/home",
            target = "_blank", "Create AWS Credentials with IAM"
          )
        ),
        shiny$passwordInput(
          ns("awsAccess"), shiny$tags$b("AWS Access Key ID"), awsAccess
        ),
        shiny$passwordInput(
          ns("awsSecret"), shiny$tags$b("AWS Secret Access Key"), awsSecret
        ),
        shiny$textInput(
          ns("defaultRegion"), shiny$tags$b("Default region name"), defaultRegion
        ),
        shiny$div(
          class = "d-flex justify-content-end p-2",
          shiny$actionButton(
            ns("update"), shiny$tags$b("Update"),
            class = "btn btn-sm btn-block btn-primary "
          )
        )
      )
    )
  )
}

#' @export
server_aws_credentials <- function(id = "aws_credentials", credentials, ns_common_store_user) {
  {
    box::use(shiny)
    box::use(.. / .. / .. / connections / redis)
    box::use(shiny)
    box::use(. / client)
    box::use(stringr)
  }
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      shiny$observeEvent(input$update, {
        input <- shiny$reactiveValuesToList(input)
        input <- lapply(input, function(x) gsub(" ", "", x))
        redis$store_state(ns_common_store_user("aws_credentials"), input)
        shiny$showNotification("Credentials Updated")
        input
      })
    }
  )
}
