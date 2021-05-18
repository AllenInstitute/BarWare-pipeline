FROM rstudio/r-base:3.6.3-centos8

## Copy the pipeline into the container
ADD ./ /BarcodeTender-pipeline/

## Resolving R and lib dependencies
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    libbz2-dev \
    libc6-dev \
    libgcc-9-dev \
    gcc-9-base \
    liblzma-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libhdf5-dev \
    pandoc \
    libpng-dev \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

RUN bash /BarcodeTender-pipeline/00_setup.sh \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

COPY auth_token /tmp/auth_token

ENTRYPOINT ["tail", "-f", "/dev/null"]
