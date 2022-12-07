#' @export
list_security_groups <- function(aws_credentials = aws_credentials) {
  box::use(purrr)
  box::use(. / client[client])
  aws_credentials
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  security_groups <- ec2$describe_security_groups()
  purrr$map_df(
    security_groups$SecurityGroups, function(sg) {
      data.frame(
        GroupName = sg$GroupName,
        GroupId = sg$GroupId
      )
    }
  )
}

#' @export
manage_security_groups <- function(GroupName = "ndexr-sg",
                                   Description = "Security Group for EC2 Servers",
                                   delete = FALSE,
                                   aws_credentials) {
  # aws_credentials
  box::use(. / client[client])
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  if (delete) {
    return(ec2$delete_security_group(GroupName = GroupName))
  }
  ec2$create_security_group(
    GroupName = GroupName,
    Description = "Security Group by NDEXR"
  )
}

#' @export
security_group_envoke <- function(GroupName = NA, ports = NULL, ips = NULL, aws_credentials) {
  box::use(purrr)
  box::use(. / client[client])
  box::use(. / client[client])
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  grid <- expand.grid(ports, ips)
  grid$id <- 1:nrow(grid)
  aws_credentials
  colnames(grid) <- c("port", "ip", "id")

  purrr$walk(
    split(grid, grid$id),
    ~ ec2$authorize_security_group_ingress(
      GroupName = GroupName,
      IpProtocol = "tcp",
      CidrIp = paste0(.$ip),
      FromPort = as.integer(.$port),
      ToPort = as.integer(.$port)
    )
  )
}

#' @export
ui_security_group <- function(id = "security_group", ns_common_store_user) {
  box::use(shiny)
  box::use(.. / .. / .. / connections / redis)
  box::use(.. / .. / .. / state / setDefault[setDefault])
  ns <- shiny$NS(id)
  redux <- redis$get_state(ns_common_store_user("security_group"))
  GroupName <- setDefault(redux$GroupName, "")
  ports <- setDefault(redux$ports, c(22, 80, 8787, 3838, 61208))
  shiny$wellPanel(
    shiny$textInput(ns("GroupName"), shiny$tags$b("Security Group Name"), GroupName),
    shiny$selectizeInput(ns("ports"), shiny$tags$b("Ports"), c(22, 80, 8787, 3838, 61208, 61209),
      ports,
      options = list(create = TRUE),
      multiple = TRUE
    ),
    shiny$div(
      class = "d-flex justify-content-between p-2",
      shiny$actionButton(ns("deleteSecurityGroup"), shiny$tags$b("Delete Security Group"), class = "btn btn-sm btn-block btn-danger btn-block"),
      shiny$actionButton(ns("makeSecurityGroup"), shiny$tags$b("Create Security Group"), class = "btn btn-sm btn-block btn-primary  btn-block")
    )
  )
}


#' @export
server_security_group <- function(id = "security_group", ns_common_store_user) {
  {
    box::use(shiny)
    box::use(. / instance)
    box::use(. / security_groups)
    box::use(purrr)
    box::use(. / client[client])
    box::use(glue[glue])
    box::use(.. / .. / .. / connections / redis)
    box::use(.. / .. / .. / modals)
  }

  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      aws_credentials <- shiny$reactive({
        redis$get_state(ns_common_store_user("aws_credentials"))
      })

      ec2boto <- shiny$reactive({
        box::use(.. / .. / .. / connections / redis)
        shiny$req(aws_credentials())
        client("ec2", aws_credentials = aws_credentials())
      })

      shiny$observeEvent(input$deleteSecurityGroup, {
        shiny$req(ec2boto())
        shiny$req(input$ports)
        shiny$req(input$deleteSecurityGroup)
        shiny$req(input$GroupName)
        tryCatch(
          {
            shiny$showNotification("Deleting Security Group")
            ec2boto()$delete_security_group(GroupName = input$GroupName)
            shiny$showNotification("Security Group Deleted")
          },
          error = function(err) {
            modals$modal_error(err)
          }
        )
      })


      shiny$observeEvent(input$makeSecurityGroup, {
        securityGroups <- security_groups$list_security_groups(aws_credentials = aws_credentials())

        GroupName <- input$GroupName

        if (isTRUE(GroupName %in% securityGroups$GroupName)) {
          shiny$showNotification(glue("Security groups already exist for {GroupName}"))
          shiny$req(FALSE)
        }

        shiny$showNotification("Creating Security Groups")
        security_groups$manage_security_groups(input$GroupName,
          aws_credentials = aws_credentials()
        )

        purrr$walk(
          input$ports,
          function(port) {
            tryCatch(
              {
                port <- as.numeric(port)
                GroupName <- input$GroupName
                shiny$showNotification(
                  glue("Allowing access on port {port} from anywhere for group {GroupName}")
                )
                security_groups$security_group_envoke(
                  GroupName,
                  ports = port, ips = "0.0.0.0/0",
                  aws_credentials = aws_credentials()
                )
              },
              error = function(err) {
                shiny$showModal(shiny$modalDialog(size = "xl", shiny$tags$pre(as.character(err))))
              }
            )
          }
        )
      })

      shiny$observe({
        shiny$req(input$GroupName)
        shiny$req(input$ports)
        redis$store_state(ns_common_store_user("security_group"), shiny$reactiveValuesToList(input))
      })
    }
  )
}
