FROM ubuntu:jammy
MAINTAINER Freddy Drennan <fdrennan@ndexr.com>
WORKDIR /ndexr/install
RUN apt-get update
RUN apt-get install -y gnupg2
RUN apt-get install -y software-properties-common
ENV "TERM"="xterm-256color"
ENV "DEBIAN_FRONTEND"="noninteractive"
ENV "TZ"="Etc/UTC"
RUN apt-get install -y tzdata
RUN apt-get install -y wget
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt-get install -y --no-install-recommends vim curl git-core curl lsb-release libssl-dev libgit2-dev libcurl4-openssl-dev libssh2-1-dev libsodium-dev libxml2-dev r-base r-base-dev dirmngr zlib1g-dev libpq-dev libsasl2-dev cmake
RUN R -e 'install.packages("renv", dependencies = TRUE)'
RUN R -e 'install.packages("shiny", dependencies = TRUE)'
RUN R -e 'install.packages("plumber", dependencies = TRUE)'
RUN R -e 'install.packages("reticulate")'
RUN R -e 'reticulate::install_miniconda(force = TRUE)'
RUN R -e 'reticulate::py_install("boto3")'
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN rm awscliv2.zip
RUN apt-get install -y zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
WORKDIR /root
ENV "nocache"="1670444405.97482"
COPY . /root
RUN R -e 'renv::consent(provided = TRUE)'
RUN R -e 'renv::init(bare = FALSE, force = TRUE, project = "/root")'
EXPOSE 8000