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

### Preliminary file and folder setup
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

Now, you will copy the following files into the "mitogenome\_pipeline" folder:
- novoplasty_template.txt
- pipe_config_template.txt
- pipeline.sh
- sam_depth.sh

A reference mitochondrial genome is required to run the pipeline. Move 
or copy your reference genome (in .fasta format) into the "references" folder.

### Filling out the configuration file

Determine the name or ID you will to use for the read data that you will be 
assembling. This can either be a species name, or some other unique identifier, 
as long as there are NO SPACES or special characters outside of dashes and 
underscores in the name (eg. homo_sapiens , AP-run321). For our example, we 
will use _yourName_ as a place-holder. Wherever you see _yourName_ , replace 
it with the ID you have chosen.

Next, you will save a copy of the pipe_config_template.txt file in the 
"species-fetch" folder. Rename this file to _yourName_.txt

Open this file with a text editor (recommended is using Nano via the 
unix shell). You should see something that looks like the following:

<details>
<summary>Blank Configuration File</summary>

  ```
  ## Directory and file name pointing to forward illumina reads

  ## Directory and file name pointing to reverse illumina reads

  ## Length of reads from illumina run (integer)

  ## Insert length from illumina run (integer)

  ## Directory and file name pointing to the illumina adaptor file for trimmomatic to use
  /projectsc/f_geneva_1/programs/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10:4
  ## Kmer to be used for novoPlasty assembly (integer)
  33
  ## Name/ID of the species that will be the reference mt-genome

  ## Name of the reference genome file with file extension

  #### If you would like for a sub-section of the pipeline to run, set that value to 1. To not have a subsection run, set to 0 (zero). 
  ## to run FastQC, Trimmomatic, and post-trim FastQC
  1
  ## to run BWA mapping and post-bwa sorting
  1
  ## to run Stampy mapping
  1
  ## to run samtools filtering of stampy mapped reads
  1
  ## to run generation of novoplasty configuration file and assembly
  1
```
</details>

Note that some values may be pre-filled with recommended values for those 
parameters.

We will now go over how to fill in the configuration file.

<details>
<summary>WARNINGS:</summary>

  - First and foremost, it is important to remember that using SPACES 
  for any of the inputs without special actions taken will cause issues. If you 
  are just starting out using the unix shell, please ensure that any folder 
  names or file names are changed so that they do not contain spaces! This also
  applies to when you are entering parameters into the configuration file. Ensure
  no spaces are added by accident to the beginning or end of your entry, else errors 
  may occur when running the pipeline.
  
  - Next, it is also important not to tamper with the spacing of each line.
  The pipeline is designed to pull important data and variables from the entry
  lines based on line numbering/spacing, so adding extra lines or deleting them
  will cause the pipeline to not function.

</details>

The general procedure for filling in the configuration file is that the relevant 
parameter goes into the blank line below the instructions written starting with \#\#.

Each dropdown below expands inctructions for filling out each respective line in 
the configuration file:

<details> 
<summary>## Directory and file name pointing to (forward/reverse) illumina reads</summary>
  Below each of these lines, write the full file path to either the forward or reverse read 
  file for the species' whose mitochodrial genome you wish to assemble.
</details>

<details> 
<summary>## Length of reads from illumina run (integer)</summary>
  This is the integer value representing the average read length generated during the 
  sequencing run. Do not write bp or anything else, just the INTEGER.
</details>

<details> 
<summary>## Insert length from illumina run (integer)</summary>
  This is the integer value representing the average insert length generated during the 
  sequencing run. Do not write bp or anything else, just the INTEGER.
</details>

<details> 
<summary>## Directory and file name pointing to the illumina adaptor file for trimmomatic to use</summary>
  Write the full file path to the adaptor you wish to use when trimming the reads.
</details>

<details> 
<summary>## Kmer to be used for novoPlasty assembly (integer)</summary>
  Enter the integer value for the Kmer you wish NovoPlasty to use when assembling 
  the genome. We recommend starting with a value of 33.
</details>

<details> 
<summary>## Name/ID of the species that will be the reference mt-genome</summary>
  Enter a name or ID that allows you to know what reference you used when generating 
  this assembly. This does not need to be identical to the name of the reference 
  file (see below), but it should be a NAME ONLY with NO FILE EXTENSION. DO NOT USE SPACES.
  - Good example: potato_3
  - Bad examples: potato_3_r445.fasta , potato 3 r445
</details>

<details> 
<summary>## Name of the reference genome file with file extension</summary>
  Enter the FILE NAME of the reference file that will be used for the intended assembly, 
  INCLUDING FILE EXTENSION. (ie. this is when you would enter potato_3_r445.fasta ). DO 
  NOT INCLUDE FILE PATH.
</details>

### Before running the pipeline

Congratulations! You are almost at the point where you can run the pipeline!!

There are two last steps that must happen before you can run it.

First, you must make a few modifications the the pipeline.sh file.
- Open the pipeline.sh file with a text editor (Using Nano via the Unix shell
  recommended).
- 

### Running the pipeline


# Below area is still under construction

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



