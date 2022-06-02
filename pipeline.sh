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
species="$1"
ref="$2"
Kmer="$3"
fetchDir="/projectsc/f_geneva_1/caden/mtGenomes/species-fetch"
folder="/projectsc/f_geneva_1/$(sed -n '1p' ${fetchDir}/${1}.txt)"
reads1="$(sed -n '2p' ${fetchDir}/${1}.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}.txt)"
readlen="$(sed -n '4p' ${fetchDir}/${1}.txt)"
insert="$(sed -n '5p' ${fetchDir}/${1}.txt)"
genomes="/projectsc/f_geneva_1/caden/genomes"

echo ""
echo "##################### BEGINNING OF $1 #####################"

echo ""
echo "##################### create missing directories"
mkdir -p ${genomes}/${species}/{fastqc-results,${species}-novoplasty} 

echo ""
echo "##################### fastqc initial quality analysis"
fastqc -t 10 ${folder}/${reads1} ${folder}/${reads2} \
-o ${genomes}/${species}/fastqc-results/
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

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
#bwa index ${genomes}/sagrei/AnoSag2_mtDNA_consensus.fasta

bwa mem -t 10 ${genomes}/sagrei/AnoSag2_mtDNA_consensus.fasta \
${genomes}/${species}/${species}_filtered.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz \
| samtools sort -@10 -o ${genomes}/${species}/${species}_bwa_aligned.bam -

echo ""
echo "##################### depth and breadth stats on BWA"
/projectsc/f_geneva_1/caden/mtGenomes/univ_sam_depth.sh ${species} "_bwa_aligned" ""
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### stampy re-mapping onto BWA output"
#echo "build genome file (comment out on re-runs)"
#/projectsc/f_geneva_1/programs/stampy/stampy.py -G sag2 --inputformat=fasta ${genomes}/sagrei/AnoSag2_mtDNA_consensus.fasta
#echo "build hash table (comment out on re-runs)"
#/projectsc/f_geneva_1/programs/stampy/stampy.py -g sag2 -H sag2

echo "map unmapped reads from bwa using stampy"
/projectsc/f_geneva_1/programs/stampy/stampy.py -g ${genomes}/sagrei/sag2 \
-h ${genomes}/sagrei/sag2 -t 10 --bamkeepgoodreads \
-M ${genomes}/${species}/${species}_bwa_aligned.bam \
| samtools sort -@10 -o ${genomes}/${species}/${species}_stampy_aligned.bam -
echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### depth and breadth stats on stampy"
/projectsc/f_geneva_1/caden/mtGenomes/univ_sam_depth.sh ${species} "_stampy_aligned" ""

echo ""
echo "##################### filter and sort mapped reads with samtools"
echo "samtools code sorting different combos of  mapped reads into new bam file"
samtools view -b -@ 9 -F 4 -f 8 ${genomes}/${species}/${species}_stampy_aligned.bam > ${genomes}/${species}/${species}_stampy_aligned_map1.bam
echo "done 1"
samtools view -b -@ 9 -F 8 -f 4 ${genomes}/${species}/${species}_stampy_aligned.bam > ${genomes}/${species}/${species}_stampy_aligned_map2.bam
echo "done 2"
samtools view -b -@ 9 -F 12 ${genomes}/${species}/${species}_stampy_aligned.bam > ${genomes}/${species}/${species}_stampy_aligned_map3.bam
echo "done 3"

echo "samtools merge 3 mappings together"
samtools merge ${genomes}/${species}/${species}_stampy_aligned_mapped.bam \
${genomes}/${species}/${species}_stampy_aligned_map1.bam \
${genomes}/${species}/${species}_stampy_aligned_map2.bam \
${genomes}/${species}/${species}_stampy_aligned_map3.bam

echo "samtools sort reads in name order"
samtools sort -n ${genomes}/${species}/${species}_stampy_aligned_mapped.bam \
-o ${genomes}/${species}/${species}_stampy_aligned_mapped_ordered.bam

echo ""
echo "##################### depth and breadth stats on filtered reads"
/projectsc/f_geneva_1/caden/mtGenomes/sam_depth.sh ${species} "_stampy_aligned_mapped" ""

echo ""
echo "##################### any other prep pre-assembly"
echo "bedtools into fastq r1 and r2 - for NOVOplasty"
bamToFastq -i ${genomes}/${species}/${species}_stampy_aligned_mapped_ordered.bam \
-fq ${genomes}/${species}/${species}_stampy_aligned_mapped_r1.fq \
-fq2 ${genomes}/${species}/${species}_stampy_aligned_mapped_r2.fq

echo "create config file for NOVOplasty"
/projectsc/f_geneva_1/caden/mtGenomes/univ_config_generator.sh ${species} ${readlen} ${insert} "${species}_stampy_aligned_mapped_r" "" "${ref}" "deca_align/${ref}.fasta" ${Kmer} ""

#echo "samtools make interleaved fq from bam - for MITObim"
#samtools bam2fq \
#${genomes}/${species}/${species}_stampy_aligned_mapped_ordered.bam \
#> ${genomes}/${species}/${species}_stampy_aligned_mapped_interleaved.fastq

echo "$(sacct -j ${SLURM_JOB_ID} --format=elapsed | sed -n -e 3p)"

echo ""
echo "##################### assembly step"
echo "Run novoplasty assemply"
perl /projectsc/f_geneva_1/programs/novoplasty/NOVOPlasty4.3.1.pl \
-c ${genomes}/${species}/${species}-novoplasty/novo_config_${species}.txt


#echo "add mira to path"
#export PATH="/projectsc/f_geneva_1/programs/mira/bin:$PATH"
#echo "run MITObim analysis"
#/projectsc/f_geneva_1/programs/mitobim/MITObim.pl  -start 1 -end 30 --paired \
#--denovo -sample ${species}_mitobim -ref sagrei \
#-readpool ${genomes}/${species}/${species}_stampy_aligned_mapped_interleaved.fastq \
#-quick /projectsc/f_geneva_1/caden/mtGenomes/genomes/sagrei/AnoSag2_mtDNA_consensus.fasta

echo ""
echo "##################### change user group of files created"
chgrp -R ccib ${genomes}/${species}/	# changes group of all files in listed directory

#fair share score
/projectsc/f_geneva_1/caden/fairshare.sh
