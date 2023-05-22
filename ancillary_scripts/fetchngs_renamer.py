# Python script to create symbolic links with descriptive names to the 
# files downloaded by fetchngs (https://nf-co.re/fetchngs/1.5)
# Run in the script in the directory that CONTAINS the nf-core results folder:

import pandas as pd
import numpy as np
import os
import re

import pprint


######################################################
#Pandas Code
# Import samplesheet data
samplesheet_file = 'results/samplesheet/samplesheet.csv'
print('Reading in samplesheet: ' + samplesheet_file)
samplesheet_data = pd.read_csv(samplesheet_file)

# Filter data
columns_to_select = ['fastq_1', 'fastq_2', 'sample_description', 
                     'library_strategy', 'scientific_name']

samplesheet_data = (samplesheet_data[columns_to_select])


# Determine file description
samplesheet_data.loc[:, 'file_description'] = (samplesheet_data.loc[:, 'sample_description'] 
                                                +  '_' 
                                                + samplesheet_data.loc[:, 'scientific_name']
                                                + '_'
                                                + samplesheet_data.loc[:, 'library_strategy']
                                              )

samplesheet_data = samplesheet_data[['fastq_1', 'fastq_2', 'file_description']]
samplesheet_data['file_description'] = samplesheet_data['file_description'].str.replace(' ','_')


# Make table 1 column per file
samplesheet_data_1 = samplesheet_data[['fastq_1', 'file_description']]
samplesheet_data_1.columns = ['fastq', 'file_description']

samplesheet_data_2 = samplesheet_data[['fastq_2', 'file_description']]
samplesheet_data_2.columns = ['fastq', 'file_description']

samplesheet_data = pd.concat([samplesheet_data_1, samplesheet_data_2])
samplesheet_data = samplesheet_data.reset_index(drop=True)


# Remove empty values (single-end data)
samplesheet_data = samplesheet_data[samplesheet_data['fastq'].notnull()]

del([samplesheet_data_1, samplesheet_data_2])


#Identify the file extension
#This assumes files end .fastq.gz or _1.fastq.gz or _2.fastq.gz (or another single digit)
samplesheet_data['file_extension'] = samplesheet_data['fastq'].str.extract(r'((_\d)*\.fastq\.gz$)')[0]

if(samplesheet_data['file_extension'].isnull().values.any()):
    print("File extension not recognised")
    sys.exit()


#Create the new filename
samplesheet_data['linked_file'] = samplesheet_data['fastq'].str.replace(r'((_\d)*\.fastq\.gz$)', '', regex=True)
samplesheet_data['linked_file'] = samplesheet_data['linked_file'].str.replace(r'(/results\/fastq\/)', '/', regex=True)

samplesheet_data['linked_file'] = (samplesheet_data['linked_file'] +
                                   '_' +
                                   samplesheet_data['file_description'] +
                                   samplesheet_data['file_extension']
                                  )

samplesheet_data['linked_file'] = samplesheet_data['linked_file'].str.replace(r'([^A-z0-9\/\.\+-]+)', '_', regex=True)    # Remove not allowed characters from the ouput filename
samplesheet_data = samplesheet_data[['fastq', 'linked_file']]


# Create a python list for the original names and new names
original_fastqs = samplesheet_data['fastq'].tolist()
new_fastqs = samplesheet_data['linked_file'].tolist()
######################################################



#######################################
#Regular Python
#Create links to the files
output_folder = 'results/fastq_nice_names/'
print(f'Creating links in {output_folder}')
os.mkdir(output_folder)
os.chdir(output_folder)

for i in range(len(original_fastqs)):
    original_fastq = original_fastqs[i]
    new_fastq = new_fastqs[i]

    # Make and run the symbolic link command
    original_fastq = original_fastq.replace('results/fastq/', '../fastq/')
    new_fastq = new_fastq.replace('results/fastq/', '')

    command = f'ln -s {original_fastq} {new_fastq}'  
    print(command)
    os.system(command)

print('Done')
