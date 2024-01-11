# Mitogenome Pipeline

**IMPORTANT NOTE: THIS RELEASE OF THE PIPELINE IS
ONLY MEANT TO SERVE AS A REFERENCE FOR THE PUBLICATION.
IF YOU ARE INTERESTED IN USING THE PIPELINE TO ANALYZE
DATA, PLEASE CHECK THIS GITHUB FOR A NEWER RELEASE. IF
IT IS NOT UP YET, THEN PLEASE CONTACT ME FOR FURTHER
INFORMATION AS IT MEANS THAT THE FINAL VERSION FOR BROAD USE
IS STILL IN THE WORKS (ESTIMATED RELEASE: SUMMER 2024)**

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
 
\#calls on an executable/extra file (see further down)

-> FastQC  
-> Trimmomatic  
-> FastQC on trimmed reads  
  
-> BWA*  
-> calculate mapping stats on BWA#  
-> Stampy*  
-> calculate mapping stats on Stampy#  
  
-> filter stampy alignment using samtools  
-> calculate stats on filetered reads  
-> convert bam file to reads 1&2 fastqc files 
  
-> generate NOVOplasty configuration file#  
-> run NOVOplasty assembly step  


### univ\_sam\_depth.sh
Universal samtools depth calculator program that
is called by full-length _pipeline.sh_.

### univ\_config\_generator.sh
Generates NOVOplasty configuration file using the
template found in _univ\_configuration\_novo.sh_.

