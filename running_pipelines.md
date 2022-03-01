General Notes
=============

# Pipelines

## RNA-seq

### Example walkthrough

Create sample sheet:

    wget -L https://raw.githubusercontent.com/nf-core/rnaseq/master/bin/fastq_dir_to_samplesheet.py
    
    python3 fastq_dir_to_samplesheet.py <FASTQ_DIR> samplesheet.csv --strandedness <STRANDEDNESS> --read1_extension <READ 1 EXTENSION> --read2_extension <LEAVE BLANK FOR SINGLE END>

Strandedness options: 'unstranded', 'forward', 'reverse'

Example Command:

    nextflow run nf-core/rnaseq -r 3.4 --input samplesheet.csv --genome GRCh38_v102 -profile singularity -config lmb.config -bg
    
## Fetch NGS

### Example walkthrough

Create a file listing on a separate line all the ids to process

        nextflow run nf-core/fetchngs -r 1.5 --input to_download.txt -config lmb.config

        





