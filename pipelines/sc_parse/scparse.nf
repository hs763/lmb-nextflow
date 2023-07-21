/*
 * pipeline input parameters
 */
params.help = false
// Show help message and exit
if (params.help){
    helpMessage()
    exit 0
}

params.reads_folder = "$projectDir/data"
params.genome_folder = "$projectDir/hg38"
params.chemistry_version = 'v2'
params.outdir = "results"
params.sample_file = "$projectDir/sample_info_sCell.tab"
log.info """\
    SCPARSE P I P E L I N E - Steven Wingett
    ===================================
    reads_folder        : ${params.reads_folder}
    genome_folder       : ${params.genome_folder}
    sample_file         : ${params.sample_file}
    chemistry_version   : ${params.chemistry_version}
    outdir              : ${params.outdir}
    """
    .stripIndent()

/*
 * Initial QC
 */
process FASTQC {
    tag "FASTQC on $sample_id"
    publishDir params.outdir, mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    echo projectdir: ${projectDir}
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}

/*
 * Mapping and Quantitation
 */
process SPIPE {
    debug true
    publishDir params.outdir, mode:'copy'

    input:
    tuple val(sample_id), path(reads)
    path genome_folder 

    output:
    path "split_pipe_${sample_id}"

    script:
    """
    mkdir split_pipe_${sample_id}
    PATH=/share/miniconda/bin:/share/miniconda/envs/spipe/bin:$PATH
    echo split-pipe --chemistry ${params.chemistry_version} --genome_dir ${genome_folder} --samp_list ${params.sample_file} --fq1 ${params.reads_folder}/${reads[0]} --fq2 ${params.reads_folder}/${reads[0]} --mode all --output_dir split_pipe_${sample_id}
    split-pipe --chemistry ${params.chemistry_version} --genome_dir ${genome_folder} --samp_list ${params.sample_file} --fq1 ${params.reads_folder}/${reads[0]} --fq2 ${params.reads_folder}/${reads[1]} --mode all --output_dir split_pipe_${sample_id}
    """
}


/*
 * QC on mapped results
 */
process PARSE_QC {

    debug true
    publishDir params.outdir, mode:'copy'

    input:
    path parse_matrix_folder
    path sample_file

    output:
    path 'output.txt'
    path 'qc_cell_outdir'

    script:
    """
    Rscript ${projectDir}/bin/reformat_data.R ${sample_file}
    Rscript ${projectDir}/bin/qc_cell.R ${parse_matrix_folder}/all-well/DGE_unfiltered sample_info_reformat.tsv > output.txt 
    """
}

/*
 * Overall summary
 */
process MULTIQC {
    publishDir params.outdir, mode:'copy'

    input:
    path '*'

    output:
    path 'multiqc_report.html'
    path 'multiqc_data'

    script:
    """
    multiqc .
    """
}


workflow {
    reads = "${params.reads_folder}/*_{1,2}.fastq.gz"

    Channel
        .fromFilePairs(reads, checkIfExists: true)
        .set { read_pairs_ch }

    fastqc_ch = FASTQC(read_pairs_ch)
    spipe_ch = SPIPE(read_pairs_ch, params.genome_folder)

    PARSE_QC(spipe_ch, params.sample_file)

    MULTIQC(spipe_ch.mix(fastqc_ch).collect())
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}


def helpMessage() {
 
    log.info"""
    >>
    SYNOPSIS:

    This workflow runs an entire Parse single cell RNA-seq processing pipeline on FastQ files, including QC, mapping and post-mapping QC.
    
    Here is a graphical representation of the workflow:

    --- FastQC
    --- split-pipe
        |
        --- QC R scripts
    --- MultiQC*
        
    * This step runs only once ALL other jobs have completed.
              
    USAGE:

    nextflow run scparse.nf --reads_folder <FASTQ foldername> --genome_folder <genome folder>  --sample_file <experiment description> --chemistry_version <experiment chemistry>

    Mandatory arguments:
    ====================

      --reads_folder [str]            Path to the folder containg FASTQ files.

      --genome_folder [str]           Path to the genome folder for mapping.

      --sample_file [str]             Path to the sample file detailing the experimental setup.

      --chemistry_version [str]       Specify the chemistry version used.

    Other options:
    ==============

      --outdir [str]                  Path to the output directory. [Default: results]

      --help                          Displays this help message and exits.

    Workflow options:
    =================

    Please note the single '-' hyphen for the following options!

      -resume                         Attempt to resume the workflow if it was interrupted previously.  This uses
                                      Nextflow's caching mechanism and may save a lot since the whole pipeline will not need to be run.

      -bg                             Sends the entire workflow into the background, thus disconnecting it from the terminal session.
                                      This option launches a daemon process (which will keep running on the headnode) that watches over
                                      your workflow. This option is HIGHLY RECOMMENDED for pipelines taking more than a minute to 
                                      complete.
    <<
    """.stripIndent()

}