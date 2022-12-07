#' @export
ui_ec2 <- function(id = "ec2", InstanceId) {
  box::use(shiny)
  box::use(shinyjs)
  ns <- shiny$NS(id)


  {
    startButton <- shiny$actionButton(ns("start"), "Start", class = "btn btn-sm btn-block btn-primary ")
    stopButton <- shiny$actionButton(ns("stop"), "Stop", class = "btn btn-sm btn-block btn-warning")
    terminateButton <- shiny$actionButton(ns("terminate"), "Terminate", class = "btn btn-sm btn-block btn-danger")
  }
  {
    typeButton <- shiny$selectizeInput(ns("instanceType"), "Instance Type",
      c("t2.nano", "t2.micro", "t2.medium", "t2.large", "t2.xlarge"), "",
      multiple = FALSE
    )
    modifyButton <- shiny$actionButton(ns("modify"), "Modify", class = "btn btn-sm btn-block btn-secondary")
  }

  if (InstanceId == "i-0c1bddf859914e6bf") {
    # startButton <- shinyjs$disabled(startButton)
    # stopButton <- shinyjs$disabled(stopButton)
    terminateButton <- shinyjs$disabled(terminateButton)
    # typeButton <- shinyjs$disabled(typeButton)
    # modifyButton <- shinyjs$disabled(modifyButton)
  }

  shiny$div(
    class = "container border my-2 p-3",
    shiny$fluidRow(
      shiny$column(
        12,
        # shiny$tags$h6("General Information", class = "display-6"),
        shiny$uiOutput(ns("instanceTable")),
        shiny$fluidRow(
          shiny$tags$h6("State Management", class = "display-6"),
          shiny$div(
            class = "col-md-7 border-end p-2",
            shiny$wellPanel(typeButton, modifyButton)
          ),
          shiny$div(
            class = "col-md-3 p-2",
            shiny$wellPanel(
              terminateButton, stopButton, startButton
            )
          )
        )
      ),
      shiny$column(
        12,
        shiny$uiOutput(ns("frontpage"))
      )
    )
  )
}

#' @export
server_ec2 <- function(id = "ec2", InstanceId, instances, aws_credentials) {
  box::use(shiny)
  box::use(glue)
  box::use(dplyr)
  box::use(. / client[client])
  box::use(. / instance)
  box::use(jsonlite)
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      instance <- shiny$reactive({
        instances <- instances[instances$InstanceId == InstanceId, ]
      })


      shiny$observeEvent(instance(), {
        output$frontpage <- shiny$renderUI({
          publicIpAddress <- instance()$publicIpAddress
          shiny$fluidRow(
            shiny$column(12, shiny$tags$a(href = publicIpAddress, publicIpAddress))
          )
        })
        output$instanceTable <- shiny$renderUI({
          shiny$req(instance())
          instance <- instance()
          #
          shiny$tags$div(
            shiny$tags$ul(
              shiny$tags$li(
                shiny$tags$a(
                  target = "_blank",
                  href = paste0("http://", instance$PublicIpAddress),
                  shiny$tags$h4(
                    paste0("Public IP: ", instance$PublicIpAddress)
                  )
                )
              ),
              shiny$tags$li(
                shiny$tags$a(target = "_blank", href = paste0("http://", instance$PublicIpAddress, ":8787"), "RStudio Server")
              ),
              shiny$tags$li(
                shiny$tags$a(target = "_blank", href = paste0("http://", instance$PublicIpAddress, ":3838"), "Shiny Server")
              ),
              shiny$tags$li(
                shiny$tags$a(target = "_blank", href = paste0("http://", instance$PublicIpAddress, ":61208"), "Glances")
              ),
              shiny$tags$li(
                shiny$p(
                  "Use the following command to access your server.",
                  shiny$pre(
                    glue$glue("ssh -i \"~/{instance$KeyName}.pem\" ubuntu@{instance$PublicDnsName}")
                  )
                )
              )
            )
          )
        })
      })

      shiny$observeEvent(input$terminate, {
        tryCatch(
          {
            shiny$showNotification("Terminating instance")
            ec2$terminate_instances(InstanceIds = list(InstanceId))
            shiny$showNotification(shiny$p(shiny$icon("fire"), " wrekd"))
          },
          error = function(err) {
            shiny$showNotification(shiny$tags$pre(as.character(err)))
          }
        )
      })

      shiny$observeEvent(input$modify, {
        resp <- ec2$modify_instance_attribute(
          InstanceId = InstanceId,
          Attribute = "instanceType",
          Value = input$instanceType
        )
      })

      shiny$observeEvent(input$stop, {
        shiny$showNotification("Stopping instance")
        ec2$stop_instances(InstanceIds = list(InstanceId))
        shiny$showNotification(shiny$p(
          shiny::icon("hand-peace"), "booped harder"
        ))
      })

      shiny$observeEvent(input$start, {
        tryCatch(
          {
            shiny$showNotification("Starting instance")
            ec2$start_instances(InstanceIds = list(InstanceId))
            shiny$showNotification(shiny$p(
              shiny::icon("hand-peace"), "booped"
            ))
          },
          error = function(err) {
            shiny$showNotification(shiny$p(
              shiny::icon("face-grin-beam-sweat"), " - probably just need to wait unless you're trying to start a terminated instance"
            ))
          }
        )
      })

      instance
    }
  )
}




#' @export
ec2_instance_create <- function(ImageId = "ami-097a2df4ac947655f",
                                InstanceType = "t2.medium",
                                min = 1,
                                max = 1,
                                KeyName = Sys.getenv("AWS_PEM"),
                                SecurityGroupId = Sys.getenv("AWS_SECURITY_GROUP"),
                                InstanceStorage = 10,
                                DeviceName = "/dev/sda1",
                                user_data = NA,
                                aws_credentials) {
  # box::use(paws[ec2])
  box::use(. / client)
  box::use(readr[read_file])
  box::use(. / state / updateState[updateState])
  box::use(base64[encode])
  box::use(utils[browseURL])
  box::use(. / s3)
  try(aws$ec2_instance_destroy(aws_credentials = aws_credentials))
  s3$s3_upload_proj(aws_credentials = aws_credentials)
  base_64_user_data <- read_file(encode("./shell/install_docker_ec2.sh"))
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  response <-
    ec2$run_instances(
      ImageId = ImageId,
      InstanceType = InstanceType,
      MinCount = as.integer(min),
      MaxCount = as.integer(max),
      UserData = base_64_user_data,
      KeyName = KeyName,
      SecurityGroupIds = list(SecurityGroupId),
      BlockDeviceMappings = list(
        list(
          Ebs = list(
            VolumeSize = as.integer(InstanceStorage)
          ),
          DeviceName = DeviceName
        )
      )
    )
  instanceData <- list(response$Instances[[1]])
  InstanceId <- response$Instances[[1]]$InstanceId
  names(instanceData) <- InstanceId
  updateState(instanceData, "aws-ec2")
  # remote_public_ip <- getOption("domain")
  sleep_seconds <- 10
  #

  ready_for_association <- FALSE
  while (isFALSE(ready_for_association)) {
    ready_for_association <- tryCatch(
      "running" == ec2$describe_instance_status(InstanceId)[[1]][[1]]$InstanceState$Name,
      error = function(err) {
        print(err)
        Sys.sleep(1)
        FALSE
      }
    )
  }
  ec2$associate_address(
    InstanceId = InstanceId,
    PublicIp = getOption("ec2.nginx.conf")
  )
  system("pkill chrome")
  browseURL("https://us-east-2.console.aws.amazon.com/ec2/")
  browseURL(getOption("domain"))
  response
}

#' @export
ec2_instance_destroy <- function() {
  box::use(. / connections / storr)
  box::use(paws[ec2])
  ec2 <- ec2()
  con <- storr$connection_storr()
  ids <- con$get("aws-ec2")
  lapply(ids, function(x) {
    try(ec2$terminate_instances(x$InstanceId))
  })
  con$del("aws-ec2")
}

#' @export
ec2_instance_stop <- function() {
  box::use(. / connections / storr)
  box::use(paws[ec2])
  client <- box::use(. / aws / app / box / client)
  ec2 <- client$client("ec2")
  con <- storr$connection_storr()
  ids <- con$get("aws-ec2")
  lapply(ids, function(x) {
    try(ec2$stop_instances(x$InstanceId))
  })
}

#' @export
ec2_instance_start <- function() {
  box::use(. / connections / storr)
  box::use(paws[ec2])
  box::use(. / aws / app / box / client)
  ec2 <- client$client("ec2")
  con <- storr$connection_storr()
  ids <- con$get("aws-ec2")
  lapply(ids, function(x) {
    try(ec2$start_instances(x$InstanceId))
  })
}
