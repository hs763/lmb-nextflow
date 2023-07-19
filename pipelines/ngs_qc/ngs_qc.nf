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
params.config_file = "/public/genomics/FastQ_Screen_Genomes/fastq_screen.conf"
params.outdir = "results"
log.info """\
    NGS-QC P I P E L I N E - Steven Wingett
    ===================================
    reads_folder        : ${params.reads_folder}
    config_file         : ${params.config_file}
    outdir              : ${params.outdir}
    """
    .stripIndent()

/*
 * Initial QC
 */
process FASTQC {

    publishDir params.outdir, mode:'copy'
    
    input:
    path(reads)

    output:
    path ('*')

    script:
    """
    fastqc --threads 4 -f fastq -q ${reads}
    """
}

/*
 * Multi-genome screen
 */
process FASTQ_SCREEN {
    publishDir params.outdir, mode:'copy'

    input:
    path(reads)
    path (config)

    output:
    path "*"

    script:
    """
    fastq_screen --conf ${config} ${reads}
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
    
    Channel
        .fromPath("${params.reads_folder}/*{.fastq.gz,.fq.gz,.fastq,.fq}", checkIfExists: true)
        .set { reads_ch }

    fastqc_ch = FASTQC(reads_ch)
    fastq_screen_ch = FASTQ_SCREEN(reads_ch, params.config_file)

    MULTIQC(fastq_screen_ch.mix(fastqc_ch).collect())
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}


def helpMessage() {
 
    log.info"""
    >>
    SYNOPSIS:

    This workflow runs a basic QC on FASTQ files.
    
    Here is a graphical representation of the workflow:

    --- FastQC
    --- FastQ Screen
    --- MultiQC*
        
    * This step runs only once ALL other jobs have completed.
              
    USAGE:

    nextflow run scparse.nf --reads_folder <FASTQ foldername> --conf_file <FastQ Screen config file> --outdir <output folder>

    Mandatory arguments:
    ====================

      --reads_folder [str]            Path to the folder containg FASTQ files.

      --conf_file [str]               Path to the FastQ Screen configuration file

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
