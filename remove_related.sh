#!/usr/bin/env bash
#USAGE: ./remove_related.sh [threshold] [freq/miss] [no_reps*]
#Must follow this command order
#Requires relatedness estimates, replicate file names, and missingness per individual named as: RelatednessEstimates.Txt bad_reps.txt missing.txt
#Input format for RelatednessEstimates.Txt are outputs from coancestry (R)
#Input format for bad_reps.txt is one individual to remove per line. *If you have no replicates, supply "no_reps" as the 3rd argument
#Input format for missing.txt is: ind %miss

#Inputs check
if [[ -z $1 ]];then
	echo "Error: please specify a threshold!"
	exit 1
fi

if [[ -z $2 ]];then
	echo "Error: please specify removal type [freq/miss]!"
	exit 1
fi

if [[ -f "remove.txt" ]];then
	rm remove.txt
fi

count=0

#Parse related pairs at threshold value, keeping only individuals from the same sample site as well as removing replicates
awk -F "," -v threshold=$1 '$9>threshold {print $2,$3,$9}' RelatednessEstimates.Txt | awk 'gsub("_"," ")' | awk '$1==$3 {print $2,$4,$1,$5}' > related_ind.txt

if [[ $3 == "no_reps" ]];then
	cp related_ind.txt related_1.tmp
else
	grep -vf bad_reps.txt related_ind.txt > related_1.tmp
	cp related_1.tmp related_ind.txt
fi

echo "Found `wc -l related_ind.txt | cut -f1 -d " "` related pairs"

####Count option###
if [[ $2 == "freq" ]];then

#Find unique individuals and get initial frequency counts
awk '{print $1"\n"$2}' related_ind.txt | sort | uniq -c | awk 'gsub("^[ ]+","")' | sort -nr > unique_ind.txt
echo "Found `wc -l unique_ind.txt | cut -f1 -d " "` unique individuals"

#Remove individuals first by frequency, leaving individual comparisons to remove by hand later
cp unique_ind.txt unique.tmp
max=`head -n1 unique.tmp | cut -d " " -f1`

while [[ "$max" -gt 1 ]];do
	remove=`head -n1 unique.tmp | cut -d " " -f2`
	echo $remove >> remove.txt
	grep -v $remove related_1.tmp > related_2.tmp
	mv related_2.tmp related_1.tmp
	awk '{print $1"\n"$2}' related_1.tmp | sort | uniq -c | awk 'gsub("^[ ]+","")' | sort -nr > unique.tmp
	max=`head -n1 unique.tmp | cut -d " " -f1`
	((++count))
	printf "\rRemoved $count individuals"
done

#Remove remaining individuals based on missing data
paste -d " " <(join -1 1 -2 1 -o 1.1,2.2 <(sort -k1 related_1.tmp) <(sort -k1 missing.txt)) <(join -1 2 -2 1 -o 1.2,2.2 <(sort -k2 related_1.tmp) <(sort -k1 missing.txt)) > related_2.tmp

while read line;do
	miss1=`echo $line | cut -d " " -f2`
	miss2=`echo $line | cut -d " " -f4`
	if (( $(echo "$miss2 > $miss1" | bc -l) ));then
		echo `echo $line | cut -d " " -f3` >> remove.txt
	else
		echo `echo $line | cut -d " " -f1` >> remove.txt
	fi
	((++count))
	printf "\rRemoved $count individuals"
done < related_2.tmp


####Miss option###
elif [[ $2 == "miss" ]];then

#Find unique individuals and attach missingness
awk '{print $1"\n"$2}' related_ind.txt | sort -u > unique_ind.txt
echo "Found `wc -l unique_ind.txt | cut -f1 -d " "` unique individuals"
join -1 1 -2 1 -o 1.1,2.2 <(sort -k1 unique_ind.txt) <(sort -k1 missing.txt) | sort -nr -k2 > unique.tmp
mv unique.tmp unique_ind.txt

while read line;do
	name=`echo $line | cut -d " " -f1`
	if [[ `grep $name related_1.tmp | wc -l` -gt 0 ]];then
		grep -v $name related_1.tmp > related_2.tmp
		mv related_2.tmp related_1.tmp
		echo $name >> remove.txt
		((++count))
		printf "\rRemoved $count individuals"
	fi
done < unique_ind.txt

fi

echo ""
rm *.tmp
