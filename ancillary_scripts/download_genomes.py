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

import os

VERSION = "0.0.1_dev"

current_working_directory = os.getcwd()
output_directory = current_working_directory




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
    print('Downloading GTF file: ' + species + ' ' + assembly + ' (' + str(release) + ')')

    ensembl_base = 'http://ftp.ensembl.org/pub/release-'
    download_folder = ensembl_base + release + '/gtf/' + species + '/'

    print("Downloading GTF")
    command = 'lftp -e "mget *.' + release + '.gtf.gz; bye" '
    command = command + download_folder
    os.system(command)




#########################################
#########################################
# MAIN
#########################################
#########################################

def main():

    print(output_directory)

    species = 'saccharomyces_cerevisiae'
    assembly = 'R64-1-1'
    release = 105

    release = str(release)

    #download_ensembl_fasta(species, assembly, release)
    #download_ensembl_gtf(species, assembly, release)


if __name__ == "__main__":
    main()

