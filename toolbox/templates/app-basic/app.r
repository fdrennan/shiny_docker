renv::activate(getOption("dir_app_environment"))

box::use(shiny)
box::use(cli)

shiny$runApp(appDir = getOption("dir_app"))
