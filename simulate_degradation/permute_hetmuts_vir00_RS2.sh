#!/bin/bash -l
#SBATCH --job-name=permute_hetmuts_vir00_RS2
#SBATCH --output=permute_hetmuts_vir00_RS2.o%j
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=2000
#SBATCH --time=04:00:00
#SBATCH --partition=short
#SBATCH --account=bscb02



#date
d1=$(date +%s)
echo $HOSTNAME
echo $1


/programs/bin/labutils/mount_server cbsufsrv5 /data1
/programs/bin/labutils/mount_server cbsubscb14 /storage


mkdir -p /workdir/$USER/$SLURM_JOB_ID
cd /workdir/$USER/$SLURM_JOB_ID

# bring in the genome assembly from before

cp /fs/cbsubscb14/storage/jmf422/Drosophila_TEs/Dvir/Dvir_genome.fa .


cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/degradation_simulation/Dvir_Chr.txt .

samtools faidx Dvir_genome.fa
cat Dvir_genome.fa.fai | cut -f 1,2 | sort -k1 | grep -f Dvir_Chr.txt > Dvirgenome.file
#cp Dvirgenome.file /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/degradation_simulation

# shuffle - n= the number of mutations 
for ((i=1;i<=1000;i++))
do 
	bedtools random -l 1 -n 1552 -g Dvirgenome.file | grep 'Chr_3' | wc -l > num_chr3
	cat num_chr3 | awk -v OFS="\t" '{print $1, $1/28.195}' >> Dvir_random_Chr3_muts.onlyChr.Xfus.txt
done

#bedtools random -l 1 -n 533 -g dvir-chromosomes-r1.06.fa > test.random


#cp test.random /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/singleton_indels_by_chr
cp Dvir_random_Chr3_muts.onlyChr.Xfus.txt /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/degradation_simulation/RS2

cd ..


rm -r ./$SLURM_JOB_ID

#date
d2=$(date +%s)
sec=$(( ( $d2 - $d1 ) ))
hour=$(echo - | awk '{ print '$sec'/3600}')
echo Runtime: $hour hours \($sec\s\)