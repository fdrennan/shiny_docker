#' @export
init_project <- function(local_repo_path,
                         app_dir,
                         repository,
                         branch = "main",
                         app_tag = "develdestroy",
                         randomize_tag = TRUE,
                         build_container = TRUE,
                         destroy = TRUE,
                         toolbox = TRUE) {
  {
    box::use(. / dockerfile)
    box::use(renv)
    box::use(gert)
    box::use(fs)
    box::use(reticulate)
    box::use(cli)
    box::use(glue[glue])
    box::use(readr)
    box::use(.. / utilities / send_email)
    box::use(utils)
  }

  cli$cli_alert_info("Storing {repository} at {local_repo_path}")

  gert$git_clone(
    url = repository,
    path = local_repo_path,
    bare = FALSE,
    branch = branch
  )
  
  if (build_container) app_tag <- paste0(app_tag, "-", round(as.numeric(Sys.time())))

  
  gert$git_branch_create(app_tag, repo=local_repo_path, ref = branch, checkout = TRUE)
  
  app_dir <- file.path(local_repo_path, app_dir)
  cli$cli_alert_info("Building Dockerfile for {app_dir}")

  dockerfile$dockerfile_build(
    from = "ubuntu:jammy",
    workdir = "/root",
    app_dir = app_dir,
    expose = 8000,
    author = "Freddy Drennan",
    email = "fdrennan@ndexr.com",
    files = NULL,
    copy_all = TRUE
  )
  container_clean_name <- glue("cd {app_dir} && docker build -t {app_tag} .")
  if (build_container) {
    system(container_clean_name)
    cli$cli_alert_success(container_clean_name)
  }

  docker_images <- dockerfile$docker_get_images(app_tag)

  if (destroy) {
    cli$cli_alert_info("Deleting images with tag {app_tag}")
    dockerfile$docker_delete_images(app_tag)
  }

  cli$cli_alert_info("Attaching files in {app_dir}")

  
  if (toolbox) {
    cli$cli_alert_info("Using toolbox code to project.")
    fs$dir_copy("~/root/toolbox", file.path(local_repo_path, 'toolbox'), overwrite = TRUE)
  }
  
  
  attachments <- fs$dir_ls(app_dir,
    type = "file",
    invert = TRUE,
    regexp = "^[.]git",
    recurse = TRUE,
    all = TRUE
  )
  if (file.exists("attachments.tar.gz")) file.remove("attachments.tar.gz")

  utils$tar("attachments.tar.gz", attachments)

  {
    box::use(.. / aws / client)
    box::use(.. / aws / s3_create_bucket)
    box::use(purrr)
    s3 <- client$client("s3")
    bucketname <- "ndexrpipelines"
    bucketObjects <- unlist(s3$list_objects(Bucket = bucketname), recursive = TRUE, use.names = TRUE)
    unlist(bucketObjects[names(bucketObjects) == "Contents.Key"])
    buckets <- purrr$map_chr(s3$list_buckets()$Buckets, function(x) x$Name)
    if (!bucketname %in% buckets) {
      s3_create_bucket$s3_create_bucket(s3, bucketname)
    }

    cli$cli_alert_info("Pushing to {bucketname}")

    s3$upload_file(
      Filename = "attachments.tar.gz",
      Bucket = bucketname,
      Key = "attachments.tar.gz",
      ExtraArgs = list(ACL = "public-read")
    )
  }

  subject <- glue(
    "{app_tag} {repository} {app_dir} destroy {destroy}"
  )

  tryCatch(
    {
      send_email$send_email(subject, list(
        docker_images = docker_images,
        get_data_here = glue("https://ndexrpipelines.s3.us-east-2.amazonaws.com/attachments.tar.gz"),
        attachments = fs$path_file(attachments),
        container_clean_name = glue("docker build -t {app_tag} .")
      ))
    },
    error = function(err) {
      send_email$send_email(subject, list(
        docker_images = docker_images,
        attachments = fs$path_file(attachments),
        regexp = regexp,
        container_clean_name = glue("docker build -t {app_tag} .")
      ))
    }
  )

  
  # browser()
  system(glue('cd {local_repo_path} && git add --all'))
  system(glue('cd {local_repo_path} && git commit -m "ndexr update" '))
  # gert$git_add(files = '/tmp/RtmplsfYoC/pvfrygpqghfcmdpcdykp/toolbox', repo = local_repo_path)
  # gert$git_commit_all(repo = local_repo_path, message = 'Saved')
  # gert$git_commit(message = 'All done', repo = local_repo_path)
  
  gert$git_push(repo=local_repo_path, remote='origin')
  cli$cli_alert_success("init_project complete")
  docker_images
}
