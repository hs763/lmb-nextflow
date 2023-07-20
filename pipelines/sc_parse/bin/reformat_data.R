#rm(list=ls())

# Setup
args <- commandArgs(trailingOnly = TRUE)
sample_info_file <- args[1]
#sample_info_file <- 'sample_info_sCell.tab'

sample_info <- read.delim(sample_info_file, sep = " ", header = FALSE, stringsAsFactors = FALSE)   # SPACE delimited!
sample_names <- unique(sample_info$V1)

output <- data.frame('dummy', 'dummy', 'dummy', stringsAsFactors = FALSE)   # Initialise with a dummy row

for (i in 1:length

(sample_names)){
  filt <- sample_info$V1  == sample_names[i]
  wells <- sample_info[filt, ]$V2
  wells <- paste(wells, collapse=",")
  
  new_row <- c(i, wells, sample_names[i])
  print(new_row)
  output[nrow(output) + 1,] <- new_row
}
colnames(output) <- c("Sample_number", "Sample_well", "Sample_name")
output <- output[-1,]   # Remove dummy row
row.names(output) <- NULL    # Re-index

write.table(output, file='sample_info_reformat.tsv', 
            sep = "\t",
            row.names=FALSE, quote=FALSE)

print('Done')
