#' @export
install_awscli <- function(d) {
  # Install AWS CLI, credentials go in /root/.aws
  d$RUN('curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"')
  d$RUN("unzip awscliv2.zip")
  d$RUN("./aws/install")
  d$RUN("rm awscliv2.zip")
}

#' @export
install_r <- function(d) {
  box::use(docker = dockerfiler)
  box::use(glue[glue])
  # Install shit to be able to install shit
  d$RUN("apt-get update")
  d$RUN("apt-get install -y gnupg2")
  d$RUN("apt-get install -y software-properties-common")

  d$ENV("TERM", "xterm-256color")
  d$ENV("DEBIAN_FRONTEND", "noninteractive")
  d$ENV("TZ", "Etc/UTC")
  d$RUN("apt-get install -y tzdata")
  d$RUN("apt-get install -y wget")

  # Tell Ubuntu where to download R from
  # d$RUN("add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian buster-cran40/'")
  d$RUN("wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc")
  d$RUN('add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"')

  libraries <-
    c(
      "vim", "curl", "git-core", "curl", "lsb-release", "libssl-dev", "libgit2-dev", "libcurl4-openssl-dev",
      "libssh2-1-dev", "libsodium-dev", "libxml2-dev", "r-base", "r-base-dev", "dirmngr", "zlib1g-dev",
      "libpq-dev", "libsasl2-dev", "cmake"
    )

  libraries <- paste0(libraries, collapse = " ")

  d$RUN(glue("apt-get install -y --no-install-recommends {libraries}"))

  d$RUN(docker$r(install.packages("renv", dependencies = TRUE)))
  d$RUN(docker$r(install.packages("shiny", dependencies = TRUE)))
  d$RUN(docker$r(install.packages("plumber", dependencies = TRUE)))
}

#' @export
install_python <- function(d) {
  box::use(docker = dockerfiler)
  d$RUN(docker$r(install.packages("reticulate")))
  d$RUN(docker$r(reticulate::install_miniconda(force = TRUE)))
  d$RUN(docker$r(reticulate::py_install("boto3")))
}


#' @export
install_oh_my_zsh <- function(d) {
  d$RUN("apt-get install -y zsh")
  d$RUN('sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"')
}

#' @export
force_no_cache <- function(d) {
  d$ENV("nocache", as.character(as.numeric(Sys.time())))
}

#' @export
renv_activate <- function(d, app_dir, workdir) {{
  box::use(cli)
  box::use(renv)
  box::use(docker = dockerfiler)
}

if (file.exists(file.path(app_dir, "renv.lock"))) {
  cli$cli_alert_info("renv.lock file found in {app_dir}")
  d$COPY("renv.lock", file.path(workdir, "renv.lock"))
  d$RUN(docker$r(renv::activate(getwd())))
  d$RUN(docker$r(renv::restore(getwd())))
} else {
  cli$cli_alert_warning("renv.lock file not found, defaulting to hydrate")
  # d$RUN(docker$r(renv::init(force=TRUE, project = '/root')))
  # d$RUN(docker$r(renv::hydrate(project = '/root')))
  d$RUN(docker$r(renv::consent(provided = TRUE)))
  d$RUN(docker$r(renv::init(bare = FALSE, force = TRUE, project = "/root")))
}}

#' @export
docker_get_images <- function(regex = "*") {
  {
    box::use(purrr)
    box::use(stringr)
    box::use(dplyr)
    box::use(tidyr)
    box::use(snakecase[to_snake_case])
  }

  docker_data <- dplyr$tibble(
    system_output = system("docker image ls", intern = TRUE)
  )

  image_header <- docker_data$system_output[[1]]

  image_df <- purrr$map_dfr(
    c("REPOSITORY", "TAG", "IMAGE ID", "CREATED", "SIZE"),
    function(x) {
      # browser()

      split_start <- stringr$str_locate(image_header, x)[[1]]
      image_df <- dplyr$tibble(split_start = split_start, title = to_snake_case(x))
    }
  )

  image_df <- dplyr$mutate(image_df,
    split_end = dplyr$lead(split_start) - 1,
    split_end = ifelse(is.na(split_end), nchar(image_header), split_end)
  )

  image_df <- dplyr$inner_join(docker_data, image_df, by = character())
  image_df <- dplyr$transmute(image_df, title, text = unlist(stringr$str_sub(system_output, split_start, split_end)))
  image_df <- dplyr$mutate(image_df, text = stringr$str_trim(text))
  image_df <- dplyr$arrange(image_df, title)
  image_df <- dplyr$mutate(image_df, group_id = title)
  image_df <- dplyr$mutate(image_df, row_id = paste0(title, "-", dplyr$row_number()))
  image_df <- tidyr$pivot_wider(image_df, values_from = text, names_from = title, id_cols = row_id)
  image_df <- tidyr$separate(image_df, row_id, c("title", "id"), "-")
  image_df <- purrr$map_dfc(
    split(image_df, image_df$title),
    function(x) {
      x[, unique(x$title)]
    }
  )
  image_df <- dplyr$filter(image_df, stringr$str_detect(repository, regex))
  image_df
}

#' @export
docker_delete_images <- function(regex_detect = "root[-]ndexr") {
  {
    box::use(dplyr)
    box::use(. / dockerfile)
    box::use(stringr)
    box::use(glue[glue])
    box::use(purrr)
    box::use(cli)
  }
  docker_images <- dockerfile$docker_get_images(regex_detect)
  docker_images |> print(n = 10)

  if (nrow(docker_images) > 0) {
    command_to_remove_containers <- glue("docker image rm {docker_images$image_id}")
    purrr$walk(command_to_remove_containers, function(x) system(x))
  }
  cli$cli_alert_info("{regex_detect} purged")
}

#' @export
dockerfile_build <- function(from = "ubuntu:jammy",
                             workdir = "/root",
                             # app_dir = getwd(),
                             app_dir = getwd(),
                             expose = 8000,
                             author = "Freddy Drennan",
                             email = "fdrennan@ndexr.com",
                             files = NULL,
                             copy_all = TRUE) {
  {
    box::use(cli)
    box::use(docker = dockerfiler)
    box::use(readr)
    box::use(. / dockerfile)
    box::use(purrr)
    box::use(renv)
  }

  d <- docker$Dockerfile$new(from)
  cli$cli_alert_info("MAINTAINER {author} {email}")
  d$MAINTAINER(author, email)
  d$WORKDIR("/ndexr/install")
  dockerfile$install_r(d)
  dockerfile$install_python(d)
  dockerfile$install_awscli(d)
  dockerfile$install_oh_my_zsh(d)

  cli$cli_alert_info("WORKDIR {workdir}")
  d$WORKDIR(workdir)

  dockerfile$force_no_cache(d)

  if (!is.null(files)) {
    purrr$walk(split(files, 1:nrow(files)), function(x) {
      cli$cli_alert_info("Copy {x$from} -> {x$to}")
      d$COPY(x$from, x$to)
    })
  }

  if (copy_all) {
    cli$cli_alert_warning("Storing everything in app dir in container, this may result in large size.")
    d$COPY(".", workdir)
  }

  dockerfile$renv_activate(d, app_dir, workdir)


  if (!is.null(expose)) {
    purrr$walk(expose, d$EXPOSE)
  }

  readr$write_file(paste0(d$Dockerfile, collapse = "\n"), file.path(app_dir, "Dockerfile"))
}
