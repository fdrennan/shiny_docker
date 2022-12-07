#' @export
aws_cost_get <- function(from = NA, to = NA, aws_credentials) {
  box::use(lubridate)
  box::use(. / client)
  box::use(purrr)
  if (any(is.na(from), is.na(to))) {
    from <- as.character(lubridate$floor_date(Sys.Date(), unit = "month"))
    to <- as.character(lubridate$ceiling_date(Sys.Date(), unit = "month"))
  } else {
    from <- as.character(from)
    to <- as.character(to)
  }

  costs <- client$client("ce", aws_credentials = aws_credentials)

  results <- costs$get_cost_and_usage(
    TimePeriod = list(
      Start = from,
      End = to
    ),
    Granularity = "DAILY",
    Metrics = list("UnblendedCost", "UsageQuantity", "BlendedCost")
  )


  purrr$map_df(
    results$ResultsByTime,
    function(x) {
      data.frame(
        start = x$TimePeriod$Start,
        unblended_cost = as.numeric(x$Total$UnblendedCost$Amount),
        blended_cost = as.numeric(x$Total$BlendedCost$Amount),
        usage_quantity = as.numeric(x$Total$UsageQuantity$Amount)
      )
    }
  )
}

#' @export
ui_aws_costs <- function(id = "aws_costs") {
  box::use(shiny)
  ns <- shiny$NS(id)
  shiny$fluidRow(
    shiny$column(12,
      class = "p-1",
      shiny$div(
        class = "d-flex justify-content-end align-items-center",
        shiny$actionButton(
          ns("pullCosts"),
          shiny$icon("refresh"),
          class = "btn btn-sm btn-secondary btn-block"
        )
      ),
      shiny$plotOutput(ns("ui"), width = "100%")
    )
  )
}

#' @export
server_aws_costs <- function(id = "aws_costs", ns_common_store_user) {
  box::use(shiny)
  box::use(ggplot2)
  box::use(. / costs)
  box::use(.. / .. / .. / connections / redis)
  box::use(lubridate)
  box::use(scales)
  box::use(ggthemes)
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      aws_costs <- shiny$observeEvent(input$pullCosts, {
        aws_credentials <- redis$get_state(ns_common_store_user("aws_credentials"))
        try({
          aws_costs <- costs$aws_cost_get(aws_credentials = aws_credentials)

          output$ui <- shiny$renderPlot({
            shiny$req(aws_costs)
            # aws_costs <- readr::read_rds('aws_costs.rda')

            ggplot2$ggplot(aws_costs, ggplot2$aes(x = lubridate$day(start), y = blended_cost)) +
              ggplot2$geom_col() +
              ggplot2$xlab(label = "Day of Month") +
              ggplot2$ylab(label = "US Dollar") +
              ggplot2$scale_y_continuous(labels = scales$dollar_format()) +
              ggplot2$ggtitle(
                paste0(month.name[lubridate$month(Sys.time())], " spend to date - ", paste0("$", round(sum(aws_costs$blended_cost), 2)))
              ) +
              ggthemes$theme_solarized(
                light = FALSE,
                base_size = 18
              )
          })
        })
      })
    }
  )
}
