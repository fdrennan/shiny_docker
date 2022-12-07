#' @export
messaging_email_send <- function() {
  box::use(. / client)
  client_ses <- client$client(
    "ses",
    list(
      awsAccess = Sys.getenv("AWS_ACCESS"),
      awsSecret = Sys.getenv("AWS_SECRET"),
      awsRegion = Sys.getenv("AWS_REGION")
    )
  )



  client_ses$meta$client$publish(
    PhoneNumber = "+12549318313",
    Message = "Good"
  )

  html_data <-
    "Subject: Subscription
MIME-Version: 1.0
Content-Type: text/HTML

<!DOCTYPE html>
    <html>
    <head>
        <style>
            h1   {color: #333;}
            p    {color: #555;}
        </style>
    </head>
    <body>
        <h1>Hey!</h1>
        <p>You've createed an account with ndexr.com.</p>
    </body>
</html>
"

  response <- client_ses$send_raw_email(
    Source = "drennanfreddy@gmail.com",
    Destinations = list("fdrennan@gmail.com"),
    RawMessage = list(
      Data = charToRaw(html_data)
    )
  )
}


#' @export
messaging_text_send <- function() {
  box::use(. / client)
  client_sns <- client$client(
    "pinpoint",
    list(
      awsAccess = Sys.getenv("AWS_ACCESS"),
      awsSecret = Sys.getenv("AWS_SECRET"),
      awsRegion = Sys.getenv("AWS_REGION")
    )
  )

  client_sns$send_messages(
    ApplicationId = "8a13cdea0ce84aeeae8e4f6de6155a2b",
    MessageRequest = list(
      Addresses = list(
        destination_number = list(ChannelType = "SMS")
      ),
      MessageConfiguration = list(
        SMSMessage = list(
          Body = "Hello",
          MessageType = "TRANSACTIONAL",
          OriginationNumber = "+18449183457"
        )
      )
    )
  )
}
