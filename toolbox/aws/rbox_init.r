#' @export
ui_rbox_init <- function(id = "rbox_init", ns_common_store_user) {
  box::use(shiny)
  box::use(.. / .. / .. / connections / redis)
  box::use(.. / .. / .. / state / setDefault[setDefault])
  ns <- shiny$NS(id)


  redux <- redis$get_state(ns_common_store_user("rbox_init"))
  ImageId <- setDefault(redux$ImageId, "ami-097a2df4ac947655f")
  InstanceType <- setDefault(redux$InstanceType, "t2.medium")
  InstanceStorage <- setDefault(redux$InstanceStorage, 15)
  ns <- shiny$NS(id)

  smash <- function(a, b) {
    sort(unique(append(a, b)))
  }

  shiny$fluidRow(
    shiny$column(
      12,
      shiny$wellPanel(
        shiny$selectizeInput(
          ns("ImageId"),
          shiny$tags$b("Amazon Machine Image (AMI)"),
          smash(c("Ubuntu 22.04: jammy" = "ami-097a2df4ac947655f"), ImageId),
          ImageId,
          options = list(create = TRUE),
          multiple = FALSE
        ),
        shiny$selectizeInput(
          ns("InstanceType"), shiny$tags$b("Instance Type"),
          smash(c("t2.nano", "t2.micro", "t2.medium", "t2.large", "t2.xlarge"), InstanceType),
          InstanceType,
          options = list(create = TRUE)
        ),
        shiny$selectizeInput(
          ns("InstanceStorage"), shiny$tags$b("Disk Space (gb)"),
          smash(c(10, 15, 30), InstanceStorage),
          options = list(create = TRUE),
          multiple = FALSE
        ),
        shiny$div(
          class = "d-flex justify-content-end p-2",
          shiny$actionButton(
            ns("createServer"),
            shiny$tags$b("Create Server"),
            class = "btn btn-sm btn-block btn-primary"
          )
        )
      )
    )
  )
}



#' @export
server_rbox_init <- function(id = "rbox_init", credentials, ns_common_store_user) {
  {
    box::use(shiny)
    box::use(. / security_groups)
    box::use(. / instance)
    box::use(readr[read_file])
    box::use(uuid)
    box::use(.. / .. / .. / connections / postgres)
    box::use(.. / .. / .. / connections / redis)
    box::use(.. / .. / .. / state / setDefault[setDefault])
    box::use(stringr)
  }
  ns <- shiny$NS(id)


  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      shiny$observeEvent(input$createServer, {
        shiny$showNotification("Building your R box")
        redux_s3 <- redis$get_state(ns_common_store_user("s3"))
        redux_security_groups <- redis$get_state(ns_common_store_user("security_group"))
        redux_key_file <- redis$get_state(ns_common_store_user("key_file"))
        redux_aws_credentials <- redis$get_state(ns_common_store_user("aws_credentials"))
        GroupName <- redux_security_groups$GroupName
        KeyName <- redux_key_file$KeyName
        user <- credentials$user
        sg <- security_groups$list_security_groups(aws_credentials = redux_aws_credentials)
        GroupId <- sg[sg$GroupName == GroupName, ]$GroupId
        ImageId <- input$ImageId
        InstanceType <- input$InstanceType
        InstanceStorage <- input$InstanceStorage
        tryCatch(
          {
            user_data_path <- "user_data.sh"

            input_data <- gsub("BucketName", redux_s3$bucketName, read_file(user_data_path))

            # input_data <-
            instance_data <- instance$create_instance(
              ImageId = ImageId,
              InstanceType = InstanceType,
              InstanceStorage = as.integer(InstanceStorage),
              user_data = input_data,
              GroupId = GroupId,
              KeyName = KeyName,
              aws_credentials = redux_aws_credentials
            )
            LaunchTime <- as.character(instance_data$LaunchTime)

            server_launch <- data.frame(
              LaunchTime = LaunchTime,
              user = user,
              ImageId = ImageId,
              uuid = uuid$UUIDgenerate(),
              status = "start"
            )

            postgres$table_create_or_upsert(
              data = server_launch, where_cols = "uuid"
            )
            redis$store_state(ns_common_store_user("rbox_init"), shiny$reactiveValuesToList(input))
            shiny$showNotification("Server is starting")
            instance_data
          },
          error = function(err) {
            shiny$showModal(shiny$modalDialog(size = "xl", shiny$tags$pre(shiny$tags$code(as.character(err)))))
            shiny$req(FALSE)
          }
        )
      })
    }
  )
}
