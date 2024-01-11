#!/bin/bash


#SBATCH --partition=main   			# which partition to run the job, options are in the Amarel guide
# --exclude=gpuc001,gpuc002		# exclude CCIB GPUs
#SBATCH --job-name=TrmHumil 			# job name for listing in queue
#SBATCH --output=/projects/ccib/geneva/lim/slurmout/slurm-%j-%x.out
#SBATCH --mem=10G				# memory to allocate in Mb
#SBATCH -n 5 					# number of cores to use
#SBATCH -N 1 					# number of nodes the cores should be on, 1 means all cores on same node
#SBATCH --time=10:00:00				# maximum run time days-hours:minutes:seconds
#SBATCH --no-requeue 				# restart and paused or superseeded jobs
#SBATCH --mail-user=lcc128@rutgers.edu 		# email address to send status updates
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE 	# email for the following reasons


echo "load any Amarel modules that script requires"
module purge					# clears out any pre-existing modules
module load java			#needed by fastqc, trimmomatic
module load FastQC			#fastqc

echo ""
echo "##################### variables"
species="$1"
fetchDir="/projects/ccib/geneva/lim/species-fetch"
folder="/projects/ccib/geneva/$(sed -n '1p' ${fetchDir}/${1}.txt)"
reads1="$(sed -n '2p' ${fetchDir}/${1}.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}.txt)"
genomes="/projects/ccib/geneva/lim/genomes"

echo ""
echo "##################### BEGINNING OF $1 #####################"

echo ""
echo "##################### create missing directories"
mkdir -p ${genomes}/${species}/{fastqc-results,${species}-novoplasty} 

#echo ""
#echo "##################### fastqc initial quality analysis"
#fastqc -t 5 ${folder}/${reads1} ${folder}/${reads2} \
#-o ${genomes}/${species}/fastqc-results/
#echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### trimmomatic"
java -jar /projects/ccib/geneva/programs/trimmomatic/trimmomatic-0.39.jar PE \
-threads 5 -phred33 -trimlog ${genomes}/${species}/${species}_trim.log \
${folder}/${reads1} ${folder}/${reads2} \
${genomes}/${species}/${species}_filtered.R1.fq.gz ${genomes}/${species}/${species}_filtered.unpaired.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz ${genomes}/${species}/${species}_filtered.unpaired.R2.fq.gz \
ILLUMINACLIP:/projects/ccib/geneva/programs/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10:4:TRUE \
LEADING:20 TRAILING:20 SLIDINGWINDOW:13:20 MINLEN:23
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### fastqc trimmomatic quality analysis"
fastqc -t 5 \
${genomes}/${species}/${species}_filtered.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz \
-o ${genomes}/${species}/fastqc-results/
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"


echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${genomes}/${species}/	# changes group of all files in listed directory


#fair share score
#/projects/ccib/geneva/lim/fairshare.sh
