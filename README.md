# Mitogenome Pipeline


## Dependencies

- SRA toolkit (optional)
- Python
- perl
- FastQC
- Trimmomatic
- Samtools
- BWA
- Stampy
- NOVOplasty

## Setup

The first step necessary to prepare to run the pipeline is to select 
or create a folder in which the project will be conducted. It is 
important that the name of the folder does not contain any SPACES! 
From here on out in these instructions, this folder will be referred 
to as your "project folder".

Next, within your project folder, create the following two folders 
(named EXACTLY as listed below, including identical capitalization):
- species-fetch
- references
- mitogenome\_pipeline

Now, you will copy the following files into the mitogenome\_pipeline folder:
- novoplasty_template.txt
- pipe_config_template.txt
- pipeline.sh
- sam_depth.sh

## Program Breakdowns

### Pipeline

Also includes _pipelineRedoAssembly.sh_
which is identical except it marks files as being redos

\*extra steps for large files  
\#calls on an executable/extra file (see further down)

-> FastQC  
-> Trimmomatic  
-> FastQC on trimmed reads  
  
-> BWA*  
-> calculate mapping stats on BWA*#  
-> Stampy*  
-> calculate mapping stats on Stampy*#  
  
-> filter stampy alignment using samtools*  
-> calculate stats on filetered reads*  
-> convert bam file to reads 1&2 fastqc files* 
  
-> generate NOVOplasty configuration file#  
-> run NOVOplasty assembly step  

### directNOVO.sh

Pipeline version that skips BWA and Stampy steps.

-> FastQC  
-> Trimmomatic  
-> FastQC on trimmed reads  
-> unzip fq.gz files to reads 1&2 fastqc files*  
-> generate NOVOplasty configuration file#  
-> run NOVOplasty assembly step


### realign.sh
Used to align filtered or assembled mitochondrial
reads to assembled mitogenome to look at pipeline performance.

### realign\_fullSag.sh
used to align filtered or assembled mitochondrial
reads to assembled sagrei genome to look at pipeline performance.

### univ\_sam\_depth.sh
Universal samtools depth calculator program that
is called by full-length _pipeline.sh_.

### univ\_config\_generator.sh/big\_config\_generator.sh
Generates NOVOplasty configuration file using the
template found in _univ\_configuration\_novo.sh_. One difference is
that the big generator also inputs a memory limit.

# Post-pipeline analysis steps

## Running MrB to set Burn-in
- make sure you have modified the .nex from amarel to be set to doing burn-in after lookng at the RWTY output
- move the mrb executable to the folder of amarel output
- use the command line to ``cd`` to the folder
- type ``./mrb``
- in the MrB window, type the command ``exe <filename_of_nex__file>.nex``

## Formatting for exporting from Figtree
\> Tree > Decreasing Node Order
- Set Tip labels to 12pt font
- Turn on branch lebels and set to display pp, Font size at 8
- Set scale bar to display Scale Range of 0.5

## Setup of Data and Using Astral

- To run Astral on the Newick file, use the command format:

``java -jar /Applications/Astral/astral.5.7.8.jar -i <directory_of_file>/<file_name>.tre -o <directory_of_output>/<out_filename>.tre 2><directory_of_output>/<out_filename>_Astral.log``



