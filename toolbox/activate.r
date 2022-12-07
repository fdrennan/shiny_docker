source("./toolbox/onload/options/default.r")
source("./toolbox/onload/options/onload_renv.r")
source("./toolbox/onload/options/onload_shiny.r")
source("./toolbox/onload/options/onload_tibble.r")
source("./toolbox/onload/options/onload_app.r")
source("./toolbox/onload/options/onload_gert.r")

if (interactive()) {
  source("renv/activate.R")
  source("./toolbox/onload/user.r")
}
