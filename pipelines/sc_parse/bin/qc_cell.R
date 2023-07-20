# R script for performing QC on single cell PARSE datasets


# Import libraries
library(scran)
library(irlba)
library(Rtsne)
library(Matrix)
library(ggplot2)
library(biomaRt)
library(viridis)
library(scDblFinder)
library(umap)
library(reticulate)
library(rlist)

umap = import('umap')   # Connect to Python3 umap library using R reticulate


# Setup
args <- commandArgs(trailingOnly = TRUE)

#path2data <- 'DGE_unfiltered/'    # Use data unfiltered by the Parse pipeline
path2data <- args[1]
#sample_info_file <- 'sample_info_sCell.tab'
sample_info_file <- args[2]

outdir = 'qc_cell_outdir'


# Import data
sample_info <- read.table(sample_info_file, sep = "\t", header = TRUE)
counts    <- t(readMM(paste0(path2data, "/DGE.mtx")))    # Sparse matrix with cell-gene counts. AFTER TRANSPOSING: each row corresponds to a gene and each column corresponds to a cell   
genes     <- read.csv(paste0(path2data, "/all_genes.csv"))    # Gene name, gene id, and genome for each column in DGE.mtx. This file is the same as the file in the reference genome dir
metadata  <- read.csv(paste0(path2data, "/cell_metadata.csv"))   # Information about each cell including the cell barcode, species, sample, well in each round of barcoding, and number of transcript/genes detected.

lib.sizes <- colSums(counts)   # Total reads for each cell
ngenes    <- colSums(counts > 0)    # Number genes in each cells with a score >0

#dim(counts)
#[1] 62704 1303455
print(paste('Number of genes: ', nrow(counts)))
print(paste('Number of cells: ', ncol(counts)))

dim(counts[,ngenes > 400])
#[1] 62704 46906
print(paste('Number of cells with >400 expressed genes', ncol(counts[,ngenes > 400])))

sample_bc1_well <- rep(NA, nrow(metadata))        
sample_number   <- rep(NA, nrow(metadata))
sample_name     <- rep(NA, nrow(metadata))
condition       <- rep(NA, nrow(metadata))

samples <- unique(sample_info$Sample_well)
for (i in 1:length(samples)){
  sample_bc1_well[metadata$bc1_well %in% unlist(strsplit(samples[i],split=","))] <- sample_info$Sample_well[i]
  sample_number[metadata$bc1_well %in% unlist(strsplit(samples[i],split=","))]   <- sample_info$Sample_number[i]
  sample_name[metadata$bc1_well %in% unlist(strsplit(samples[i],split=","))]     <- sample_info$Sample_name[i]
}
sample_name <- gsub(" ","_",sample_name)

submeta <- data.frame(rlist::list.rbind(strsplit(sample_name, split="_")))
colnames(submeta) <- c("batch", "day", "replicate")
submeta$day <- gsub("d","",submeta$day)

metadata <- data.frame(cbind(metadata, lib.sizes, sample_number, sample_bc1_well, sample_name, submeta))

# Bespoke renaming
#condition[which(metadata$day == 45)] <- "CTRL_45"
#condition[which(metadata$day == 48)] <- "DISS_48"
#condition[which(metadata$day == 55 & (metadata$replicate == "CTRLA" | metadata$replicate == "CTRLB" | metadata$replicate == "CTRL" | metadata$replicate == "Escapee"))] <- "CTRL_55"
#condition[which(metadata$day == 55 & (metadata$replicate == "DISSA" | metadata$replicate == "DISSB"))] <- "DISS_55"
#condition[which(metadata$day == 55 & (metadata$replicate == "Embed" | metadata$replicate == "Agar"))]  <- "EMB_55"
#condition[which(metadata$day == 70 & (metadata$replicate == "CTRLA" | metadata$replicate == "CTRLB"))] <- "CTRL_70"
#condition[which(metadata$day == 70 & (metadata$replicate == "DISSA" | metadata$replicate == "DISSB"))] <- "DISS_70"

metadata <- cbind(metadata,condition)

#setwd('/mnt')   # Move to host binding folder in container

dir.create(outdir)

# Make a box-whisker plot for each sample
plot_df <- metadata
ggplot(plot_df, aes (x = factor(sample_name), y = as.numeric(lib.sizes))) +
  geom_boxplot() +
  theme_bw() +  coord_flip() +
  labs(x = "Sample", y = "Number of UMIs") +
  scale_y_log10(breaks = c(100, 1000, 5000, 10000, 50000, 100000),
    labels = c("100","1,000", "5,000", "10,000", "50,000", "100,000"))

outfile = paste(outdir, "UMIsBySample_beforeQC.pdf", sep="/")
ggsave(outfile)
 

# Plot number of expressed genes vs UMIs (drop/keep cutoff > 400) 
outfile = paste(outdir, "cell_complexity.pdf", sep="/")
pdf(outfile)
qplot(lib.sizes, ngenes, col = ifelse(ngenes < 400, "drop", "keep")) +
  scale_x_log10() +
  scale_y_log10() +
  theme_minimal() + 
  theme(text = element_text(size=20),legend.position = "none")  +
  labs(x = "UMI count", y = "Number of expressed genes") +
  scale_color_manual(values = c("drop" = "grey50", "keep" = "black"), name = "")
dev.off()

dim(counts[,ngenes > 400 & lib.sizes > 500])
#[1] 62704 43180
print(paste('Number of cells with >400 expressed genes and total reads > 500)', ncol(counts[,ngenes > 400 & lib.sizes > 500])    ))

# Filter out genes with few observations
counts   <- counts[,ngenes > 400 & lib.sizes > 500]
metadata <- metadata[ngenes > 400 & lib.sizes > 500,]
lib.sizes <- colSums(counts)
ngenes    <- colSums(counts > 0)


# Plot histogram of:
# 'Number genes in each cells with a score >0' / 'Total reads for each cell'
# Histogram shows this ratio for each cell
outfile = paste(outdir, "hist_ngenes_libsize_ratio.pdf", sep="/")
pdf(outfile)
hist(ngenes/lib.sizes)
dev.off()

# Filter out cells where:
# 'Number genes in each cells with a score >0' / 'Total reads for each cell' >= 0.9
counts   <- counts[,ngenes/lib.sizes < 0.9]
metadata <- metadata[ngenes/lib.sizes < 0.9,]
lib.sizes <- colSums(counts)
ngenes    <- colSums(counts > 0)
print('Filtering out cells in which reads tend to map uniformly to genes')
print(paste('Number of genes: ', nrow(counts)))
print(paste('Number of cells: ', ncol(counts)))


# Get ENSEMBL annotations
ensembl <- useEnsembl(biomart = "ensembl",  dataset = "hsapiens_gene_ensembl",mirror="useast")

gene_map  <- getBM(attributes=c("ensembl_gene_id", "hgnc_symbol", "chromosome_name"),
  filters = "hgnc_symbol", values = genes$gene_name, mart = ensembl)


# Remove cells with a higher than expected number of mitochondrial reads
mt.index    <- gene_map$chromosome_name == "MT"
mt.counts   <- counts[which(genes$gene_name %in% gene_map$hgnc_symbol[mt.index]), ]
mt.fraction <- colSums(mt.counts)/lib.sizes
mt.p   <- pnorm(mt.fraction, mean = median(mt.fraction), sd = mad(mt.fraction), lower.tail = FALSE)


# Decide on FDR for this threshold
#mt.lim <- min(mt.fraction[which(p.adjust(mt.p, method = "fdr") < 0.05)])
mt.lim <- min(mt.fraction[which(p.adjust(mt.p, method = "fdr") < 0.001)])
print(paste("MT filtering limit set to using statistical test:", mt.lim))

metadata <- data.frame(cbind(metadata,mt.fraction))

# Plot mitochondrial threshold
outfile = paste(outdir, "mtreadfraction1.pdf", sep="/")
pdf(outfile)
qplot(lib.sizes, mt.fraction, col = ifelse(mt.fraction>mt.lim, "drop", "keep")) +
  scale_x_log10() +
  labs(x = "UMI count", y = "MT read fraction") +
  theme_minimal() + 
  theme(text = element_text(size=20),legend.position = "none")  +
  scale_color_manual(values = c("drop" = "grey50", "keep" = "black"), name = "")
dev.off()

print(paste('Number of cells after applying MT threshold: ', ncol(counts[,mt.fraction < mt.lim])))
#dim(counts[,mt.fraction < mt.lim])
#[1] 62704 41576

#dim(counts[,mt.fraction < 0.2])
print("Nevertheless, setting MT threshold to 0.2!")
mtlim <- 0.2
#[1] 62704 42908
print(paste('Number of cells after applying MT threshold: ', ncol(counts[,mt.fraction < mt.lim])))



# Read data into Bioconductor package SingleCellExperiment
tryCatch( 
  expr = {
    sce <- SingleCellExperiment(list(counts=counts[,mt.fraction < mt.lim]),
      colData=DataFrame(metadata[mt.fraction < mt.lim,]))
    rownames(sce) <- genes$gene_id

    rownames(genes) <- rownames(sce)
    rowData(sce) <- DataFrame(genes)

    colnames(sce) <- metadata$bc_wells[mt.fraction  < mt.lim]
    colData(sce)  <- DataFrame(metadata[mt.fraction < mt.lim,])

    lib.sizes <- colSums(counts(sce))
    sce_filt  <- sce[calculateAverage(sce)>0.01,]

    clusts <- as.numeric(quickCluster(sce_filt, method = "igraph", min.size = 100))

    min.clust <- min(table(clusts))/2
    new_sizes <- c(floor(min.clust/3), floor(min.clust/2), floor(min.clust))
    sce_filt  <- computeSumFactors(sce_filt, clusters = clusts, sizes = new_sizes, max.cluster.size = 3000)

    sizeFactors(sce) <- sizeFactors(sce_filt)

    # Create Size Factors plot
    outfile = paste(outdir, "sizefactors.pdf", sep="/")
    pdf(outfile)
    ggplot(data = data.frame(X = lib.sizes, Y = sizeFactors(sce)), mapping = aes(x = X, y = Y)) +
      geom_point() +
      scale_x_log10(breaks = c(500, 2000, 5000, 10000, 30000), labels = c("5,00", "2,000", "5,000", "10,000", "30,000") ) +
      scale_y_log10(breaks = c(0.2, 1, 5)) +
      theme_minimal() +
      theme(text = element_text(size=20))  +
      labs(x = "Number of UMIs", y = "Size Factor")
    dev.off()
  },
  error = function(e){ 
    message('Caught an error!')
    print(e)
  },
  warning = function(w){
    message('Caught an warning!')
    print(w)
  }
)






library(tidyverse)
library(BiocParallel)


tryCatch( 
    expr = {
      # Find doublets
      bp <- MulticoreParam(25, RNGseed=1234)
      bpstart(bp)
      sce <- scDblFinder(sce, samples="bc1_well", dbr=.05, dims=30, BPPARAM=bp)
      bpstop(bp)
      table(sce$scDblFinder.class)
      #singlet doublet 
      #  39090    2486 

      bpstart(bp)
      sce_test <- scDblFinder(sce, samples="bc1_well", dims=30, BPPARAM=bp)
      bpstop(bp)
      table(sce_test$scDblFinder.class)
      #singlet doublet 
      #  40063    1513

      sce_filt <- sce[calculateAverage(sce)>0.01,]
      sce_filt <- logNormCounts(sce_filt)

      decomp  <- modelGeneVar(sce_filt)
      hvgs    <- rownames(decomp)[decomp$FDR < 0.1]
      #length(hvgs)
      #[1] 625
      pca     <- prcomp_irlba(t(logcounts(sce_filt[hvgs,])), n = 30)
      rownames(pca$x) <- colnames(sce_filt)
      tsne <- Rtsne(pca$x, pca = FALSE, check_duplicates = FALSE, num_threads=30)
      layout  <- umap(pca$x, method="umap-learn", umap_learn_args=c("n_neighbors", "n_epochs", "min_dist"), n_neighbors=30, min_dist=.25)

      df_plot <- data.frame(
      colData(sce),
      doublet  = colData(sce)$scDblFinder.class,
      tSNE1    = tsne$Y[, 1],
      tSNE2    = tsne$Y[, 2], 
      UMAP1 = layout$layout[,1],
      UMAP2 = layout$layout[,2] 
      )

      # Plot doublets on tsne plot
      plot.index <- order(df_plot$doublet)
      ggplot(df_plot[plot.index,], aes(x = tSNE1, y = tSNE2, col = factor(doublet))) +
        geom_point(size = 0.4) +
        scale_color_manual(values=c("gray","#0169c1"), name = "") +
        labs(x = "Dim 1", y = "Dim 2") +
        theme_minimal() + #theme(legend.position = "none") +
        theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank()) +
        theme(axis.title.y=element_blank(), axis.text.y=element_blank(), axis.ticks.y=element_blank()) +
        guides(colour = guide_legend(override.aes = list(size=7)))
      
      outfile = paste(outdir, "tsne_doublets.pdf", sep="/")
      ggsave(outfile)

      # Plot doublets on UMAP
      ggplot(df_plot[plot.index,], aes(x = UMAP1, y = UMAP2, col = factor(doublet))) +
        geom_point(size = 0.4) +
        scale_color_manual(values=c("gray","#0169c1"), name = "") +
        labs(x = "Dim 1", y = "Dim 2") +
        theme_minimal() + #theme(legend.position = "none") +
        theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank()) +
        theme(axis.title.y=element_blank(), axis.text.y=element_blank(), axis.ticks.y=element_blank()) +
        guides(colour = guide_legend(override.aes = list(size=7)))
      
      outfile = paste(outdir, "umap_doublets.pdf", sep="/")
      ggsave(outfile)

      # Plot box-whisket plot of number of reads in singlet / doublet cells
      ggplot(df_plot, aes(x=doublet, y=log10(lib.sizes))) + 
        geom_boxplot() +
        labs(x = "", y = "log10(Library size)") 

      outfile = paste(outdir, "boxplot_doublets.pdf", sep="/")
      ggsave(outfile)

      doublet_score <- colData(sce)$scDblFinder.score
      doublet_class <- colData(sce)$scDblFinder.class

      sce_qc <- sce[,colData(sce)$scDblFinder.class == "singlet"]


      # Plot UMIs by sample after QC filtering
      ggplot(data.frame(colData(sce_qc)), aes (x = factor(sample_name), y = as.numeric(lib.sizes))) +
        geom_boxplot() +
        theme_bw() +  coord_flip() +
        labs(x = "Sample", y = "Number of UMIs") +
        scale_y_log10(breaks = c(100, 1000, 5000, 10000, 50000, 100000),
          labels = c("100","1,000", "5,000", "10,000", "50,000", "100,000"))

      outfile = paste(outdir, "UMIsBySample_afterQC.pdf", sep="/")
      ggsave(outfile)

      # Plot UMI density for each sample after QC filtering
      outfile = paste(outdir, "UMIsDensityBySample_afterQC.pdf", sep="/")
      pdf(outfile, width=12)

      data.frame(colData(sce_qc)) %>% 
          ggplot(aes(color=sample_name, x=lib.sizes, fill= sample_name)) + 
          geom_density(alpha = 0.2) + 
          scale_x_log10() + 
          theme_classic() +
          ylab("Cell density") +
          geom_vline(xintercept = 400)
      dev.off()

      # Barchart of the number of cells for each sample after QC
      ggplot(data.frame(colData(sce_qc)), aes (x = factor(sample_name))) +
        geom_bar() +
        theme_bw() +  coord_flip() +
        labs(x = "Sample", y = "Number of Cells") 
      
      outfile = paste(outdir, "CellsBySample_afterQC.pdf", sep="/")
      ggsave(outfile)

      # Barchart of the number of cells for each condition after QC (maybe just 1 condition?)
      ggplot(data.frame(colData(sce_qc)), aes (x = factor(condition))) +
        geom_bar() +
        theme_bw() +  coord_flip() +
        labs(x = "Condition", y = "Number of Cells") 

      outfile = paste(outdir, "CellsByCondition_afterQC.pdf", sep="/")
      ggsave(outfile)

      table(colData(sce_qc)$condition)   # Print nothing out if no condition?
      #CTRL_45 CTRL_55 CTRL_70 DISS_48 DISS_55 DISS_70  EMB_55 
      #   7746    7742    2174    1528    9439    7741    5206

      colData(sce) <- colData(sce)[,-grep("scDblFinder",colnames(colData(sce)))]

      colData(sce)$doublet_score <- doublet_score
      colData(sce)$doublet_class <- doublet_class

      # Plot the histogram of doublet score
      outfile = paste(outdir, "histogram_of_doublet_score.pdf", sep="/")
      pdf(outfile)
      hist(doublet_score)
      dev.off()
    },
    error = function(e){ 
      message('Caught an error!')
      print(e)
    },
    warning = function(w){
      message('Caught an warning!')
      print(w)
    }
  )

#saveRDS(sce,paste0(path2data,"sce.rds"))

############################################
######## Generate output for sctour ########
#scTour: a deep learning architecture for robust inference and accurate prediction of 
#cellular dynamics




tryCatch( 
    expr = {
      sctour_dir <- paste0(outdir, "sctour", sep="/") 
      if (!file.exists(sctour_dir)){
        dir.create(sctour_dir)
      } 
      #setwd(sctour_dir)

      outfile = paste(sctour_dir, "sce.rds", sep="/")
      saveRDS(sce, outfile)

      #setwd("/home/swingett/data1_wingett/Parse/post_pipeline_analysis/sctour")

      #sce <- readRDS(paste0(path2data,"sce.rds"))
      sce <- sce[,colData(sce)$doublet_class == "singlet"]

      outfile = paste(sctour_dir, "raw_counts.mtx", sep="/")
      writeMM(t(counts(sce)), outfile)
      
      outfile = paste(sctour_dir, "cells.txt", sep="/")
      writeLines(colnames(sce), "cells.txt")
      
      outfile = paste(sctour_dir, "genes.txt", sep="/")
      writeLines(rownames(sce), outfile)

      meta <- cbind(cell=rownames(colData(sce)), colData(sce))
      outfile = paste(sctour_dir, "metadata.tab", sep="/")
      write.table(data.frame(meta), file=outfile, sep="\t", row.names=FALSE, quote=FALSE)

      sce_filt <- sce[calculateAverage(sce)>0.01,]
      sce_filt <- logNormCounts(sce_filt)

      outfile = paste(sctour_dir, "norm_counts.mtx", sep="/")
      writeMM(t(logcounts(sce_filt)), outfile, sep="\t")

      outfile = paste(sctour_dir, "cells_norm.txt", sep="/")
      writeLines(colnames(sce_filt), outfile)

      outfile = paste(sctour_dir, "genes_norm.txt", sep="/")
      writeLines(rowData(sce_filt)$gene_name, outfile)
    },
    error = function(e){ 
      message('Caught an error!')
      #print(e)
    },
    warning = function(w){
      message('Caught an warning!')
      #print(w)
    }
  )

print("\n")
Sys.sleep(1)
print('Done')

