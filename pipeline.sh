#!/bin/bash


#SBATCH --partition=main   			# which partition to run the job, options are in the Amarel guide
# --exclude=gpuc001,gpuc002		# exclude CCIB GPUs
#SBATCH --job-name=pipeline 			# job name for listing in queue
#SBATCH --output=/projectsc/f_geneva_1/caden/mtGenomes/slurmout/slurm-%j-%x.out
#SBATCH --mem=40G				# memory to allocate in Mb
#SBATCH -n 10 					# number of cores to use
#SBATCH -N 1 					# number of nodes the cores should be on, 1 means all cores on same node
#SBATCH --time=3-00:00:00			# maximum run time days-hours:minutes:seconds
#SBATCH --no-requeue 				# restart and paused or superseeded jobs
#SBATCH --mail-user=lcc128@rutgers.edu 		# email address to send status updates
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE 	# email for the following reasons


echo "load any Amarel modules that script requires"
module purge					# clears out any pre-existing modules
module load java			#needed by fastqc, trimmomatic
module load FastQC			#fastqc
#module load samtools	#in path	#needed by bwa, stampy, bedtools, MITObim, 
module load bwa				#bwa
module load python/2.7.12		#needed by stampy
module load bedtools2			#for NOVOplasty prep
module load perl			#needed by both assemblers

echo ""
echo "##################### variables"
# ALL VARIABLES ARE CASE SENSITIVE

#File directory where the project will be run
project="/projectsc/f_geneva_1/caden/mtGenomes"
fetchDir="${project}/species-fetch"

#Name of the species.
species=$1
#Kmer to be used for novoPlasty assembly
Kmer=
#Directory and file name pointing to forward illumina reads
reads1="$(sed -n '2p' ${fetchDir}/${1}.txt)"
#Directory and file name pointing to forward illumina reads
reads2="$(sed -n '3p' ${fetchDir}/${1}.txt)"
#Length of reads from illumina run
readlen="$(sed -n '4p' ${fetchDir}/${1}.txt)"
#Insert length stat from illumina run
insert="$(sed -n '5p' ${fetchDir}/${1}.txt)"
#Directory for the illumina adaptor file for trimmomatic to use
illumina_adaptor="/projectsc/f_geneva_1/programs/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10:4"

#Name of the species that will be the reference mt-genome
ref=
#Name of the reference genome file with file extension
ref_file=


echo ""
echo "##################### sub-program run controls"
## if you would like for a sub-section of the pipeline to run,
## set that value to 1. To not have a subsection run, set to 0 (zero). 

#to run FastQC, Trimmomatic, and post-trim FastQC
fq_trimmo_run=1
#to run BWA mapping and post-bwa sorting
bwa_run=1
#to run Stampy mapping
stampy_run=1
#to run samtools filtering of stampy mapped reads
filter_run=1
#to run generation of novoplasty configuration file and assembly
novo_run=1

echo ""
echo "##################### BEGINNING OF $1 #####################"
echo "reference used: ${ref}"
echo "Kmer used for Novoplasty: ${Kmer}"
echo "Forward reads: ${reads1}"
echo "Reverse reads: ${reads2}"
echo "Read length stat: ${readlen}"
echo "Insert size stat: ${insert}"
echo ""
echo "FastQC & Trimmomatic run:       ${fq_trimmo_run}"
echo "BWA mapping:                    ${bwa_run}"
echo "Stampy mapping:                 ${stampy_run}"
echo "Post-stampy filtering:          ${filter_run}"
echo "Novoplasty config and assembly: ${novo_run}"


echo ""
echo "##################### create missing directories"
mkdir -p ${project}/assemblies/${species}/{fastqc-results,${species}-novoplasty} 


if [ $fq_trimmo_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### fastqc initial quality analysis"
  fastqc -t 10 ${reads1} ${reads2} \
    -o ${project}/assemblies/${species}/fastqc-results/

  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

  echo ""
  echo "##################### trimmomatic"
  java -jar /projectsc/f_geneva_1/programs/trimmomatic/trimmomatic-0.39.jar PE \
    -threads 10 -phred33 -trimlog ${project}/assemblies/${species}/${species}_trim.log \
    ${folder}/${reads1} ${folder}/${reads2} \
    ${project}/assemblies/${species}/${species}_filtered.R1.fq.gz ${project}/assemblies/${species}/${species}_filtered.unpaired.R1.fq.gz \
    ${project}/assemblies/${species}/${species}_filtered.R2.fq.gz ${project}/assemblies/${species}/${species}_filtered.unpaired.R2.fq.gz \
    ILLUMINACLIP: ${illumina_adaptor} \
    LEADING:20 TRAILING:20 SLIDINGWINDOW:13:20 MINLEN:23

  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

  echo ""
  echo "##################### fastqc trimmomatic quality analysis"
  fastqc -t 10 \
    ${project}/assemblies/${species}/${species}_filtered.R1.fq.gz \
    ${project}/assemblies/${species}/${species}_filtered.R2.fq.gz \
    -o ${project}/assemblies/${species}/fastqc-results/

  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

else
  echo "fastqc and trimmomatic skipped"
fi


if [ $bwa_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### index and align with BWA"
  #bwa index ${project}/references/${ref}.fasta

  bwa mem -t 10 ${project}/references/${ref_file} \
    ${project}/assemblies/${species}/${species}_filtered.R1.fq.gz \
    ${project}/assemblies/${species}/${species}_filtered.R2.fq.gz \
    | samtools sort -@10 -o ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}.bam -

  echo ""
  echo "##################### depth and breadth stats on BWA"
  ${project}/mitogenome_pipeline/sam_depth.sh ${species} "_bwa_aligned-${ref}" ""

  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

else
  echo "bwa alignment skipped"
fi


if [ $stampy_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### Sort BWA output reads"
  echo "samtools sort reads in name order"
  samtools sort -@10 -n ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}.bam \
    -o ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_ordered.bam

  echo "##################### stampy re-mapping onto BWA output"
  #echo "build genome file (comment out on re-runs)"
  #/projectsc/f_geneva_1/programs/stampy/stampy.py -G ${project}/references/${ref} --inputformat=fasta ${project}/references/${ref_file}
  #echo "build hash table (comment out on re-runs)"
  #/projectsc/f_geneva_1/programs/stampy/stampy.py -g ${project}/references/${ref} -H ${project}/references/${ref}

  echo "map unmapped reads from bwa using stampy"
  /projectsc/f_geneva_1/programs/stampy/stampy.py -g ${project}/references/${ref} \
    -h ${project}/references/${ref} -t 10 --bamkeepgoodreads \
    -M ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_ordered.bam \
    | samtools sort -@10 -o ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}.bam -
    echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

  echo ""
  echo "##################### depth and breadth stats on stampy"
  ${project}/mitogenome_pipeline/sam_depth.sh ${species} "_stampy_aligned-${ref}" ""

else
  echo "stampy alignment skipped"
fi


if [ $filter_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### filter and sort mapped reads with samtools"
  echo "samtools code sorting different combos of  mapped reads into new bam file"
  samtools view -b -@10 -F 4 -f 8 ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}.bam > ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}_map1.bam
  echo "done 1"
  samtools view -b -@10 -F 8 -f 4 ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}.bam > ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}_map2.bam
  echo "done 2"
  samtools view -b -@10 -F 12 ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}.bam > ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}_map3.bam
  echo "done 3"

  echo "samtools merge 3 mappings together"
  samtools merge ${project}/assemblies/${species}/${species}_mapped-${ref}.bam \
    ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}_map1.bam \
    ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}_map2.bam \
    ${project}/assemblies/${species}/${species}_stampy_aligned-${ref}_map3.bam

  echo "samtools sort reads in name order"
  samtools sort -n ${project}/assemblies/${species}/${species}_mapped-${ref}.bam \
    -o ${project}/assemblies/${species}/${species}_mapped-${ref}_ordered.bam

  echo ""
  echo "##################### depth and breadth stats on filtered reads"
  ${project}/mitogenome_pipeline/sam_depth.sh ${species} "_mapped-${ref}" ""

else
  echo "filtering of stampy alignment skipped"
fi


if [ $novo_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### any other prep pre-assembly"
  echo "bedtools into fastq r1 and r2 - for NOVOplasty"
  bamToFastq -i ${project}/assemblies/${species}/${species}_mapped-${ref}_ordered.bam \
    -fq ${project}/assemblies/${species}/${species}_mapped-${ref}_r1.fq \
    -fq2 ${project}/assemblies/${species}/${species}_mapped-${ref}_r2.fq

  echo "create config file for NOVOplasty"
  ${project}/mitogenome_pipeline/config_generator.sh ${species} ${readlen} ${insert} "${species}_mapped-${ref}_r" "" "${ref}" "${project}/references/${ref_file}" ${Kmer} ""

  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

  echo ""
  echo "##################### assembly step"
  echo "Run novoplasty assemply"
  perl /projectsc/f_geneva_1/programs/novoplasty/NOVOPlasty4.3.1.pl \
    -c ${project}/assemblies/${species}/${species}-novoplasty/novo_config_${species}__${ref}_${Kmer}.txt

else
  echo "novoplasty prep and alignment skipped"
fi

echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${project}/assemblies/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
