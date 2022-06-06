#!/bin/bash


#SBATCH --partition=p_ccib_1   			# which partition to run the job, options are in the Amarel guide
#SBATCH --exclude=gpuc001,gpuc002,memc001	# exclude CCIB GPUs
#SBATCH --job-name=Pipe_redo 			# job name for listing in queue
#SBATCH --output=/projectsc/f_geneva_1/caden/mtGenomes/slurmout/slurm-%j-%x.out
#SBATCH --mem=40G				# memory to allocate in Mb
#SBATCH -n 10 					# number of cores to use
#SBATCH -N 1 					# number of nodes the cores should be on, 1 means all cores on same node
#SBATCH --time=10-00:00:00			# maximum run time days-hours:minutes:seconds
#SBATCH --no-requeue 				# restart and paused or superseeded jobs
#SBATCH --mail-user=lcc128@rutgers.edu 		# email address to send status updates
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE 	# email for the following reasons


echo "load any Amarel modules that script requires"
module purge					# clears out any pre-existing modules
module load FastQC                      #fastqc
module load java			#needed by trimmomatic
#module load samtools	#in path	#needed by bwa, stampy, bedtools, MITObim, 
module load bwa				#bwa
module load python/2.7.12		#needed by stampy
module load bedtools2			#for NOVOplasty prep
module load perl			#needed by both assemblers

echo ""
echo "##################### variables"
species=$1
ref=$2
Kmer=$3
fetchDir="/projectsc/f_geneva_1/caden/mtGenomes/species-fetch"
folder="$(sed -n '1p' ${fetchDir}/${1}.txt)"
reads1="$(sed -n '2p' ${fetchDir}/${1}.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}.txt)"
readlen="$(sed -n '4p' ${fetchDir}/${1}.txt)"
insert="$(sed -n '5p' ${fetchDir}/${1}.txt)"
genomes="/projectsc/f_geneva_1/caden/mtGenomes/genomes"

echo ""
echo "##################### BEGINNING OF $1 #####################"

echo ""
echo "##################### create new folder for redo output"
mkdir -p ${genomes}/${species}/{fastqc-results,${species}-novoplasty,redo}

echo ""
echo "##################### trimmomatic"
java -jar /projectsc/f_geneva_1/programs/trimmomatic/trimmomatic-0.39.jar PE \
-threads 10 -phred33 -trimlog ${genomes}/${species}/${species}_trim.log \
${folder}/${reads1} ${folder}/${reads2} \
${genomes}/${species}/${species}_filtered.R1.fq.gz ${genomes}/${species}/${species}_filtered.unpaired.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz ${genomes}/${species}/${species}_filtered.unpaired.R2.fq.gz \
ILLUMINACLIP:/projectsc/f_geneva_1/programs/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10:4 \
LEADING:20 TRAILING:20 SLIDINGWINDOW:13:20 MINLEN:23
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### fastqc trimmomatic quality analysis"
fastqc -t 10 \
${genomes}/${species}/${species}_filtered.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz \
-o ${genomes}/${species}/fastqc-results/
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"


echo ""
echo "##################### index and align with BWA"
bwa index ${genomes}/deca_align/${ref}.fasta

bwa mem -t 10 ${genomes}/deca_align/${ref}.fasta \
${genomes}/${species}/${species}_filtered.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz \
| samtools sort -@10 -o ${genomes}/${species}/redo/${species}_bwa_aligned-${ref}.bam -

echo ""
echo "##################### depth and breadth stats on BWA"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/univ_sam_depth.sh ${species} "_bwa_aligned-${ref}" "/redo"
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### stampy re-mapping onto BWA output"
#echo "build genome file (comment out on re-runs)"
#/projectsc/f_geneva_1/programs/stampy/stampy.py -G ${genomes}/deca_align/${ref} --inputformat=fasta ${genomes}/deca_align/${ref}.fasta
#echo "build hash table (comment out on re-runs)"
#/projectsc/f_geneva_1/programs/stampy/stampy.py -g ${genomes}/deca_align/${ref} -H ${genomes}/deca_align/${ref}

echo "map unmapped reads from bwa using stampy"
/projectsc/f_geneva_1/programs/stampy/stampy.py -g ${genomes}/deca_align/${ref} \
-h ${genomes}/deca_align/${ref} -t 10 --bamkeepgoodreads \
-M ${genomes}/${species}/redo/${species}_bwa_aligned-${ref}.bam \
| samtools sort -@9 -o ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}.bam -
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### depth and breadth stats on stampy"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/univ_sam_depth.sh ${species} "_stampy_aligned-${ref}" "/redo"

echo ""
echo "##################### filter and sort mapped reads with samtools"
echo "samtools code sorting different combos of  mapped reads into new bam file"
samtools view -b -@ 9 -F 4 -f 8 ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}.bam > ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}_map1.bam
echo "done 1"
samtools view -b -@ 9 -F 8 -f 4 ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}.bam > ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}_map2.bam
echo "done 2"
samtools view -b -@ 9 -F 12 ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}.bam > ${genomes}/${species}/redo/${species}_stampy_aligned-${ref}_map3.bam
echo "done 3"

echo "samtools merge 3 mappings plus mappings together"
samtools merge ${genomes}/${species}/redo/${species}_mapped-${ref}.bam \
${genomes}/${species}/redo/${species}_stampy_aligned-${ref}_map1.bam \
${genomes}/${species}/redo/${species}_stampy_aligned-${ref}_map2.bam \
${genomes}/${species}/redo/${species}_stampy_aligned-${ref}_map3.bam

echo "samtools sort reads in name order"
samtools sort -n ${genomes}/${species}/redo/${species}_mapped-${ref}.bam \
-o ${genomes}/${species}/redo/${species}_mapped-${ref}_ordered.bam

echo ""
echo "##################### depth and breadth stats on filtered reads"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_project/univ_sam_depth.sh ${species} "_mapped-${ref}" "/redo"

echo ""
echo "##################### any other prep pre-assembly"
echo "bedtools into fastq r1 and r2 - for NOVOplasty"
bamToFastq -i ${genomes}/${species}/redo/${species}_mapped-${ref}_ordered.bam \
-fq ${genomes}/${species}/redo/${species}_mapped-${ref}_r1.fq \
-fq2 ${genomes}/${species}/redo/${species}_mapped-${ref}_r2.fq

echo "##################### create config file for NOVOplasty"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_pipeline/univ_config_generator.sh ${species} ${readlen} ${insert} "${species}_mapped-${ref}_r" "redo/" "${ref}" "deca_align/${ref}.fasta" ${Kmer} "redo"

echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### assembly step"
echo "Run novoplasty assemply"
perl /projectsc/f_geneva_1/programs/novoplasty/NOVOPlasty4.3.1.pl \
-c ${genomes}/${species}/${species}-novoplasty/novo_config_${species}_redo_${ref}_${Kmer}.txt

echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${genomes}/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
