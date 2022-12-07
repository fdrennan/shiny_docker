#' @export
ui_key_file <- function(id = "key_file", ns_common_store_user) {
  box::use(shiny)
  ns <- shiny$NS(id)

  box::use(.. / .. / .. / connections / redis)
  box::use(.. / .. / .. / state / setDefault[setDefault])
  redux <- redis$get_state(ns_common_store_user("key_file"))
  KeyName <- setDefault(redux$KeyName, "")

  shiny$fluidRow(
    shiny$column(
      12,
      shiny$textInput(ns("KeyName"), "PEM Key Name", KeyName),
      shiny$div(
        class = "d-flex justify-content-between p-2",
        shiny$actionButton(ns("deleteKeyPair"), shiny$tags$b("Delete Key Pair"), class = "btn btn-sm btn-block btn-danger"),
        shiny$actionButton(ns("makeKeyPair"), shiny$tags$b("Create Key Pair"), class = "btn btn-sm btn-block btn-primary")
      )
    )
  )
}

#' @export
server_key_file <- function(id = "key_file", ns_common_store_user) {
  {
    box::use(shiny)
    box::use(. / client[client])
    box::use(. / key_pairs)
    box::use(glue)
    box::use(utils)
    box::use(.. / .. / .. / connections / redis)
  }

  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      aws_credentials <- shiny$reactive({
        redis$get_state(ns_common_store_user("aws_credentials"))
      })

      ec2boto <- shiny$reactive({
        shiny$req(aws_credentials())
        client("ec2", aws_credentials = aws_credentials())
      })



      shiny$observeEvent(input$makeKeyPair, {
        KeyName <- input$KeyName
        fileName <- paste0(KeyName, ".pem")
        if (isFALSE(KeyName %in% key_pairs$list_key_pair(aws_credentials = aws_credentials()))) {
          shiny$showNotification("Creating Key Pair")
          key_file <- key_pairs$manage_key_pair(KeyName, aws_credentials = aws_credentials())
          shiny$showModal(shiny$modalDialog(size = "xl", {
            shiny$fluidRow(
              shiny$column(
                12,
                shiny$tags$p(
                  shiny$tags$b("Download this file to ssh into your server."),
                  shiny$tags$em("You will have to create another keyfile if lost.")
                ),
                shiny$tags$p(
                  "Change access to the key in order to run ssh or autossh",
                  shiny$tags$pre(
                    shiny$tags$code(glue$glue("sudo chmod 400 {fileName}"))
                  )
                ),
                shiny$downloadButton(ns("downloadData"), "Download Key File")
              )
            )
          }))
        } else {
          shiny$showNotification("Key Pair already exists.")
        }

        output$downloadData <- shiny$downloadHandler(
          contentType = "application/x-x509-ca-cert",
          filename = function() {
            fileName
          },
          content = function(file) {
            write(key_file, file)
          }
        )
      })


      shiny$observeEvent(
        input$deleteKeyPair,
        {
          tryCatch(
            {
              ec2boto()$delete_key_pair(KeyName = input$KeyName)
              shiny$showNotification("Key pair deleted")
            },
            error = function(err) {
              shiny$showModal(shiny$modalDialog(size = "xl", shiny$tags$pre(shiny$tags$code(as.character(err)))))
            }
          )

          tryCatch(
            {
              file.remove(glue$glue("{input$KeyName}.pem"))
            },
            error = function(err) {
              shiny$showModal(shiny$modalDialog(size = "xl", shiny$tags$pre(shiny$tags$code(as.character(err)))))
            }
          )
        }
      )

      shiny$observe({
        shiny$req(input$KeyName)
        input <- shiny$reactiveValuesToList(input)
        redis$store_state(ns_common_store_user("key_file"), input)
      })
    }
  )
}
