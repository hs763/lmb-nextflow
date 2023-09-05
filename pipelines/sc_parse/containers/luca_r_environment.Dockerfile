#sudo docker build  -f luca_r_environment.Dockerfile -t luca_r_environment .
#docker run --name luca_r_environment -d -i -t luca_r_environment /bin/bash
#docker exec -it luca_r_environment bash


FROM ubuntu:mantic-20230807.1


LABEL image.author.name "Steven Wingett"

SHELL ["/bin/bash", "-c"]

RUN apt update -y

RUN apt install cmake=3.27.4-1 -y

RUN apt install curl=8.2.1-1ubuntu2 -y
RUN apt install apt-show-versions=0.22.14 -y
RUN apt install libssl-dev=3.0.10-1ubuntu2 -y
RUN apt install libcurl4-openssl-dev=8.2.1-1ubuntu2 -y

RUN apt install libhdf5-dev=1.10.8+repack1-1ubuntu1 -y
RUN apt install vim=2:9.0.1672-1ubuntu2 -y

RUN apt install r-base=4.3.1-4 -y
RUN apt install r-base-dev=4.3.1-4 -y

#library( ggplot2 )
RUN Rscript -e 'install.packages("ggplot2", version="3.4.3")' 

#library( dplyr )
RUN Rscript -e 'install.packages("dplyr", version="1.1.3")' 

#library( tidyr )
RUN Rscript -e 'install.packages("tidyr", version="1.3.0")'

#library( plotly )
RUN Rscript -e 'install.packages("openssl", version="2.1.0")'
RUN Rscript -e 'install.packages("curl", version="5.0.2")'
RUN Rscript -e 'install.packages("plotly", version="4.10.2")'

#library (knitr)
RUN Rscript -e 'install.packages("knitr", version="1.43")'

#library(FactoMineR)
RUN Rscript -e 'install.packages("FactoMineR", version="2.8")'

#library(factoextra)
RUN Rscript -e 'install.packages("factoextra", version="1.0.7")'

#library( Seurat )
RUN Rscript -e 'install.packages("Seurat", version="4.3.0.1")'

#library( tibble )
RUN Rscript -e 'install.packages("tibble", version="3.2.1")'

#library(corrplot)
RUN Rscript -e 'install.packages("corrplot", version="0.92")'

#library( cowplot )
RUN Rscript -e 'install.packages("cowplot", version="1.1.1")'

#library (readxl)
RUN Rscript -e 'install.packages("readxl", version="1.4.3")'

#library(Matrix)
RUN Rscript -e 'install.packages("Matrix", version="1.6.1")'

#library(reshape2)
RUN Rscript -e 'install.packages("reshape2", version="1.4.4")'

#library(remotes)
RUN Rscript -e 'install.packages("remotes", version="2.4.2.1")'

#library(patchwork)
RUN Rscript -e 'install.packages("patchwork", version="1.1.3")'

#library(SeuratDisk)
RUN Rscript -e 'install.packages("hdf5r", version="1.3.8")'

#mojaveazure/seurat-disk
# Sometimes the github API prevents pulls owing to API limits for the IP address!!!!!   
##  Authentication with a personal access token is a way around this - see: 
# https://mpn.metworx.com/packages/usethis/1.5.1/articles/articles/usethis-setup.html
RUN Rscript -e 'install.packages("usethis", version="2.2.2")'
# Install the seurat-disk commit 9b89970
# Comment this out and then try an build the container without this line if the API limit is a
# problem.  Then in the container create an Github personal access token and try to pull the repo.
RUN Rscript -e 'remotes::install_github("mojaveazure/seurat-disk@9b89970")'
