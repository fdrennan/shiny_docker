#' @export
send_email <- function(subject=NULL, data_list=NULL, attachments=NULL) {
  {
    box::use(gmailr)
    box::use(shiny)
    box::use(readr)
    box::use(jsonlite)
    box::use(glue[glue])
    box::use(fs)
    box::use(utils)
    box::use(cli)
  }

  gmailr$gm_auth_configure(appname = "ndexrapp", path = "~/.credentials.json")
  gmailr$gm_auth(email = "fdrennan@ndexr.com", path = "~/.credentials.json")

  test_email <-
    gmailr$gm_mime() |>
    gmailr$gm_to("fdrennan@ndexr.com") |>
    gmailr$gm_from("fdrennan@ndexr.com") |>
    gmailr$gm_subject(subject) |>
    gmailr$gm_html_body(
      as.character(
        shiny$tags$p(
          shiny$tags$pre(
            jsonlite$toJSON(data_list, pretty = TRUE)
          )
        )
      )
    )

  
  if (!is.null(attachments)) {
    for (attachment in attachments) {
      cli$cli_alert_info('Attaching {attachment}')
      test_email <- gmailr$gm_attach_file(test_email, filename = attachment, content_type = 'application/zip')
    }
  }
  
  
  gmailr$gm_send_message(test_email)
}

