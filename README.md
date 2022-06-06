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

- input file format
- 

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




