FROM us.gcr.io/dev-pipeline-internal/google-r-base:v1.0

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

RUN Rscript -e 'install.packages("BiocManager");BiocManager::install("rhdf5")' \
    && Rscript -e 'install.packages(c("R.utils","rlang","assertthat","jsonlite"))' \
    && Rscript -e 'install.packages(c("data.table","Matrix","multimode"))' \
    && Rscript -e 'install.packages(c("dplyr","purrr","ggplot2","ids","DT"))' \
    && Rscript -e 'install.packages(c("optparse","rmarkdown"))'

RUN cd /BarWare-pipeline/ \
    && bash 00_setup.sh \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds


