#!/bin/bash


#SBATCH --partition=p_ccib_1   			# which partition to run the job, options are in the Amarel guide
#SBATCH --exclude=gpuc001,gpuc002		# exclude CCIB GPUs
#SBATCH --job-name=big_dirNovo 			# job name for listing in queue
#SBATCH --output=/projectsc/f_geneva_1/caden/mtGenomes/slurmout/slurm-%j-%x.out
#SBATCH --mem=50G				# memory to allocate in Mb
#SBATCH -n 1 					# number of cores to use
#SBATCH -N 1 					# number of nodes the cores should be on, 1 means all cores on same node
#SBATCH --time=5:00:00			# maximum run time days-hours:minutes:seconds
#SBATCH --no-requeue 				# restart and paused or superseeded jobs
#SBATCH --mail-user=lcc128@rutgers.edu 		# email address to send status updates
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE 	# email for the following reasons


echo "load any Amarel modules that script requires"
module purge					# clears out any pre-existing modules
module load bedtools2			#for NOVOplasty prep
module load perl			#needed by both assemblers

echo ""
echo "##################### variables"
species="$1"
ref="$2"
Kmer="$3"
fetchDir="/projectsc/f_geneva_1/caden/mtGenomes/species-fetch"
reads1="$(sed -n '2p' ${fetchDir}/${1}.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}.txt)"
readlen="$(sed -n '4p' ${fetchDir}/${1}.txt)"
insert="$(sed -n '5p' ${fetchDir}/${1}.txt)"
genomes="/projectsc/f_geneva_1/caden/mtGenomes/genomes"

#echo ""
#echo "##################### BEGINNING OF $1 #####################"

#gunzip -c ${genomes}/${species}/${species}_filtered.R1.fq.gz > ${genomes}/${species}/${species}_filtered1.fq
#gunzip -c ${genomes}/${species}/${species}_filtered.R2.fq.gz > ${genomes}/${species}/${species}_filtered2.fq

echo "##################### create config file for NOVOplasty"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/big_config_generator.sh ${species} ${readlen} ${insert} "${species}_filtered" "" "${ref}" "deca_align/${ref}.fasta" ${Kmer} "direct" "45"

echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### assembly step"
echo "Run novoplasty assemply"
perl /projectsc/f_geneva_1/programs/novoplasty/NOVOPlasty4.3.1.pl \
-c ${genomes}/${species}/${species}-novoplasty/novo_config_${species}_direct_${ref}_${Kmer}.txt


echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${genomes}/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
