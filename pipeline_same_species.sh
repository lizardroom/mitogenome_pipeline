#!/bin/bash


#SBATCH --partition=main   			# which partition to run the job, options are in the Amarel guide
# --exclude=gpuc001,gpuc002		# exclude CCIB GPUs
#SBATCH --job-name=pipe_sa-sp 			# job name for listing in queue
#SBATCH --output=/projectsc/f_geneva_1/caden/mtGenomes/slurmout/slurm-%j-%x.out
#SBATCH --mem=5G				# memory to allocate in Mb (or in Gb is G is added)
#SBATCH -n 10 					# number of cores to use
#SBATCH -N 1 					# number of nodes the cores should be on, 1 means all cores on same node
#SBATCH --time=3-00:00:00			# maximum run time days-hours:minutes:seconds
#SBATCH --no-requeue 				# restart and paused or superceeded jobs
#SBATCH --mail-user=lcc128@rutgers.edu 		# email address to send status updates
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE 	# email for the following reasons


echo "load any Amarel modules that script requires"
module purge                	# clears out any pre-existing modules
module load java		#needed by fastqc, trimmomatic
module load FastQC		#fastqc
#module load samtools	#in path	#needed by bwa, bedtools, MITObim, 
module load bwa			#bwa
module load bedtools2		#for NOVOplasty prep
module load perl		#needed by both assemblers

echo ""
echo "##################### variables"
# ALL VARIABLES ARE CASE SENSITIVE

#File directory where the project will be run
project="/projectsc/f_geneva_1/caden/mtGenomes"

##################### DO NOT MODIFY CODE BELOW HERE #####################
#Name of the species from command line submission
species=$1
#assigning fetch folder location
fetchDir="${project}/species-fetch"


#Directory and file name pointing to forward illumina reads
reads1="$(sed -n '2p' ${fetchDir}/${species}.txt)"
#Directory and file name pointing to reverse illumina reads
reads2="$(sed -n '4p' ${fetchDir}/${species}.txt)"
#Length of reads from illumina run
readlen="$(sed -n '6p' ${fetchDir}/${species}.txt)"
#Insert length stat from illumina run
insert="$(sed -n '8p' ${fetchDir}/${species}.txt)"
#Directory for the illumina adaptor file for trimmomatic to use
illumina_adaptor="$(sed -n '10p' ${fetchDir}/${species}.txt)"
#Kmer to be used for novoPlasty assembly
Kmer="$(sed -n '12p' ${fetchDir}/${species}.txt)"
#Name of the species that will be the reference mt-genome
ref="$(sed -n '14p' ${fetchDir}/${species}.txt)"
#Name of the reference genome file with file extension
ref_file="$(sed -n '16p' ${fetchDir}/${species}.txt)"
## if you would like for a sub-section of the pipeline to run, set that value to 1. To not have a subsection run, set to 0 (zero). 
#to run FastQC, Trimmomatic, and post-trim FastQC
fq_trimmo_run="$(sed -n '19p' ${fetchDir}/${species}.txt)"
#to run BWA mapping and post-bwa sorting
bwa_run="$(sed -n '21p' ${fetchDir}/${species}.txt)"
#to run Stampy mapping
stampy_run="0"
#to run samtools filtering of mapped reads
filter_run="$(sed -n '25p' ${fetchDir}/${species}.txt)"
#to run generation of novoplasty configuration file and assembly
novo_run="$(sed -n '27p' ${fetchDir}/${species}.txt)"

echo ""
echo "##################### BEGINNING OF $1 #####################"
echo "################# same-species pipeline version #################"
echo "reference used: ${ref}"
echo "Kmer used for Novoplasty: ${Kmer}"
echo "Forward reads: ${reads1}"
echo "Reverse reads: ${reads2}"
echo "Read length stat: ${readlen}"
echo "Insert size stat: ${insert}"
echo ""
echo "##################### sub-program run controls"
echo "FastQC & Trimmomatic run:       ${fq_trimmo_run}"
echo "BWA mapping:                    ${bwa_run}"
echo "Stampy mapping:      this is the same-species version of the pipeline and does not run stampy"
echo "Post-mapping filtering:         ${filter_run}"
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
    ${reads1} ${reads2} \
    ${project}/assemblies/${species}/${species}_filtered.R1.fq.gz ${project}/assemblies/${species}/${species}_filtered.unpaired.R1.fq.gz \
    ${project}/assemblies/${species}/${species}_filtered.R2.fq.gz ${project}/assemblies/${species}/${species}_filtered.unpaired.R2.fq.gz \
    ILLUMINACLIP:${illumina_adaptor} \
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
  echo "##################### index reference file and align with BWA"

  # if one of the indexed files does not exist, then index the reference file
  if ! test -f "${project}/references/${ref_file}.amb"; then
    bwa index ${project}/references/${ref_file}
  else
    echo "indexing output detected, indexing skipped"
  fi
  echo ""
  
  bwa mem -t 10 ${project}/references/${ref_file} \
    ${project}/assemblies/${species}/${species}_filtered.R1.fq.gz \
    ${project}/assemblies/${species}/${species}_filtered.R2.fq.gz \
    | samtools sort -@10 -o ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}.bam -

  echo ""
  echo "##################### depth and breadth stats on BWA"
  ${project}/mitogenome_pipeline/sam_depth.sh "${project}/assemblies" ${species} "_bwa_aligned-${ref}"

  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

else
  echo "bwa alignment skipped"
fi


if [ $filter_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### filter and sort mapped reads with samtools"
  echo "samtools code sorting different combos of  mapped reads into new bam file"
  samtools view -b -@10 -F 4 -f 8 ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}.bam > ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_map1.bam
  echo "done 1"
  samtools view -b -@10 -F 8 -f 4 ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}.bam > ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_map2.bam
  echo "done 2"
  samtools view -b -@10 -F 12 ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}.bam > ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_map3.bam
  echo "done 3"

  echo "samtools merge 3 mappings together"
  samtools merge ${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}.bam \
    ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_map1.bam \
    ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_map2.bam \
    ${project}/assemblies/${species}/${species}_bwa_aligned-${ref}_map3.bam

  echo "samtools sort reads in name order"
  samtools sort -n ${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}.bam \
    -o ${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}_ordered.bam

  echo ""
  echo "##################### depth and breadth stats on filtered reads"
  ${project}/mitogenome_pipeline/sam_depth.sh "${project}/assemblies" ${species} "_ss-bwa-mapped-${ref}"

else
  echo "filtering of mapped reads skipped"
fi


if [ $novo_run -eq 1 ]; then #####################################
  echo ""
  echo "##################### any other prep pre-assembly"
  echo "bedtools into fastq r1 and r2 - for NOVOplasty"
  bamToFastq -i ${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}_ordered.bam \
    -fq ${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}_r1.fq \
    -fq2 ${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}_r2.fq

  echo "create config file for NOVOplasty"
    output="${project}/assemblies/${species}/${species}-novoplasty/"
    conTemp="${project}/mitogenome_pipeline/novoplasty_template.txt"
    conNew="${output}novo_config_${species}_ss-ref-${ref}_${Kmer}.txt"

    echo -n "$(sed -n '1,3p' ${conTemp})" > ${conNew}
    echo "${species}_ss-ref-${ref}_${Kmer}" >> ${conNew}
    echo -n "$(sed -n '4,6p' ${conTemp})" >> ${conNew}
    echo "${Kmer}" >> ${conNew}
    echo -n "$(sed -n '7,10p' ${conTemp})" >> ${conNew}
    echo "${project}/references/${ref_file}" >> ${conNew}
    echo -n "$(sed -n '11,12p' ${conTemp})" >> ${conNew}
    echo "${project}/references/${ref_file}" >> ${conNew}
    echo -n "$(sed -n '13,18p' ${conTemp})" >> ${conNew}
    echo "${readlen}" >> ${conNew}
    echo -n "$(sed -n '19p' ${conTemp})" >> ${conNew}
    echo "${insert}" >> ${conNew}
    echo -n "$(sed -n '20,23p' ${conTemp})" >> ${conNew}
    echo "${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}_r1.fq" >> ${conNew}
    echo -n "$(sed -n '24p' ${conTemp})" >> ${conNew}
    echo "${project}/assemblies/${species}/${species}_ss-bwa-mapped-${ref}_r2.fq" >> ${conNew}
    echo -n "$(sed -n '25,37p' ${conTemp})" >> ${conNew}
    echo "${output}" >> ${conNew}

  
  echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

  echo ""
  echo "##################### assembly step"
  echo "Run novoplasty assemply"
  perl /projectsc/f_geneva_1/programs/novoplasty/NOVOPlasty4.3.1.pl \
    -c ${project}/assemblies/${species}/${species}-novoplasty/novo_config_${species}_ss-ref-${ref}_${Kmer}.txt

else
  echo "novoplasty prep and alignment skipped"
fi

echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${project}/assemblies/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
