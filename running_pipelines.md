General Notes
=============

# Pipelines

## RNA-seq
[Full Usage Docs](https://nf-co.re/rnaseq/3.6/usage)

### Example walkthrough

**Create sample sheet example:**

    wget -L https://raw.githubusercontent.com/nf-core/rnaseq/master/bin/fastq_dir_to_samplesheet.py
    
    python3 fastq_dir_to_samplesheet.py <FASTQ_DIR> samplesheet.csv --strandedness <STRANDEDNESS> --read1_extension <READ 1 EXTENSION> --read2_extension <LEAVE BLANK FOR SINGLE END>

Strandedness options: 'unstranded', 'forward', 'reverse'

**Example Nextflow command:**

    nextflow run nf-core/rnaseq -r 3.5 --input samplesheet.csv --genome GRCh38_v102 -config /public/singularity/containers/nextflow/lmb-nextflow/lmb.config -bg

### Output
[Click here for output overview](https://nf-co.re/rnaseq/3.6/output)

 ---

## Fetch NGS
[Full Usage Docs](https://nf-co.re/fetchngs/1.5/usage)

### Example walkthrough

Create a file listing on a separate line all the ids to process.

**Example Nextflow command:**

    nextflow run nf-core/fetchngs -r 1.5 --input to_download.txt -config /public/singularity/containers/nextflow/lmb-nextflow/lmb.config -queue-size 4 -bg

### Output
[Click here for output overview](https://nf-co.re/fetchngs/1.5/output)

---

## ATAC-seq

[Full Usage Docs](https://nf-co.re/atacseq/1.2.1/usage)

### Example walkthrough   
Make design file.  It has to be a comma-separated file with 4 columns, and a header row (column headers: group,replicate,fastq_1,fastq_2).  

Input FASTQ files need the extension ".fastq.gz" or ".fq.gz" 


[Click here for more details on making the design file](https://nf-co.re/atacseq/1.2.1/docs/usage#multiple-replicates)


**Example Nextflow command:**

    nextflow run nf-core/atacseq -r 1.2.1 --input design.csv --genome GRCh38_v102 -config /public/singularity/containers/nextflow/lmb-nextflow/lmb.config -bg


### Output
[Click here for output overview](https://nf-co.re/atacseq/1.2.1/output)


## ChIP-seq

[Full Usage Docs](https://nf-co.re/chipseq/1.2.2/usage)

### Example walkthrough   
Make design file.  It has to be a comma-separated file with 6 columns, and a header row (column headers: group, replicate, fastq_1, fastq_2, antibody, control).  

Input FASTQ files need the extension ".fastq.gz" or ".fq.gz" 


[Click here for more details on making the design file](https://nf-co.re/chipseq/1.2.2/usage#multiple-replicates)


**Example Nextflow command:**

    nextflow run nf-core/chipseq -r 1.2.2 --input design.csv --genome GRCm38_v100 -config /public/singularity/containers/nextflow/lmb-nextflow/lmb.config -bg


Note: the option --macs_gsize needs to be set for peak calling, annotation and differential analysis.

### Output
[Click here for output overview](https://nf-co.re/chipseq/1.2.2/output)



