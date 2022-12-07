box::use(httr)

httr$oauth_endpoints("google")

# 2. Register an application at https://cloud.google.com/console#/project
#    Replace key and secret below.
myapp <- httr$oauth_app("google",
  key = "736107328181-smtj77h7t2g4ldf5b84m9ljsr8ck7k5h.apps.googleusercontent.com",
  secret = "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",
  redirect_uri = "192.168.0.68:8787"
)


google_token <- httr$oauth2.0_token(httr$oauth_endpoints("google"), myapp,
  scope = "https://www.googleapis.com/auth/userinfo.profile"
)

# 4. Use API
req <- GET(
  "https://www.googleapis.com/oauth2/v1/userinfo",
  config(token = google_token)
)
stop_for_status(req)
content(req)
