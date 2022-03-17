# Python3 script to download genomes

#It assumes ENSEMBL download unless specified elsewhere
# Input variable:
# Species
# Assembly name
# Release
# Database name (typically ENSEMBL)
# Genome Link (if not ENSEMBL)
# GTF link (if not ENSEMBL)
# Processing columns (1 or 0)

# Need in path:
# lftp
# extract_splice_sites.py
# extract_exons.py
# bowtie2-build
# hisat2-build
# STAR
# hicup_digester
# gzip

import os
import glob
import re
import pandas as pd

VERSION = "0.0.1_dev"

current_working_directory = os.getcwd()
genome_ref_outdir = current_working_directory
genome_ref_outdir = genome_ref_outdir + '/Genome_References/'


####################################
# download_ensembl_fasta
####################################
def download_ensembl_fasta(species, assembly, release):
    print('Downloading FASTA files: ' + species + ' ' + assembly + ' (' + str(release) + ')')

    ensembl_base = 'http://ftp.ensembl.org/pub/release-'
    download_folder = ensembl_base + release + '/fasta/' + species + '/dna/'

    print("Downloading chromosomal sequences")
    command = 'lftp -e "mget *.dna.chromosome.*fa.gz; bye" '
    command = command + download_folder
    os.system(command)

    print("Downloading nonchromosomal sequences")
    command = 'lftp -e "mget *.dna.nonchromosomal.*fa.gz; bye" '
    command = command + download_folder
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
        os.chdir(fasta_folder)
        fasta_files = glob.glob('*.fa')
        fasta_files = ','.join(fasta_files)

        #Build index
        genome_index_basename = '.'.join([species, assembly, 'dna', release])
        command = f'bowtie2-build {fasta_files} {genome_index_basename} > bowtie2-build.out'
        os.system(command)

        #Move index files to new folder
        os.makedirs(bowtie2_folder)
        command = f'mv *.bt2 {bowtie2_folder}'
        os.system(command)
        command = f'mv bowtie2-build.out {bowtie2_folder}'
        os.system(command)
    else:
        print('Skipping - Bowtie2 folder already exists: ' + bowtie2_folder)



####################################
# make_hisat2_index
####################################
def make_hisat2_index(hisat2_folder, fasta_folder, gtf_folder, species, assembly, release):
    
    if not os.path.exists(hisat2_folder):

        #Make splice sites and exons file
        os.chdir(gtf_folder)
        gtf_file = glob.glob('*.gtf')[0]
        splice_site_file = gtf_file[:-3] + 'ss'
        exon_file = gtf_file[:-3] + 'exon'

        command = f'extract_splice_sites.py {gtf_file} > {splice_site_file}'
        os.system(command)     
        command = f'extract_exons.py {gtf_file} > {exon_file}'
        os.system(command)

        # Make HISAT2 index
        os.chdir(fasta_folder)
        fasta_files = glob.glob('*.fa')
        fasta_files = ','.join(fasta_files)
        genome_index_basename = '.'.join([species, assembly, 'dna', release])
        command = f'hisat2-build {fasta_files} {genome_index_basename} > hisat2-build.out'
        os.system(command)

        #Move index files to new folder
        os.makedirs(hisat2_folder)
        command = f'mv *.ht2 {hisat2_folder}'
        os.system(command)
        command = f'mv hisat2-build.out {hisat2_folder}'
        os.system(command)

    else:
        print('Skipping - HISAT2 folder already exists: ' + hisat2_folder)



####################################
# make_star_index
####################################
def make_star_index(star_folder, fasta_folder, gtf_folder, species, assembly, release):

    if not os.path.exists(star_folder):

        os.makedirs(star_folder)
        os.chdir(star_folder)

        fasta_files = glob.glob(f'{fasta_folder}/*.fa')
        fasta_files = ' '.join(fasta_files)
        gtf_file = glob.glob(f'{gtf_folder}/*.gtf')
        gtf_file = gtf_file[0]

        #Build index
        genome_index_basename = '.'.join([species, assembly, 'dna', release, 'STAR_index'])
        os.makedirs(genome_index_basename)

        command = f'STAR --runThreadN 8 --runMode genomeGenerate --genomeDir {genome_index_basename} --genomeFastaFiles {fasta_files} --sjdbGTFfile {gtf_file}'
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
            command = f'hicup_digester --re1 {seq},{enzyme} --genome {genome_index_basename} --zip *.fa'
            os.system(command)

        #Move Digest files to new folder
        os.makedirs(hicup_folder)
        command = f'mv Digest*.txt.gz {hicup_folder}'
        os.system(command)

    else:
        print('Skipping - HiCUP digest folder already exists: ' + hicup_folder)



#########################################
#########################################
# MAIN
#########################################
#########################################

def main():

    # Import genomes to download list (csv file)
    genomes_to_download_listfile = 'genomes_to_download.csv'
    genomes_to_download_list = pd.read_csv(genomes_to_download_listfile)
   # print(genomes_to_download_list)

    print("Writing genome files to " + genome_ref_outdir)
    #make_non_existant_dir(output_directory)

        
    for index, genomes_to_download_metadata in genomes_to_download_list.iterrows():

        species = genomes_to_download_metadata['species']
        assembly = genomes_to_download_metadata['assembly']
        release = genomes_to_download_metadata['release']
        release = str(release)
        database = genomes_to_download_metadata['database']
        #species = 'saccharomyces_cerevisiae'
        #assembly = 'R64-1-1'
        #release = 105
        #release = str(release)
        #database_source = 'Ensembl'

        print('Genome: ' + species + ' ' + assembly + ' (' + release + ')')
        release_outsubdir = genome_ref_outdir + '/'.join([database, species, assembly, 'Release_' + release])

        # Download FASTA
        fasta_folder = release_outsubdir + '/FASTA/'

        if not os.path.exists(fasta_folder):
            os.makedirs(fasta_folder)
            os.chdir(fasta_folder)
            download_ensembl_fasta(species, assembly, release)
            os.system('gunzip *.fa.gz')
        else:
            print('Skipping - FASTQ folder already exists: ' + fasta_folder)


        # Download GTF
        gtf_folder = release_outsubdir + '/GTF/'

        if not os.path.exists(gtf_folder):
            os.makedirs(gtf_folder)
            os.chdir(gtf_folder)
            download_ensembl_gtf(species, assembly, release)
            os.system('gunzip *.gz')

        else:
            print('Skipping - GTF folder already exists: ' + gtf_folder)

        # Build Bowtie2 index files
        if(genomes_to_download_metadata['bowtie2']):
            bowtie2_folder = release_outsubdir + '/Bowtie2/'
            make_bowtie2_index(bowtie2_folder, fasta_folder, species, assembly, release)


        # Build HISAT2 index files
        if(genomes_to_download_metadata['hisat2']):
            hisat2_folder = release_outsubdir + '/HISAT2/'
            make_hisat2_index(hisat2_folder, fasta_folder, gtf_folder, species, assembly, release)


        # Build STAR index files
        if(genomes_to_download_metadata['star']):
            star_folder = release_outsubdir + '/STAR/'
            make_star_index(star_folder, fasta_folder, gtf_folder, species, assembly, release)

        
        # Create HiCUP digest files
        if(genomes_to_download_metadata['hicup']):
            hicup_folder = release_outsubdir + '/HiCUP_digest/'
            make_hicup_digest_files(hicup_folder, fasta_folder, species, assembly, release)

         

    print('Done')



if __name__ == "__main__":
    main()

