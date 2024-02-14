#!/bin/bash


#SBATCH --partition=p_ccib_1   			# which partition to run the job, options are in the Amarel guide
#SBATCH --exclude=gpuc001,gpuc002    	        # exclude CCIB GPUs
#SBATCH --job-name=Realign 			# job name for listing in queue
#SBATCH --output=/projectsc/f_geneva_1/caden/mtGenomes/slurmout/slurm-%j-%x.out
#SBATCH --mem=10G				# memory to allocate in Mb
#SBATCH -n 10 					# number of cores to use
#SBATCH -N 1 					# number of nodes the cores should be on, 1 means all cores on same node
#SBATCH --time=4-00:00:00			# maximum run time days-hours:minutes:seconds
#SBATCH --no-requeue 				# restart and paused or superseeded jobs
#SBATCH --mail-user=lcc128@rutgers.edu 		# email address to send status updates
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE 	# email for the following reasons


echo "load any Amarel modules that script requires"
module purge					# clears out any pre-existing modules
#module load samtools	#in path	#needed by bwa, stampy, bedtools, MITObim, 
module load bwa				#bwa
module load python/2.7.12		#needed by stampy

echo ""
echo "##################### variables"
species=$1
ref=$2
vers=$3

fetchDir="/projectsc/f_geneva_1/caden/mtGenomes/species-fetch"
folder="$(sed -n '1p' ${fetchDir}/${1}-remap.txt)"
reads1="$(sed -n '2p' ${fetchDir}/${1}-remap.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}-remap.txt)"
genomes="/projectsc/f_geneva_1/caden/mtGenomes/genomes"

echo ""
echo "##################### BEGINNING OF $1 from $2 #####################"

echo ""
echo "##################### create new folder for redo output"
mkdir -p ${genomes}/${species}/{fastqc-results,${species}-novoplasty,remap}


echo ""
echo "##################### index and align with BWA"
bwa index ${genomes}/deca_align/${ref}.fasta

echo "mapping..."
bwa mem -t 10 ${genomes}/deca_align/${ref}.fasta \
${folder}/${reads1} ${folder}/${reads2} \
| samtools sort -@10 -o ${genomes}/${species}/remap/${species}${vers}_${ref}_bwa_remap.bam -

echo ""
echo "##################### depth and breadth stats on BWA"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/univ_sam_depth.sh ${species} "${vers}_${ref}_bwa_remap" "/remap"
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${genomes}/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
