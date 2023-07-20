# Build the FastQC container
sudo singularity build biocontainers_fastqc_v0.11.9_cv8.sif docker://biocontainers/fastqc:v0.11.9_cv8

# Build the MultiQC container
sudo singularity build ewels_multiqc_v1.14.sif docker://ewels/multiqc:v1.14


# Build the analysis script container
sudo singularity build --sandbox shortcake/ docker:rnakato/shortcake
sudo singularity shell --bind my_data:/mnt --writable shortcake
Inside of container add R package scDblFinder




