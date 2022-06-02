#!/bin/sh

genomes="/projectsc/f_geneva_1/caden/mtGenomes/genomes"
species="$1"
readLen="$2"
insert="$3"
reads=$4
subfolder=$5
refName=$6
ref="$7"
Kmer="$8"
format=$9
forward="${genomes}/${species}/${subfolder}${reads}1.fq"
reverse="${genomes}/${species}/${subfolder}${reads}2.fq"
output="${genomes}/${species}/${species}-novoplasty/"
conTemp="/projectsc/f_geneva_1/caden/mtGenomes/univ_configuration_novo.txt"
conNew="${output}novo_config_${species}_${format}_${refName}_${Kmer}.txt"

echo -n "$(sed -n '1,3p' ${conTemp})" > ${conNew}
echo "${species}_${9}_${6}_${8}" >> ${conNew}
echo -n "$(sed -n '4,6p' ${conTemp})" >> ${conNew}
echo "${Kmer}" >> ${conNew}
echo -n "$(sed -n '7,10p' ${conTemp})" >> ${conNew}
echo "${ref}" >> ${conNew}
echo -n "$(sed -n '11,12p' ${conTemp})" >> ${conNew}
echo "${ref}" >> ${conNew}
echo -n "$(sed -n '13,18p' ${conTemp})" >> ${conNew}
echo "${readLen}" >> ${conNew}
echo -n "$(sed -n '19p' ${conTemp})" >> ${conNew}
echo "${insert}" >> ${conNew}
echo -n "$(sed -n '20,23p' ${conTemp})" >> ${conNew}
echo "${forward}" >> ${conNew}
echo -n "$(sed -n '24p' ${conTemp})" >> ${conNew}
echo "${reverse}" >> ${conNew}
echo -n "$(sed -n '25,37p' ${conTemp})" >> ${conNew}
echo "${output}" >> ${conNew}
