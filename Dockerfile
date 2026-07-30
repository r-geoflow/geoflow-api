FROM rocker/r-base:4.5.3

LABEL org.opencontainers.image.title="geoflow-api"
LABEL org.opencontainers.image.url="https://github.com/r-geoflow/geoflow-api"
LABEL org.opencontainers.image.description="An API for executing geoflow workflows (powered by Plumber R package)"
LABEL org.opencontainers.image.authors="Emmanuel Blondel <eblondel.pro@gmail.com>"

ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    pandoc \
    texlive-xetex \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-formats-extra \
    \
    # XML / crypto / networking
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libgit2-dev \
    \
    # V8 / JS
    libv8-dev \
    \
    # Security / secrets
    libsodium-dev \
    libsecret-1-dev \
    \
    # RDF
    librdf0 \
    librdf0-dev \
    rasqal-utils \
    raptor2-utils \
    \
    # Geospatial stack
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    proj-bin \
    proj-data \
    libudunits2-dev \
    libsqlite3-dev \
    \
    # Raster/vector formats
    libtiff-dev \
    libjpeg-dev \
    libpng-dev \
    \
    # Scientific formats
    libnetcdf-dev \
    libhdf5-dev \
    \
    # Compression
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    \
    # Math / compilation
    cmake \
    libglpk-dev \
    libgmp3-dev \
    libpcre2-dev \
    libicu-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    \
    # Misc
    default-jdk \
    fonts-roboto \
    ghostscript \
    hugo \
    less \
    libmagick++-dev \
    libopenmpi-dev \
    libzmq3-dev \
    qpdf \
    texinfo \
    software-properties-common \
    vim \
    wget \
    curl \
    lsb-release \
    \
    && rm -rf /var/lib/apt/lists/*


# R geospatial packages
RUN install2.r --error --skipinstalled --ncpus -1 \
    sf \
    terra \
    stars \
    s2 \
    lwgeom \
    units \
    sp \
    raster \
    geojsonsf \
    vapour


# Core dependencies
RUN install2.r --error --skipinstalled --ncpus -1 \
    httpuv \
    plumber \
    redland


WORKDIR /srv/geoflow-api

ENV RENV_PATHS_CACHE=/srv/geoflow-api/renv/.cache

RUN install2.r --error --skipinstalled renv

COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

RUN mkdir -p renv/.cache && \
    R -e "renv::restore()"


COPY plumber_geoflow_api.R plumber_geoflow_api.R
COPY plumber.R plumber.R

EXPOSE 8000

CMD ["R", "-f", "plumber.R"]
