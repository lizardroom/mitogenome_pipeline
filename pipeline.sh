#!/bin/bash

echo "load any modules that script requires"
module purge					      # clears out any pre-existing modules
module load java			      #needed by fastqc, trimmomatic
module load FastQC		      #fastqc
module load samtools	      #needed by bwa, stampy, bedtools, MITObim, 
module load bwa				      #bwa
module load python/2.7.12		#needed by stampy
module load bedtools2			  #for NOVOplasty prep
module load perl			      #needed by NOVOplasty

echo ""
echo "##################### variables"
species="$1"
ref="$2"
Kmer="$3"
fetchDir="/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/species-fetch"
folder="$(sed -n '1p' ${fetchDir}/${1}.txt)"
reads1="$(sed -n '2p' ${fetchDir}/${1}.txt)"
reads2="$(sed -n '3p' ${fetchDir}/${1}.txt)"
readlen="$(sed -n '4p' ${fetchDir}/${1}.txt)"
insert="$(sed -n '5p' ${fetchDir}/${1}.txt)"
genomes="/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/genomes"

echo ""
echo "##################### BEGINNING OF $1 with Ref $2 and Kmer $3 #####################"

echo ""
echo "##################### create missing directories"
mkdir -p ${genomes}/${species}/{fastqc-results,${species}-novoplasty} 


echo ""
echo "##################### fastqc initial quality analysis"
fastqc -t 10 ${folder}/${reads1} ${folder}/${reads2} \
-o ${genomes}/${species}/fastqc-results/


echo ""
echo "##################### trimmomatic"
java -jar /XXXXXXX/YYYYYYYYY/ZZZZZZZ/trimmomatic/trimmomatic-0.39.jar PE \
-threads 10 -phred33 -trimlog ${genomes}/${species}/${species}_trim.log \
${folder}/${reads1} ${folder}/${reads2} \
${genomes}/${species}/${species}_filtered.R1.fq.gz ${genomes}/${species}/${species}_filtered.unpaired.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz ${genomes}/${species}/${species}_filtered.unpaired.R2.fq.gz \
ILLUMINACLIP:/XXXXXXX/YYYYYYYYY/ZZZZZZZ/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10:4 \
LEADING:20 TRAILING:20 SLIDINGWINDOW:13:20 MINLEN:23


echo ""
echo "##################### fastqc trimmomatic quality analysis"
fastqc -t 10 \
${genomes}/${species}/${species}_filtered.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz \
-o ${genomes}/${species}/fastqc-results/


echo ""
echo "##################### index and align with BWA"
bwa index ${genomes}/references/${ref}.fasta

bwa mem -t 10 ${genomes}/references/${ref}.fasta \
${genomes}/${species}/${species}_filtered.R1.fq.gz \
${genomes}/${species}/${species}_filtered.R2.fq.gz \
| samtools sort -@10 -o ${genomes}/${species}/${species}_bwa_aligned-${ref}.bam -

echo ""
echo "##################### depth and breadth stats on BWA"
/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/samtools_depth_stats.sh ${species} "_bwa_aligned-${ref}"


echo ""
echo "##################### stampy re-mapping onto BWA output"
echo "build genome file (comment out on re-runs)"
/XXXXXXX/YYYYYYYYY/ZZZZZZZ/stampy/stampy.py -G ${ref} --inputformat=fasta ${genomes}/references/${ref}.fasta
echo "build hash table (comment out on re-runs)"
/XXXXXXX/YYYYYYYYY/ZZZZZZZ/stampy/stampy.py -g ${ref} -H ${ref}

echo "map unmapped reads from bwa using stampy"
/XXXXXXX/YYYYYYYYY/ZZZZZZZ/stampy/stampy.py -g ${genomes}/references/${ref} \
-h ${genomes}/references/${ref} -t 10 --bamkeepgoodreads \
-M ${genomes}/${species}/${species}_bwa_aligned-${ref}.bam \
| samtools sort -@10 -o ${genomes}/${species}/${species}_stampy_aligned-${ref}.bam -

echo ""
echo "##################### depth and breadth stats on stampy"
/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/samtools_depth_stats.sh ${species} "_stampy_aligned-${ref}"


echo ""
echo "##################### filter and sort mapped reads with samtools"
echo "samtools code sorting different combos of  mapped reads into new bam file"
samtools view -b -@10 -F 4 -f 8 ${genomes}/${species}/${species}_stampy_aligned-${ref}.bam > ${genomes}/${species}/${species}_stampy_aligned-${ref}_map1.bam
echo "done 1"
samtools view -b -@10 -F 8 -f 4 ${genomes}/${species}/${species}_stampy_aligned-${ref}.bam > ${genomes}/${species}/${species}_stampy_aligned-${ref}_map2.bam
echo "done 2"
samtools view -b -@10 -F 12 ${genomes}/${species}/${species}_stampy_aligned-${ref}.bam > ${genomes}/${species}/${species}_stampy_aligned-${ref}_map3.bam
echo "done 3"

echo "samtools merge 3 mapping files together"
samtools merge ${genomes}/${species}/${species}_mapped-${ref}.bam \
${genomes}/${species}/${species}_stampy_aligned-${ref}_map1.bam \
${genomes}/${species}/${species}_stampy_aligned-${ref}_map2.bam \
${genomes}/${species}/${species}_stampy_aligned-${ref}_map3.bam

echo "samtools sort reads in name order - needed for bedtools"
samtools sort -n ${genomes}/${species}/${species}_mapped-${ref}.bam \
-o ${genomes}/${species}/${species}_mapped-${ref}_ordered.bam

echo ""
echo "##################### depth and breadth stats on filtered reads"
/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_pipeline/sam_depth.sh ${species} "_mapped-${ref}"


echo ""
echo "##################### bedtools into fastq r1 and r2 - for NOVOplasty"
bamToFastq -i ${genomes}/${species}/${species}_mapped-${ref}_ordered.bam \
-fq ${genomes}/${species}/${species}_mapped-${ref}_r1.fq \
-fq2 ${genomes}/${species}/${species}_mapped-${ref}_r2.fq

echo "create config file for NOVOplasty"
/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/config_generator.sh ${species} ${readlen} ${insert} "${species}_mapped-${ref}_r" "" "${ref}" "deca_align/${ref}.fasta" ${Kmer} ""


echo ""
echo "##################### assembly step"
echo "Run novoplasty assemply"
perl /XXXXXXX/YYYYYYYYY/ZZZZZZZ/novoplasty/NOVOPlasty4.3.1.pl \
-c ${genomes}/${species}/${species}-novoplasty/novo_config_${species}__${ref}_${Kmer}.txt
