FROM rocker/rstudio:3.6

## allow root access to terminal in RStudio
ENV ROOT=TRUE
ENV PASSWORD=password
ENV DISABLE_AUTH=TRUE
ENV TZ=Australia/Brisbane

ARG CTAN_REPO=${CTAN_REPO:-https://www.texlive.info/tlnet-archive/2019/02/27/tlnet}
ENV CTAN_REPO=${CTAN_REPO}

ENV PATH=$PATH:/opt/TinyTeX/bin/x86_64-linux/

RUN wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    fonts-roboto \
    ghostscript \
    less \
    libgit2-dev \
    libxml2-dev \
    libcairo2-dev \
    liblapack-dev \
    liblapack3 \
    libopenblas-base \
    libopenblas-dev \
    libpq-dev \
    default-jdk \
    libbz2-dev \
    libicu-dev \
    liblzma-dev \
    libhunspell-dev \
    libjpeg-dev \
    libv8-dev \
    openssh-client \
    mdbtools \
    libmagick++-dev \
    libsnappy-dev \
    libopenmpi-dev \
    librdf0-dev \
    libtiff-dev \
    autoconf \
    automake \
    libtool \
    python-dev \
    pkg-config \
    p7zip-full \
    libzmq3-dev \
    qpdf \
    ssh \
    texinfo \
    libudunits2-dev \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && rm -rf -- /var/lib/apt/lists /tmp/*.deb \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ \
  ## Use tinytex for LaTeX installation
  && install2.r --error tinytex \
  ## Admin-based install of TinyTeX:
  && wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && if /opt/TinyTeX/bin/*/tex -v | grep -q 'TeX Live 2018'; then \
      ## Patch the Perl modules in the frozen TeX Live 2018 snapshot with the newer
      ## version available for the installer in tlnet/tlpkg/TeXLive, to include the
      ## fix described in https://github.com/yihui/tinytex/issues/77#issuecomment-466584510
      ## as discussed in https://www.preining.info/blog/2019/09/tex-services-at-texlive-info/#comments
      wget -P /tmp/ ${CTAN_REPO}/install-tl-unx.tar.gz \
      && tar -xzf /tmp/install-tl-unx.tar.gz -C /tmp/ \
      && cp -Tr /tmp/install-tl-*/tlpkg/TeXLive /opt/TinyTeX/tlpkg/TeXLive \
      && rm -r /tmp/install-tl-*; \
    fi \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr install ae inconsolata listings metafont mfware parskip pdfcrop tex \
  && tlmgr path add \
  && Rscript -e "tinytex::r_texmf()" \
  && chown -R root:staff /opt/TinyTeX \
  && chmod -R g+w /opt/TinyTeX \
  && chmod -R g+wx /opt/TinyTeX/bin \
  && echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron \
  && install2.r --error PKI \
  ## And some nice R packages for publishing-related stuff
  && install2.r --error --deps TRUE \
    bookdown rticles rmdshower rJava

RUN install2.r --error \
    --deps TRUE \
    devtools

## add regularly used packages
RUN install2.r --error \
  RcppEigen \
  lme4 \
  car \
  scales \
  reshape2 \
  RPostgreSQL \
  Hmisc \
  officer \
  flextable \
  xaringan \
  ggthemes \
  scales \
  zoo \
  futile.logger \
  extrafont \
  writexl \
  feather

## execute R commands to install some packages
RUN install2.r --error \
  secret \
  flexdashboard \
  XLConnect \
  RSQLite \
  fst \
  && R -e 'remotes::install_github("tidyverse/ggplot2")' \
  && R -e 'remotes::install_github("wilkelab/gridtext")' \
  && R -e 'remotes::install_gitlab("thedatacollective/segmentr")' \
  && R -e 'remotes::install_github("danwwilson/hrbrthemes", "dollar_axes")' \
  && R -e 'remotes::install_github("thedatacollective/tdcthemes")' \
  && R -e 'remotes::install_gitlab("thedatacollective/templatermd")' \
  && R -e 'remotes::install_github("StevenMMortimer/salesforcer")' \
  && R -e 'install.packages("data.table", type = "source", repos = "http://Rdatatable.github.io/data.table")' \
  && rm -rf /tmp/downloaded_packages/ \
  && rm -rf /tmp/*.tar.gz

## add fonts
COPY fonts /usr/share/fonts
COPY user-settings /home/rstudio/.rstudio/monitored/user-settings/

## Update font cache
RUN fc-cache -f -v

## Add /data volume by default
VOLUME /data
VOLUME /home/rstudio/.ssh
