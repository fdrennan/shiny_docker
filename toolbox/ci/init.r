#' @export
build_pipeline <- function(repository = "git@gitlab.com:fdrennan/root.git",
                           app_dir = "toolbox/templates/app-basic",
                           app_tag = "develdestroy",
                           branch = "main",
                           destroy = FALSE,
                           seed = 4325,
                           toolbox = FALSE,
                           build_container = FALSE,
                           randomize_tag = TRUE) {
  {
    box::use(. / build)
    box::use(. / dockerfile)
    box::use(.. / utilities / send_email)
  }

  if (is.numeric(seed)) set.seed(seed)

  project_dir <- file.path(tempdir(), paste0(sample(letters, 20, replace = TRUE), collapse = ""))

  build$init_project(
    repository = repository,
    app_dir = app_dir,
    app_tag = app_tag,
    randomize_tag = randomize_tag,
    local_repo_path = project_dir,
    build_container = build_container,
    destroy = FALSE,
    toolbox = toolbox,
    branch = branch
  )
}

if (FALSE) {
  rstudioapi::restartSession()

  box::use(. / init[build_pipeline])

  results <- build_pipeline(
    app_dir = "./.",
    repository = "git@gitlab.com:fdrennan/root.git",
    seed = NULL,
    toolbox = TRUE,
    destroy = FALSE,
    branch = "main"
  )

  results <- build_pipeline(
    app_dir = "./.",
    repository = "git@github.com:fdrennan/bmrn-test.git",
    seed = NULL,
    destroy = FALSE,
    branch = "ndexr-27",
    toolbox = TRUE,
    build_container = FALSE,
    app_tag = "ndexttesting1"
  )

  results <- build_pipeline(
    app_dir = "./.",
    repository = "git@github.com:fdrennan/shiny_docker.git",
    seed = NULL,
    destroy = FALSE,
    branch = "master",
    toolbox = TRUE,
    build_container = TRUE,
    app_tag = "ndexttest002",
    randomize_tag = TRUE
  )
}
