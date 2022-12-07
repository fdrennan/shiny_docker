# Main App
if (file.exists("/root/.Rprofile")) {
  options(dir_app = "/root/toolbox/templates/app/src")
  options(dir_app_environment = "/root")
} else {
  options(dir_app = "./toolbox/templates/app/src")
  options(dir_app_environment = "~/root")
}
