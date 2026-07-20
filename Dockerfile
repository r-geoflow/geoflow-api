FROM rocker/shiny:4.5.1

LABEL org.opencontainers.image.title="geoflow-api"
LABEL org.opencontainers.image.url="https://github.com/r-geoflow/geoflow-api"
LABEL org.opencontainers.image.description="An API for executing geoflow workflows (powered by Plumber R package)"
LABEL org.opencontainers.image.authors="Emmanuel Blondel <eblondel.pro@gmail.com>"

# Set thread environment variables
ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sudo pandoc texlive-xetex texlive-latex-base texlive-latex-recommended \
    texlive-fonts-recommended texlive-fonts-extra texlive-formats-extra \
    libssl-dev libxml2-dev libv8-dev libsodium-dev libsecret-1-dev \
    librdf0 librdf0-dev cmake curl default-jdk fonts-roboto ghostscript \
    hugo less libbz2-dev libglpk-dev libgmp3-dev libfribidi-dev \
    libharfbuzz-dev libhunspell-dev libicu-dev liblzma-dev libmagick++-dev \
    libopenmpi-dev libpcre2-dev libxslt1-dev libzmq3-dev lsb-release qpdf \
    texinfo software-properties-common vim wget libgit2-dev libcurl4 rasqal-utils raptor2-utils

# Geospatial libraries
RUN /rocker_scripts/install_geospatial.sh

# Core dependencies
RUN install2.r --error --skipinstalled --ncpus -1 httpuv redland

WORKDIR /srv/geoflow-api

# Setup renv
ENV RENV_PATHS_CACHE=/srv/geoflow-api/renv/.cache
RUN R -e "install.packages(c('renv'), repos='https://cran.r-project.org/')"

COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

RUN mkdir -p renv/.cache && R -e "renv::restore()"

# Copy API files
COPY plumber_geoflow_api.R plumber_geoflow_api.R
COPY plumber.R plumber.R

# Expose port
EXPOSE 8000

# Run API
CMD ["R", "-f", "plumber.R"]