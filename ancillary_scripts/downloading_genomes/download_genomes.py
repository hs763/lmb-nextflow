# Python3 script to download genomes

from operator import ge
import os
#import os.path
import glob
import re
import argparse
import pandas as pd
import subprocess
import math

parser = argparse.ArgumentParser(description='''
Python3 script to download genomes.

It assumes downloading from Ensembl, unless specified
elsewhere. 

Takes as input 'samplesheet.csv', which 
needs to be in the current working directory. It 
reads this file to determine what to download and 
what other operations to perform (e.g. build new 
Bowtie2 index files).  The values 0/1 set this for each 
download in samplesheet.csv. 

Currently functionality 
is only supported for Ensembl downloads. (TODO: maybe 
add NCBI downloads as a separate function?; add links 
to FASTA files and GTF files for other genome data 
repositories).
 
The following are / maybe needed in path for this script to run:
           lftp,
           extract_splice_sites.py,
           extract_exons.py,
           bowtie2-build,
           hisat2-build,
           STAR,
           hicup_digester,
           gzip
                                
                                 
For making the Parse genome a conda environment will need to be activated (
see: https://support.parsebiosciences.com/hc/en-us/articles/17166220335636-Pipeline-Setup-and-Use-Current-Version- )

''')

parser.add_argument("--genome_list", action='store', type=str,
                    help="CSV file listing genomes to download [default=genomes_to_download.csv]", 
                    default='genomes_to_download.csv')


args = parser.parse_known_args()    #Use parse_known_arg to differentiate between arguments pre-specified and those that are not
options = args[0]   # Get the 2 arrays of known/unknown arguments from the tuple


current_working_directory = os.getcwd()
genome_ref_outdir = current_working_directory
genome_ref_outdir = genome_ref_outdir + '/Genome_References/'
#temporary_fasta_folder = genome_ref_outdir + '/_tmp_original_fasta_files_to_delete'

folder_names = {        #To standardise folder names throughout code
                'fasta' : 'FASTA',
                'gtf' : 'GTF',
                'bowtie2' : 'Indices/Bowtie2_index',
                'hisat2' : 'Indices/HISAT2_index',
                'star' : 'Indices/STAR_index',
                'hicup' : 'Misc/HiCUP_digest',
                'parse' : 'Indices/Parse_index'
                }


####################################
# download_ensembl_fasta
####################################
def download_ensembl_fasta(species, assembly, release):
    print('Downloading FASTA files: ' + species + ' ' + assembly + ' (' + str(release) + ')')

    ensembl_base = 'http://ftp.ensembl.org/pub/release-'
    download_folder = ensembl_base + release + '/fasta/' + species + '/dna/'

    print("Downloading primary assembly sequences")
    command = 'lftp -e "mget *.dna.primary_assembly.* ; bye" '
    command = command + download_folder
    print(f'command: {command}')
    os.system(command)

    # Did primary assembly download, if not download toplevel
    file_lookup = os.getcwd() + '/*.dna.primary_assembly.*'
    fasta_files_downloaded = glob.glob(file_lookup)
    
    if(len(fasta_files_downloaded) == 0):
        print('Primary assembly not found, downloading toplevel file')
        print('(When there is no primary assembly file, the toplevel file does not include haplotype sequences)')
        command = 'lftp -e "mget *.dna.toplevel.fa.gz; bye" '
        command = command + download_folder
        print(f'command: {command}')
        os.system(command)

    print('Unzipping FASTA files')
    os.system('gunzip *.fa.gz') 

    # For many Nextflow pipelines a single FASTA file is required
    # So record original filenames, concatenated into a single file and then move
    # original file to a new location for deletion
    file_lookup = os.getcwd() + '/*.fa'
    fasta_files_downloaded = glob.glob(file_lookup)

    # Write file list
    fasta_summary_list = 'original_nextflow_fasta_files_list.txt'
    with open(fasta_summary_list, 'w') as f_out:
        for file in fasta_files_downloaded:
            file = os.path.basename(file)
            f_out.write(file + '\n')
    f_out.close() 

    # Create concatenated file
    fasta_files_downloaded = ' '.join(fasta_files_downloaded)
    combined_fasta_file = species + '__' + assembly + '__release' + str(release) + '.nextflow.genome.fa'
    print('Combining FASTA files into: ' + combined_fasta_file)
    command = f'cat {fasta_files_downloaded} > {combined_fasta_file}'
    os.system(command)

    # Move file(s) to temporary folder
    #print('Combining original FASTA files into temporary FASTA folder ' + temporary_fasta_folder)
    #command = f'mv {fasta_files_downloaded} {temporary_fasta_folder}'
    #os.system(command)


####################################
# download_ensembl_fasta_cDNA
####################################
def download_ensembl_fasta_cdna(species, assembly, release):
    cdna_file_extension = '*.cdna.all.fa.gz'

    print('Downloading FASTA files: ' + species + ' ' + assembly + ' (' + str(release) + ')')

    ensembl_base = 'http://ftp.ensembl.org/pub/release-'
    download_folder = ensembl_base + release + '/fasta/' + species + '/cdna/'

    print("Downloading cDNA sequences")
    command = f'lftp -e "mget {cdna_file_extension}; bye" '
    command = command + download_folder
    print(f'command: {command}')
    os.system(command)

    print('Unzipping cDNA files')
    command = f'gunzip {cdna_file_extension}'
    os.system(command)



####################################
# download_ensembl_gtf
####################################
def download_ensembl_gtf(species, assembly, release):
    print('Downloading GTF file: ' + species + ' ' + assembly + ' (' + release + ')')

    ensembl_base = 'http://ftp.ensembl.org/pub/release-'
    download_folder = ensembl_base + release + '/gtf/' + species + '/'

    print("Downloading GTF")
    command = 'lftp -e "mget *.' + release + '.gtf.gz; bye" '
    command = command + download_folder
    os.system(command)


####################################
# make_bowtie2_index
####################################
def make_bowtie2_index(bowtie2_folder, fasta_folder, species, assembly, release):
    
    if not os.path.exists(bowtie2_folder):
        os.makedirs(bowtie2_folder)

    # Make a bowtie subfolder for this specific version of Bowtie2
    command = 'bowtie2-build --version | head -1'
    bowtie2_version = subprocess.getoutput(command).split(' ')[-1]
    bowtie2_version_specific_folder = f'{bowtie2_folder}/v{bowtie2_version}'

    if not os.path.exists(bowtie2_version_specific_folder):
        os.chdir(fasta_folder)
        fasta_files = glob.glob('*.nextflow.genome.fa')
        fasta_files = ','.join(fasta_files)

        #Build index
        genome_index_basename = '.'.join([species, assembly, 'dna', release])
        command = 'bowtie2-build --version > bowtie2-build_version.out'

        os.system(command)
        command = f'bowtie2-build {fasta_files} {genome_index_basename} > bowtie2-build.out'
        os.system(command)

        #Move index files to new folder
        os.makedirs(bowtie2_version_specific_folder)
        command = f'mv *.bt2 {bowtie2_version_specific_folder}'
        os.system(command)
        command = f'mv *.out {bowtie2_version_specific_folder}'
        os.system(command)
    else:
        print('Skipping - Bowtie2 folder already exists: ' + bowtie2_version_specific_folder)



####################################
# make_hisat2_index
####################################
def make_hisat2_index(hisat2_folder, fasta_folder, gtf_folder, species, assembly, release):
    
    if not os.path.exists(hisat2_folder):
        os.makedirs(hisat2_folder)

        #Make splice sites and exons file
        os.chdir(gtf_folder)
        gtf_file = glob.glob('*.gtf')[0]
        splice_site_file = gtf_file[:-3] + 'ss'
        exon_file = gtf_file[:-3] + 'exon'

        command = f'extract_splice_sites.py {gtf_file} > {splice_site_file}'
        os.system(command)     
        command = f'extract_exons.py {gtf_file} > {exon_file}'
        os.system(command)

    # Make a hisat2 subfolder for this specific version of hisat2
    command = 'hisat2-build --version | head -1'
    hisat2_version = subprocess.getoutput(command).split(' ')[-1]
    hisat2_version_specific_folder = f'{hisat2_folder}/v{hisat2_version}'

    if not os.path.exists(hisat2_version_specific_folder):
        # Make HISAT2 index
        os.chdir(fasta_folder)
        fasta_files = glob.glob('*.nextflow.genome.fa')
        fasta_files = ','.join(fasta_files)
        genome_index_basename = '.'.join([species, assembly, 'dna', release])
        command = 'hisat2 --version > hisat2-version.out'
        os.system(command)
        command = f'hisat2-build {fasta_files} {genome_index_basename} > hisat2-build.out'
        os.system(command)

        #Move index files to new folder
        os.makedirs(hisat2_version_specific_folder)
        command = f'mv *.ht2 {hisat2_version_specific_folder}'
        os.system(command)
        command = f'mv *.out {hisat2_version_specific_folder}'
        os.system(command)

    else:
        print('Skipping - HISAT2 folder already exists: ' + hisat2_version_specific_folder)



####################################
# determine_genome_size
####################################

def determine_genome_size(fasta_folder):
    os.chdir(fasta_folder)
    fasta_files = glob.glob('*.nextflow.genome.fa')
    print('Determining the genome size of FASTA files in: ' + fasta_folder + '\n' + '\n'.join(fasta_files))

    fasta_files = ' '.join(fasta_files)
    command = f"grep -v '>' {fasta_files} | wc"     # Skip FASTA header lines
    wc_output = subprocess.getoutput(command)
    wc_output = wc_output.split() 

    genome_size = int(wc_output[2]) - int(wc_output[0])    # Characters - new lines
    print(f'Genome size determined to be {genome_size} bases')

    return(genome_size)



####################################
# make_star_index
####################################
def make_star_index(star_folder, fasta_folder, gtf_folder, species, assembly, release, genome_size):

    if not os.path.exists(star_folder):

        # Determine the --genomeSAindexNbases value
        # Documentation recommends: min(14, log2(GenomeLength)/2 - 1)
        genomeSAindexNbases = (math.log2(genome_size) / 2) - 1
        genomeSAindexNbases = math.floor(genomeSAindexNbases)
        
        if(genomeSAindexNbases > 14):   # Set between 10 and 14
            genomeSAindexNbases = 14
        elif(genomeSAindexNbases < 10):
            genomeSAindexNbases = 10

        print(f'Genome size is {genome_size}, so setting --genomeSAindexNbases to {genomeSAindexNbases}')
        
        os.makedirs(star_folder)
        os.chdir(star_folder)

        fasta_files = glob.glob(f'{fasta_folder}/*.nextflow.genome.fa')
        fasta_files = ' '.join(fasta_files)
        gtf_file = glob.glob(f'{gtf_folder}/*.gtf')
        gtf_file = gtf_file[0]

        #Build index
        genome_index_basename = '.'.join([species, assembly, 'dna', release, 'STAR_index'])
        os.makedirs(genome_index_basename)

        command = 'STAR --version > star_version.out'
        os.system(command)
        command = f'STAR --runThreadN 8 --runMode genomeGenerate --genomeDir {genome_index_basename} --genomeFastaFiles {fasta_files} --sjdbGTFfile {gtf_file} --genomeSAindexNbases {genomeSAindexNbases}'
        os.system(command)

    else:
        print('Skipping - STAR folder already exists: ' + star_folder)



####################################
# make_hicup_digest_files
####################################
def make_hicup_digest_files(hicup_folder, fasta_folder, species, assembly, release):

    if not os.path.exists(hicup_folder):
        restriction_enzymes = {
            'DpnII' : '^GATC',
            'MboI' : '^GATC',
            'EcoRI': 'G^AATTC',
            'BglII' : 'A^GATCT',
            'NcoI' : 'C^CATGG'
        }

        os.chdir(fasta_folder)
        release = 'release_' + release  
        genome_index_basename = '_'.join([species, assembly, 'dna', release])
        genome_index_basename = re.sub(r'\W+', '_', genome_index_basename)   #Remove non-word characters
        
        #Perform digest(s)
        for enzyme, seq in restriction_enzymes.items():
            command = f'hicup_digester --re1 {seq},{enzyme} --genome {genome_index_basename} --zip *.nextflow.genome.fa'
            os.system(command)

        #Move Digest files to new folder
        os.makedirs(hicup_folder)
        command = f'mv Digest*.txt.gz {hicup_folder}'
        os.system(command)

    else:
        print('Skipping - HiCUP digest folder already exists: ' + hicup_folder)



####################################
# make_parse_index
####################################
def make_parse_index(parse_folder, fasta_folder, gtf_folder, species, assembly, release):

    if not os.path.exists(parse_folder):
    
        os.makedirs(parse_folder)
        os.chdir(parse_folder)

        fasta_files = glob.glob(f'{fasta_folder}/*.nextflow.genome.fa')
        fasta_files = ' '.join(fasta_files)
        gtf_file = glob.glob(f'{gtf_folder}/*.gtf')
        gtf_file = gtf_file[0]

        #Build index
        genome_index_basename = '.'.join([species, assembly, 'dna', release, 'Parse_index'])
        os.makedirs(genome_index_basename)

        command = f'split-pipe --mode mkref --genome_name {genome_index_basename} --fasta {fasta_files} --genes {gtf_file} --output_dir {genome_index_basename}'
        print('Command:')
        print(command)
        os.system(command)

    else:
        print('Skipping - Parse folder already exists: ' + parse_folder)



####################################
# make_overview_file
####################################
def make_overview_file(genomes_to_download_list):

    genome_overview_text = ''

    for index, genomes_to_download_metadata in genomes_to_download_list.iterrows():
        species = genomes_to_download_metadata['species']
        assembly = genomes_to_download_metadata['assembly']
        release = genomes_to_download_metadata['release']
        release = str(release)
        database = genomes_to_download_metadata['database']

        release_outsubdir = genome_ref_outdir + '/'.join([species, database, assembly, 'Release_' + release])

        #Genome Name
        genome_name = species + '.' + assembly + '.release_' + release
        genome_overview_text = genome_overview_text + 'Genome_Name: ' + genome_name + '\n'

        # FASTA file(s)
        fasta_folder = release_outsubdir + f"/{folder_names['fasta']}/"  
        if os.path.exists(fasta_folder):
            fasta_file = glob.glob(f'{fasta_folder}/*.nextflow.genome.fa')
            if(len(fasta_file)):    # Anything found?
                fasta_file = fasta_file[0]
                genome_overview_text = genome_overview_text + f"\tfasta = '{fasta_file}'\n"

        # GTF file
        gtf_folder = release_outsubdir + f"/{folder_names['gtf']}/" 
        if os.path.exists(gtf_folder):
            gtf_file = glob.glob(f'{gtf_folder}/*.gtf')
            if(len(gtf_file)):    # Anything found?
                gtf_file = gtf_file[0]
                genome_overview_text = genome_overview_text + f"\tgtf = '{gtf_file}'\n"

        # Bowtie2 Index
        bowtie2_folder = release_outsubdir + f"/{folder_names['bowtie2']}/"
        if os.path.exists(bowtie2_folder):
            genome_overview_text = genome_overview_text + f"\tbowtie2 = '{bowtie2_folder}'\n"

        # HISAT2 Index
        hisat2_folder = release_outsubdir + f"/{folder_names['hisat2']}/"
        if os.path.exists(hisat2_folder):
            genome_overview_text = genome_overview_text + f"\thisat2 = '{hisat2_folder}'\n"

        # STAR Index
        star_folder = release_outsubdir + f"/{folder_names['star']}/"
        if os.path.exists(star_folder):
            genome_overview_text = genome_overview_text + f"\tstar = '{star_folder}{species}.{assembly}.dna.{release}.STAR_index/'\n"

        # HiCUP Digest
        hicup_folder = release_outsubdir + f"/{folder_names['hicup']}/"
        if os.path.exists(hicup_folder):
            genome_overview_text = genome_overview_text + f"\thicup_digest = '{hicup_folder}'\n"

    return(genome_overview_text)





####################################
# determine_effective_genome_size
####################################
# def determine_effective_genome_size(fasta_folder):
#     os.chdir(fasta_folder)
#     fasta_files = glob.glob('*.fa')
#     print('Determining the effective genome size of FASTA files in: ' + fasta_folder + '\n' + '\n'.join(fasta_files))

#     fasta_files = ' '.join(fasta_files)
#     print(os.path.realpath()) 
#     command = f'python3 ../external_scripts/unique-kmers.py -k 100 {fasta_files}'
#     print('Command: ' + command)
#     effective_genome_size = subprocess.getoutput(command)
#     effective_genome_size = effective_genome_size.split('\n')[-1].split()[-1]   #After last white space on last line 
#     print('Genome size: ' + effective_genome_size)
#     print(f'Effective genome size determined to be {effective_genome_size} bases')
#     effective_genome_size = int(effective_genome_size)

#     return(effective_genome_size)




#########################################
#########################################
# MAIN
#########################################
#########################################
def main():

    # Fistly, create the temporary folder to where 'unwanted' FASTA are moved
    # The concatenated FASTA file is retained
    #if not os.path.exists(temporary_fasta_folder):
    #    os.makedirs(temporary_fasta_folder)

    # Import genomes to download list (csv file)
    genomes_to_download_list = pd.read_csv(options.genome_list)
    print("Writing genome files to " + genome_ref_outdir)

    for index, genomes_to_download_metadata in genomes_to_download_list.iterrows():
        species = genomes_to_download_metadata['species']
        assembly = genomes_to_download_metadata['assembly']
        release = genomes_to_download_metadata['release']
        release = str(release)
        database = genomes_to_download_metadata['database']
        
        #Useful for testing:
        #species = 'saccharomyces_cerevisiae'
        #assembly = 'R64-1-1'
        #release = 105
        #release = str(release)
        #database_source = 'Ensembl'

        print('Genome: ' + species + ' ' + assembly + ' (' + release + ')')
        release_outsubdir = genome_ref_outdir + '/'.join([species, database, assembly, 'Release_' + release])

        # Download FASTA
        fasta_folder = release_outsubdir + f"/{folder_names['fasta']}/"

        if not os.path.exists(fasta_folder):
            os.makedirs(fasta_folder)
            os.chdir(fasta_folder)
            download_ensembl_fasta(species, assembly, release)
            download_ensembl_fasta_cdna(species, assembly, release)
            #os.system('gunzip *.fa.gz')
        else:
            print('Skipping - FASTQ folder already exists: ' + fasta_folder)


        # Download GTF
        gtf_folder = release_outsubdir + f"/{folder_names['gtf']}/"

        if not os.path.exists(gtf_folder):
            os.makedirs(gtf_folder)
            os.chdir(gtf_folder)
            download_ensembl_gtf(species, assembly, release)
            os.system('gunzip *.gz')

        else:
            print('Skipping - GTF folder already exists: ' + gtf_folder)

        # Build Bowtie2 index files
        if(genomes_to_download_metadata['bowtie2']):
            bowtie2_folder = release_outsubdir + f"/{folder_names['bowtie2']}/"
            make_bowtie2_index(bowtie2_folder, fasta_folder, species, assembly, release)


        # Build HISAT2 index files
        if(genomes_to_download_metadata['hisat2']):
            hisat2_folder = release_outsubdir + f"/{folder_names['hisat2']}/"
            make_hisat2_index(hisat2_folder, fasta_folder, gtf_folder, species, assembly, release)


        # Build STAR index files
        if(genomes_to_download_metadata['star']):
            star_folder = release_outsubdir + f"/{folder_names['star']}/"
            genome_size = determine_genome_size(fasta_folder)
            make_star_index(star_folder, fasta_folder, gtf_folder, species, assembly, release, genome_size)

        
        # Create HiCUP digest files
        if(genomes_to_download_metadata['hicup']):
            hicup_folder = release_outsubdir + f"/{folder_names['hicup']}/"
            make_hicup_digest_files(hicup_folder, fasta_folder, species, assembly, release)


        # Build Parse index files
        if(genomes_to_download_metadata['parse']):
            parse_folder = release_outsubdir + f"/{folder_names['parse']}/"
            make_parse_index(parse_folder, fasta_folder, gtf_folder, species, assembly, release)
        

    # Make overview file to be used in the config file
    genome_overview_text = make_overview_file(genomes_to_download_list)
    genome_overview_file = genome_ref_outdir + 'genome_overview.txt'

    with open(genome_overview_file, 'w') as f_out:
        f_out.write(genome_overview_text)
    f_out.close()    

    print('Done')

if __name__ == "__main__":
    main()
