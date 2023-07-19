The ngs_qc pipeline is written in Nextflow and performs a basic QC on sequenced files:

1) FastQC
2) FastQ Screen


Notes on building the associated containers:

FastQC
(This is for a writable version, but that is actually not necessary)
sudo singularity build --sandbox  biocontainers_fastqc_v0.11.9_cv8 docker://biocontainers/fastqc:v0.11.9_cv8
sudo singularity shell --writable --bind /mnt:$PWD biocontainers_fastqc_v0.11.9_cv8



Inside a container install Bowtie2:
cd /usr/local/bin/
wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.5.1/bowtie2-2.5.1-linux-x86_64.zip  --no-check-certificate
unzip bowtie2-2.5.1-linux-x86_64
ln -s bowtie2-2.5.1-linux-x86_64/bowtie2

Inside a container install FastQ Screen:
wget https://github.com/StevenWingett/FastQ-Screen/archive/refs/tags/v0.15.3.tar.gz --no-check-certificate
tar xvzf v0.15.3.tar.gz
ln -s FastQ-Screen-0.15.3/fastq_screen

exit

sudo singularity build ngs_qc.sif biocontainers_fastqc_v0.11.9_cv8/

(This built these containers in the FastQC container, but current best practice is to use separate containers for each separate process.)
