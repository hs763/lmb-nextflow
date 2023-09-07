#sudo docker build -f qc_cell.Dockerfile -t qc_cell .
#docker run -v $PWD:/mnt --name qc_cell -d -i -t qc_cell /bin/bash
#docker exec -it qc_cell bash


FROM ubuntu:mantic-20230807.1


LABEL image.author.name "Steven Wingett"

SHELL ["/bin/bash", "-c"]

RUN apt update -y

RUN apt update -y

RUN apt install r-base=4.3.1-4 -y
RUN apt install r-base-dev=4.3.1-4 -y

RUN apt install curl=8.2.1-1ubuntu2 -y
RUN apt install apt-show-versions=0.22.14 -y
RUN apt install libssl-dev=3.0.10-1ubuntu2 -y
RUN apt install libcurl4-openssl-dev=8.2.1-1ubuntu2 -y

RUN apt install libxml2-dev=2.9.14+dfsg-1.3 -y
RUN apt install libfontconfig1-dev=2.14.2-4ubuntu1 -y 

RUN apt install libharfbuzz-dev=8.0.1-1 -y
RUN apt install libfribidi-dev=1.0.13-3 -y

RUN apt install libfreetype6-dev=2.13.1+dfsg-1 -y
RUN apt install libpng-dev=1.6.40-1 -y
RUN apt install libtiff5-dev=4.5.1+git230720-1ubuntu1 -y
RUN apt install libjpeg-dev=8c-2ubuntu11 -y

RUN apt install libcairo2-dev=1.17.8-2 -y



# library(tidyverse)
RUN Rscript -e 'install.packages("xml2", version="1.3.5")'
RUN Rscript -e 'install.packages("systemfonts", version="1.0.4")'
RUN Rscript -e 'install.packages("textshaping", version="0.3.6")'
RUN Rscript -e 'install.packages("ragg", version="1.2.5")'
RUN Rscript -e 'install.packages("rvest", version="1.0.3")'
RUN Rscript -e 'install.packages("tidyverse", version="2.0.0")' 

# library(viridis)
RUN Rscript -e 'install.packages("viridis", version="0.6.4")'

# library(biomaRt)
RUN Rscript -e 'install.packages("BiocManager", version="1.30.22")'
RUN Rscript -e 'BiocManager::install(version = "3.17")'
RUN Rscript -e 'BiocManager::install("biomaRt", version = "3.17")'
 
# library(irlba)
RUN Rscript -e 'install.packages("irlba", version="2.3.5.1")'

# library(Rtsne)
RUN Rscript -e 'install.packages("Rtsne", version="0.16")'

# library(Matrix)
RUN Rscript -e 'install.packages("Matrix", version="1.6.1")'


# library(reticulate)
RUN Rscript -e 'install.packages("reticulate", version="1.31")'

# library(umap)
RUN Rscript -e 'install.packages("umap", version="0.2.10.0")'



# library(scDblFinder)
RUN Rscript -e 'install.packages("Cairo", version="1.6.1")'
RUN Rscript -e 'install.packages("ggrastr", version="1.0.2")'
RUN Rscript -e 'BiocManager::install("scater", version = "3.17")'
RUN Rscript -e 'BiocManager::install("scDblFinder", version = "3.17")'


# library(rlist)
RUN Rscript -e 'install.packages("rlist", version="0.4.6.2")'


# library(BiocParallel)
#RUN Rscript -e 'BiocManager::install("BiocParallel", version = "3.17")'


# library(scran)
#RUN Rscript -e 'install.packages("RCurl", version="1.98.1.12")'
#RUN Rscript -e 'BiocManager::install("GenomeInfoDb", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("GenomicRanges", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("SummarizedExperiment", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("SingleCellExperiment", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("scuttle", version = "3.17")'
#RUN Rscript -e 'BiocManager::install("scran", version = "3.17")'
