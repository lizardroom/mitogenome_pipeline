#!/bin/sh

sample_file="/projectsc/f_geneva_1/caden/mtGenomes/mitogenome_pipeline/species_list.txt"
line_count=$(wc -l < ${sample_file})

mkdir -p /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub

cd /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub

#run initial rogueNaRok analysis
/projectsc/f_geneva_1/caden/apps/RogueNaRok/RogueNaRok \
	-i /projectsc/f_geneva_1/caden/mtGenomes/mrB/conc_nuc/conc_nuc_0.5burn.nwk \
	-n original

rogue_stat="/projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/RogueNaRok_droppedRogues.original"
new_stat=$(echo "$(sed -n '2p' ${rogue_stat})" | awk '{print $5}')
printf "original\t${new_stat}\n" >> /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/RogueNaRok_stats.txt

#loop through list of species names 
for (( samp_line = 1; samp_line <= $line_count; samp_line++))  #loop through lines in sample ID file. $line_count
do
	# pull the species name from the selected line
	species=$(sed -n "${samp_line}p" ${sample_file} | tr -d '\n')
	echo "${species}"
 
	echo "${species}" > /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/${species}.txt


	/projectsc/f_geneva_1/caden/apps/RogueNaRok/rnr-prune \
		-i /projectsc/f_geneva_1/caden/mtGenomes/mrB/conc_nuc/conc_nuc_0.5burn.nwk \
		-x /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/${species}.txt \
		-n reduce_${species}

	#run rogueNaRok analysis on new tree with species that was cut
	/projectsc/f_geneva_1/caden/apps/RogueNaRok/RogueNaRok \
		-i /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/RnR-prune_prunedBootstraps.reduce_${species} \
		-n post_${species}

	rogue_stat="/projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/RogueNaRok_droppedRogues.post_${species}"

	new_stat=$(echo "$(sed -n '2p' ${rogue_stat})" | awk '{print $5}')
	printf "${species}\t${new_stat}\n" >> /projectsc/f_geneva_1/caden/mtGenomes/roguenarok_pub/RogueNaRok_stats.txt

done
