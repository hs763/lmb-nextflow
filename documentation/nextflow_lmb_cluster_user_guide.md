![LMB_Logo](assets/institute_logo.svg)

# Running NGS pipelines with Nextflow on the LMB cluster

## Introduction
For more than a decade Next Generation Sequencing (NGS) has been used ever more frequently in molecular biology and has been adapted for use in new experimental protocols and applications.  Processing and NGS datasets is far from trivial however, requiring substantial computation resources, in terms of data storage, RAM (working memory) and processing power.  

Here at the LMB we have a powerful compute cluster available to researchers which has been purposed for running NGS computational pipelines (note: a pipeline is simply a sequence of computational operations).  This guide provides an overview of how to access the computer cluster and run these pipelines. 

## What is NGS data?

Next-generation sequencing (NGS) is a massively parallel sequencing technology that offers ultra-high throughput.  The technology is used to determine the genomic sequence of an orgainism, the expression levels of all the genes in a tissues or to provide insigts into epigenetic modifications or conformational changes.

The most frequently used NGS technology is short reads () from Illumina or longer reads from PacBio or Oxford Nanopore.  

The standard data output from these sequences is [FASTQ](https://en.wikipedia.org/wiki/FASTQ_format).  These FASTQ file are essentially text files which record the sequence of each read, and an associated quality score which provides an estimate of the relaiblity of each base call.  It is these files that are processed by NGS pipelines (usually conjuction with geneome reference files and relevent metadata).


## What is a compute cluster?

A computer cluster is a set of computers that work together so that they can be regarded as a single system.  These inter-connected computers (known as nodes) run software to coordinate programs across the computers, so they can work together to perform complex tasks.

Data processing is performed on compute nodes, but acccess to the cluster is via a head node.  The user passes commands to the head nodes and then head node instructs one or more (often many) compute nodes to perform the actual intensive calculations.

[image here?]

## Getting a cluster account
1. The first thing you need to do is get an account on the compute cluster via an [online form](http://nis1.lmb.internal/cgi-bin/newaccount.cgi).

2. Once you have the account you will also need to email a member of [Scientific Computing](https://www.mrc-lmb.cam.ac.uk/scicomp/index.php?id=about) and ask that you are added to the cluster 'singularity' group.  (This is necessary from running the pre-installed NGS pipelines.)


## Logging in to the cluster 

The descriptions below describe how to access the compute cluster when working physically on-site, at the LMB.  **For remote access, you will first need to connect to the [ATG server.](https://www.mrc-lmb.cam.ac.uk/scicomp/index.php?id=ssh-x2go)** 

Gernally users will access the cluster from PCs running Windows or Macs running iOS, which require different methods to access the cluster (we assume users running Linux do not require a bespoke description of how to access the cluser)

### Accessing from an LMB-registered Mac

1. Open the 'terminal' window.  Do this by double-clicking the terminal icon (a black square with the >_ symbol in the top right corner) or press cmd+space simultaneously and then type 'terminal'in the Spotlight Search bar.

2.  The terminal window should have opened.  Here you may type in commands for your Mac to execute.  To tell your Mac to connect to the cluster, enter the following command:
     
        ssh -Y hex

Then enter your cluster password (which should have been sent to you after you registered for cluster access.)  When you successfully login, a message will be dispayed, usually infroaming qyou when you last logged in.

# Getting to grips with Linux

Unlike Macs which run the iOS operating sytem, or PCs which run the Windows, our compute cluster runs a Linux operating system.  This Linux operating system may seem unfamilair to first-time users, since it does not receive input from the user who moves a mouse pointer to click icons on the screen.  Instead the user types instructions into what is know as the 'command line' which tell the cluster as to what to do.

On your screen the commandline will look similar to the text below:

        [username@hex ~]$

Try it yourself, type the following command, tells you toady's date (remember to press enter after typing the command):
        date

So, this command-line may at first seem much less user-friendly than the more familair Windows or iOS operating systems.  But actually the command line is very versatile, allowing the user to perform complex tasks with greater ease and speed than can be acheived by dragging and dropping icons with a mouse etc.  It takes a bit of practice to become familialr with Linux 

While there are many Linux commands, users will tend to mainly use the commands listed below.

ls - list contents of a directory
cd - change directory
cp - copy
mv - move / rename files or folders
rm - remove file
mkdir - create a directory
rmdir - remove a directory
cat - print the contents of a file
nano - edit the contents of a file
pwd - print the address of the current working directory

We shan't give a more detailed overview of Linux here, for it is covered excellently in many places.  For example, try watching this [10-minute video to understand Linux](https://www.youtube.com/watch?v=J2zquYPJbWY)

There are also a series of [very short tutorials](http://info.ee.surrey.ac.uk/Teaching/Unix/) produced by the University of Surrey.  Have a quick look at the first four tutorials and you should have a good idea of the most useful Linux commands.

And finally, here is a link to a useful [Linux Cheat Sheet](http://sites.tufts.edu/cbi/files/2013/01/linux_cheat_sheet.pdf)

## First-time setup

Once you have logged-in there are a couple of commands you should run once to setup your system to be run Nextflow

1.  We recommend using the 'bash' shell by default, instead of 'tcsh'.  Don't worry about this terminology if you haven't heard this before, simply put bash and tcsh are slighly different dialects of the same language.   When you enter commands into the terminal window you have just opened (also know as the shell), using bash or tcsh will have slight different operations.  

Firstly, just check whether you are using bash or tcsh.  Enter in the command line:
        echo $SHELL

If the output reports bash, then you do not need to change the shell.  However, is tcsh is reported then enter the command below: 

2.  To set the bash shell permanently enter:

        cp ~admin/{.bashrc,.profile} $HOME
        ypchsh

Then, follow the prompts and chose /bin/bash as your shell.


2.  Add Nextflow to your path.  This simply means that when you type 'nextflow' into the command-line, your system will recognise that this is command and will subsequently run the Nextflow software.

        nano ~/.bashrc

This will open a very basic text editor and will have opened the file names .basrc.  Use the UP/DOWN arrows to go to the end of the file.  When at the end of the file, copy and past the follwoing text:

        export PATH="/net/nfs1/public/genomics/soft/bin:$PATH"

To save and exit the text editor type
ctrl + o (simultaneously pressing both buttons)
enter
ctrl + x (simultaneously pressing both buttons)

This will exit the text editor. 

3.  Logout of the cluster 

        exit

4. Log back in again to the cluster, as you did earlier (i.e. ssh -Y hex).  

5. To test your changes, enter the following:

        echo $SHELL

This should report bash as the shell and not tcsh.

6. Set up nextflow for the first time by entering the following:
   
        nextflow

This will make a series of changes to your system


7. Nextflow should now be up and running for you on the cluster.  To check, enter:
        
        nextflow

The Nextflow help message should now be printed to the screen

Sorry that was little bit complicated, but you only have to do this once.



## Cluster Commands
So, the compute cluster uses Linux as its operating system, but in addition to this a cluster needs special software to enable all the compute nodes and head node(s) to communicate with on another and the data storage arrays.  Our cluster performs this task with software called Slurm.

The basic concept is that user logs in to the head node (hex) and then uses Slurm to submit a job (compuational task) to one or more compute nodes.  Dividing work between multiple cores and nodes is a way to speed up a job (parrelelisation).

Fortunately, to use Nextflow you don't need to learn about in and depth - Nextflow uses Slurm, but acts and interface between you and Slurm.  There are a small number of Slurm commands that are useful however when trying to keep track of your running jobs.

To list the jobs running on the cluster (for all users):

        squeue

To list only your jobs running on the cluster:

     squeue -u $USER

You will notice that your jobs will be listed once you set off Nextflow pipelines.
 
# Copying data from your machine to the cluster (and vice versa)

So you've got data on your personal computer that you would like to analyse on the cluster.  How do you copy the data across?  We recommend the free software tool [Cyberduck.](https://cyberduck.io/)  Simply download the version of the software relavant to your operating system.  Open the software and create a bookmark with hex as the server.  Use an sftp connection and provide your username and password.

[video]


# Running Nextflow

# Help with Nextflow commands with GUIde-Piper

# Nextflow Pipelines

# Downloading data from public repositories

# Processing RNA-seq data

# Processing ChIP-seq data

# Processing  ATAC-seq data

![Nextflow_Logo](assets/nextflow_logo.png)
