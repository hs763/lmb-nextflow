#sudo docker build --no-cache -f qc_cell.Dockerfile -t qc_cell .
#docker run -v $PWD:/mnt --name qc_cell -d -i -t qc_cell /bin/bash
#docker exec -it qc_cell bash
#
#
# docker tag 17b6aaf0b231 swingett/qc_cell:v0.2
# docker push swingett/qc_cell:v0.2


FROM ubuntu:jammy-20231004

LABEL image.author.name "Steven Wingett"

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt update -y

RUN apt install r-base=4.1.2-1ubuntu2  -y
RUN apt install r-base-dev=4.1.2-1ubuntu2 -y
RUN apt install curl=7.81.0-1ubuntu1.14 -y
RUN apt install apt-show-versions=0.22.13 -y
RUN apt install libssl-dev=3.0.2-0ubuntu1.12 -y
RUN apt install libcurl4-openssl-dev=7.81.0-1ubuntu1.14 -y
RUN apt install libxml2-dev=2.9.13+dfsg-1ubuntu0.3 -y
RUN apt install libfontconfig1-dev=2.13.1-4.2ubuntu5 -y 
RUN apt install libharfbuzz-dev=2.7.4-1ubuntu3.1 -y
RUN apt install libfribidi-dev=1.0.8-2ubuntu3.1 -y
RUN apt install libfreetype6-dev=2.11.1+dfsg-1ubuntu0.2 -y
RUN apt install libpng-dev=1.6.37-3build5 -y
RUN apt install libtiff5-dev=4.3.0-6ubuntu0.7 -y
RUN apt install libjpeg-dev=8c-2ubuntu10 -y
RUN apt install libcairo2-dev=1.16.0-5ubuntu2 -y
RUN apt install libmagick++-dev=8:6.9.11.60+dfsg-1.3ubuntu0.22.04.3 -y


# library(devtools)
#RUN Rscript -e 'install.packages("devtools")'
RUN Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/devtools_2.4.5.tar.gz")'

# library(tidyverse)
RUN Rscript -e 'devtools::install_version("xml2", version="1.3.5", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("systemfonts", version="1.0.4", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("textshaping", version="0.3.6", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("ragg", version="1.2.5", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("rvest", version="1.0.3", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("tidyverse", version="2.0.0", repos = "http://cran.us.r-project.org")' 

# library(viridis)
RUN Rscript -e 'devtools::install_version("viridis", version="0.6.4", repos = "http://cran.us.r-project.org")'

# library(biomaRt)
RUN Rscript -e 'devtools::install_version("BiocManager", version="1.30.22", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'BiocManager::install(version = "3.14")'
RUN Rscript -e 'BiocManager::install("biomaRt", version = "3.14")'
 
# library(irlba)
RUN Rscript -e 'devtools::install_version("irlba", version="2.3.5.1", repos = "http://cran.us.r-project.org")'

# library(Rtsne)
RUN Rscript -e 'devtools::install_version("Rtsne", version="0.16", repos = "http://cran.us.r-project.org")'

# library(Matrix)
RUN Rscript -e 'devtools::install_version("Matrix", version="1.6.1", repos = "http://cran.us.r-project.org")'

# library(reticulate)
RUN Rscript -e 'devtools::install_version("reticulate", version="1.31", repos = "http://cran.us.r-project.org")'

# library(umap)
RUN Rscript -e 'devtools::install_version("umap", version="0.2.10.0", repos = "http://cran.us.r-project.org")'

# library(scDblFinder)
RUN Rscript -e 'devtools::install_version("Cairo", version="1.6.1", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("ggrastr", version="1.0.2", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'BiocManager::install("scater", version = "3.14")'
RUN Rscript -e 'BiocManager::install("scDblFinder", version = "3.14")'

# library(rlist)
RUN Rscript -e 'devtools::install_version("rlist", version="0.4.6.2", repos = "http://cran.us.r-project.org")'

# library celda
RUN Rscript -e 'devtools::install_version("assertive.base", version="0.0.9", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("assertive.files", version="0.0.2", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("assertive.numbers", version="0.0.2", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/assertive.properties/assertive.properties_0.0-5.tar.gz")'
RUN Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/assertive.types/assertive.types_0.0-3.tar.gz")'
RUN Rscript -e 'devtools::install_version("gridGraphics", version="0.5.1")'
RUN Rscript -e 'devtools::install_version("magick", version="2.8.1")'
RUN Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/multipanelfigure/multipanelfigure_2.1.2.tar.gz")'
RUN Rscript -e 'BiocManager::install("celda", version = "3.14")'

#######################

# library(BiocParallel)
#RUN Rscript -e 'BiocManager::install("BiocParallel", version = "3.17")'


# library(scran)
#RUN Rscript -e 'install_version("RCurl", version="1.98.1.12")'
#RUN Rscript -e 'BiocManager::install("GenomeInfoDb", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("GenomicRanges", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("SummarizedExperiment", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("SingleCellExperiment", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("scuttle", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("scran", version = "3.17")'
