

# Setup
args <- commandArgs(trailingOnly = TRUE)
print(args)
print(args[2])
#path2data <- 'DGE_unfiltered/'    # Use data unfiltered by the Parse pipeline
#path2data <- 'results/split_pipe_test/all-well/DGE_unfiltered/'
#sample_info_file <- 'sample_info_sCell.tab'

path2data <- args[1]
sample_info_file <- args[2]

# Import data
sample_info <- read.table(sample_info_file, sep = "\t", header = TRUE)

metadata  <- read.csv(paste0(path2data, "/cell_metadata.csv"))   # Information about each cell including the cell barcode, species, sample, well in each round of barcoding, and number of transcript/genes detected.

#print(sample_info)
#print(metadata)
print(nrow(sample_info))

print('Done R!')