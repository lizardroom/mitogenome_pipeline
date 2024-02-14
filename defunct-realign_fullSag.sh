#!/bin/bash


#SBATCH --partition=p_ccib_1   			# which partition to run the job, options are in the Amarel guide
#SBATCH --exclude=gpuc001,gpuc002    	        # exclude CCIB GPUs
#SBATCH --job-name=Realign_fullSag 			# job name for listing in queue
#SBATCH --output=/projectsc/f_geneva_1/caden/mtGenomes/slurmout/slurm-%j-%x.out
#SBATCH --mem=40G				# memory to allocate in Mb
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
ref="-${2}"
fetchDir="/projectsc/f_geneva_1/caden/mtGenomes/species-fetch"
folder="$(sed -n '1p' ${fetchDir}/${1}-remap.txt)"
reads1="$(sed -n '2p' ${fetchDir}/${1}-remap.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}-remap.txt)"
genomes="/projectsc/f_geneva_1/caden/mtGenomes/genomes"


echo ""
echo "##################### BEGINNING OF $1 from $2 #####################"

echo ""
echo "##################### create new folder for remap output"
mkdir -p ${genomes}/${species}/{fastqc-results,${species}-novoplasty,remap_sag}


echo ""
echo "##################### index and align with BWA"
#bwa index ${genomes}/sagrei/AnoSag2.1.fa

bwa mem -t 10 ${genomes}/sagrei/AnoSag2.1.fa \
${folder}/${reads1} ${folder}/${reads2} \
| samtools sort -@10 -o ${genomes}/${species}/remap_sag/${species}_bwa_remap-sag.bam -

echo ""
echo "##################### depth and breadth stats on BWA"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/univ_sam_depth.sh ${species} "_bwa_remap-sag" "/remap_sag"
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"


echo ""
echo "##################### stampy re-mapping onto BWA output"
#echo "build genome file (comment out on re-runs)"
#/projectsc/f_geneva_1/programs/stampy/stampy.py -G ${genomes}/sagrei/AnoSag2.1 --inputformat=fasta ${genomes}/sagrei/AnoSag2.1.fa
#echo "build hash table (comment out on re-runs)"
#/projectsc/f_geneva_1/programs/stampy/stampy.py -g ${genomes}/sagrei/AnoSag2.1 -H ${genomes}/sagrei/AnoSag2.1

echo "map unmapped reads from bwa using stampy"
/projectsc/f_geneva_1/programs/stampy/stampy.py -g ${genomes}/sagrei/AnoSag2.1 \
-h ${genomes}/sagrei/AnoSag2.1 -t 10 --bamkeepgoodreads \
-M ${genomes}/${species}/remap_sag/${species}_bwa_remap-sag.bam \
| samtools sort -@9 -o ${genomes}/${species}/remap_sag/${species}_stampy_remap-sag.bam -
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### depth and breadth stats on stampy"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/univ_sam_depth.sh ${species} "_stampy_remap-sag" "/remap_sag"


echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${genomes}/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
