#' @export
ui_s3 <- function(id = "s3", ns_common_store_user) {
  box::use(shiny)
  box::use(shinyjs)
  box::use(.. / .. / .. / connections / redis)
  box::use(.. / .. / .. / state / setDefault[setDefault])
  ns <- shiny$NS(id)


  redux <- redis$get_state(ns_common_store_user("s3"))

  bucketName <- setDefault(
    redux$bucketName,
    paste0("ndexrapp", sample(1:9, 8, replace = TRUE))
  )

  shiny$wellPanel(
    shiny$textInput(ns("bucketName"), shiny$tags$b("Bucket Name"), bucketName),
    shiny$div(
      class = "d-flex justify-content-between p-2",
      shinyjs$disabled(shiny$actionButton(ns("deleteBucket"), shiny$tags$b("Delete Bucket"), class = "btn btn-sm btn-block btn-danger")),
      shiny$actionButton(ns("makeBucket"), shiny$tags$b("Push to S3"), class = "btn btn-sm btn-block btn-primary")
    )
  )
}

#' @export
server_s3 <- function(id = "s3", ns_common_store_user) {
  box::use(shiny)
  box::use(glue)
  box::use(. / s3)
  box::use(fs)
  box::use(.. / .. / .. / connections / redis)
  box::use(. / client)
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns


      aws_credentials <- shiny$reactive({
        redis$get_state(ns_common_store_user("aws_credentials"))
      })

      files_to_upload <- shiny$reactive({
        c(
          fs$dir_ls("./shared/nginx/", recurse = T, type = "file"),
          fs$dir_ls("./shared/Docker/", recurse = T, type = "file")
        )
      })

      shiny$observeEvent(input$makeBucket, {
        # shiny$req()
        shiny$req(aws_credentials())
        shiny$req(files_to_upload())
        shiny$req(input$bucketName)
        files_to_upload <- files_to_upload()
        tryCatch(
          {
            s3Boto <- client$client("s3", aws_credentials())

            try({
              bucket <- s3Boto$create_bucket(
                Bucket = input$bucketName,
                CreateBucketConfiguration = list(
                  LocationConstraint = aws_credentials()$defaultRegion
                ),
                ACL = "public-read"
              )
            })

            s3$s3_upload_proj(input$bucketName, files_to_upload, aws_credentials = aws_credentials())
            shiny$showNotification(glue$glue("{input$bucketName} created"))
          },
          error = function(err) {
            shiny$showModal(shiny$modalDialog(size = "xl", shiny$tags$pre(shiny$tags$code(as.character(err)))))
          }
        )
      })


      shiny$observe({
        input$makeBucket
        shiny$req(input$bucketName)
        input <- shiny$reactiveValuesToList(input)
        redis$store_state(ns_common_store_user("s3"), input)
      })
    }
  )
}


#' @export
s3_upload_proj <- function(bucketname = "ndexrapp",
                           paths = c(
                             "./nginx/nginx.conf", "./nginx/ec2.nginx.conf",
                             "docker-compose.yaml", "Makefile", ".Renviron"
                           ), aws_credentials) {
  {
    box::use(fs)
    box::use(shiny)
    box::use(.. / .. / .. / modals)
    box::use(. / client)
    box::use(glue[glue])
    box::use(readr)
  }
  s3 <- client$client("s3", aws_credentials)

  files_to_upload <- fs$dir_ls(
    path = "./shared", all = TRUE,
    recurse = T, type = "file"
  )


  shiny$withProgress(
    message = "Uploading files to your S3 bucket",
    detail = "This will take a moment.",
    value = 0,
    {
      for (i in seq_along(files_to_upload)) {
        s3$put_object(
          ACL = "public-read",
          Body = readr$read_file(files_to_upload[i]),
          Bucket = bucketname,
          Key = gsub("./shared/", "", files_to_upload[i])
        )
        shiny$incProgress(1 / length(files_to_upload))
      }
    }
  )
}


# box::use(./aws)
# aws$s3_upload_proj('ndexrapp', './plumber.r')
# aws$s3_upload_proj()
