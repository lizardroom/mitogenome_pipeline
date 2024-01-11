#!/bin/bash

echo "directory and name variables"
genomes="/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/genomes"
species="$1"
name="$2"
folder="/XXXXXXX/YYYYYYYYY/ZZZZZZZ/project/genomes/${species}${3}"

#####################
echo "index mapping file"
samtools index ${folder}/${species}${name}.bam
echo "create depth file"
samtools depth -a ${folder}/${species}${name}.bam > ${folder}/${species}${name}_depth.txt

echo "calculate flagstat on mapping"
samtools flagstat ${folder}/${species}${name}.bam > ${folder}/${species}${name}_stats.txt
echo "" >> ${folder}/${species}${name}_stats.txt

echo "output depth stats"
x=$(awk '{c++;s+=$3}END{print s/c}' ${folder}/${species}${name}_depth.txt)
echo "Depth (all): $x" >> ${folder}/${species}${name}_stats.txt
awk -v x=$x '{c++;d+=($3-x)**2}END{print "Depth StDev:", sqrt(d/c)}' ${folder}/${species}${name}_depth.txt >> ${folder}/${species}${name}_stats.txt
awk -v max=0 '{if(($3)>max) max=($3)}END{print "Depth Max:", max}' ${folder}/${species}${name}_depth.txt >> ${folder}/${species}${name}_stats.txt

awk '{c++; if($3>0) total+=1}END{print "Breadth: ", (total/c)*100}' ${folder}/${species}${name}_depth.txt >> ${folder}/${species}${name}_stats.txt
samtools depth ${folder}/${species}${name}.bam | awk '{c++;s+=$3}END{print "Depth (>0 coverage): ", s/c}' >> ${folder}/${species}${name}_stats.txt

#####################
