#!/bin/bash

echo "directory and name variables"
genomes="$1"
species="$2"
name="$3"

#####################
echo "index mapping file"
samtools index ${genomes}/${species}/${species}${name}.bam
echo "create depth file"
samtools depth -a ${genomes}/${species}/${species}${name}.bam > ${genomes}/${species}/${species}${name}_depth.txt

echo "calculate flagstat on mapping"
samtools flagstat ${genomes}/${species}/${species}${name}.bam > ${genomes}/${species}/${species}${name}_stats.txt
echo "" >> ${genomes}/${species}/${species}${name}_stats.txt

echo "output depth stats"
x=$(awk '{c++;s+=$3}END{print s/c}' ${genomes}/${species}/${species}${name}_depth.txt)
echo "Depth (all): $x" >> ${genomes}/${species}/${species}${name}_stats.txt
awk -v x=$x '{c++;d+=($3-x)**2}END{print "Depth StDev:", sqrt(d/c)}' ${genomes}/${species}/${species}${name}_depth.txt >> ${genomes}/${species}/${species}${name}_stats.txt
awk -v max=0 '{if(($3)>max) max=($3)}END{print "Depth Max:", max}' ${genomes}/${species}/${species}${name}_depth.txt >> ${genomes}/${species}/${species}${name}_stats.txt

awk '{c++; if($3>0) total+=1}END{print "Breadth: ", (total/c)*100}' ${genomes}/${species}/${species}${name}_depth.txt >> ${genomes}/${species}/${species}${name}_stats.txt
samtools depth ${genomes}/${species}/${species}${name}.bam | awk '{c++;s+=$3}END{print "Depth (>0 coverage): ", s/c}' >> ${genomes}/${species}/${species}${name}_stats.txt

#####################
