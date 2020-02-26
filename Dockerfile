FROM rocker/shiny-verse


RUN apt-get update -qq && apt-get install -y \
  git-core \
  libssl-dev \
  default-jdk \
  libcurl4-openssl-dev \
  curl \
  libxml2-dev \
  libpq-dev -y

RUN R CMD javareconf

RUN R -e "install.packages('devtools')"


