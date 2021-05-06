#!/bin/bash -l
#SBATCH --job-name=HaplotypeCaller_RS2_vir00_1
#SBATCH --output=HaplotypeCaller_RS2_vir00_1.o%j
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=36000
#SBATCH --time=24:00:00
#SBATCH --partition=regular
#SBATCH --account=bscb02


#qsub HaplotypeCaller.sh <line name>


#date
d1=$(date +%s)
echo $HOSTNAME
echo $1

#/programs/bin/labutils/mount_server cbsufsrv5 /data1 ## Mount data server
/programs/bin/labutils/mount_server cbsubscb14 /storage

mkdir -p /workdir/$USER/$SLURM_JOB_ID

cd /workdir/$USER/$SLURM_JOB_ID


# copy in the sam file
cp /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/$1_aligned.sam .


# Picard
picard="/programs/picard-tools-2.19.2/picard.jar"
java -Xmx32g -jar $picard CleanSam I=$1_aligned.sam O=$1.clean.sam VALIDATION_STRINGENCY=SILENT QUIET=true COMPRESSION_LEVEL=0
java -Xmx32g -jar $picard SortSam I=$1.clean.sam O=$1.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
java -Xmx32g -jar $picard MarkDuplicates I=$1.sorted.bam O=$1.sorted.dup.bam REMOVE_DUPLICATES=true METRICS_FILE=$1.sorted.dup.metrics VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true

# read group is needed
# need to check what the read group is, how the sam file looks

RG=`cat $1_aligned.sam | grep -v '^@' | cut -f 1 | cut -f 1 -d ':' | head -n 1`
PU=`cat $1_aligned.sam | grep -v '^@' | cut -f 1 | cut -f 3 -d ':' | head -n 1`

java -Xmx32g -jar $picard AddOrReplaceReadGroups \
    I= $1.sorted.dup.bam \
    O= $1.sorted.dup.RG.bam \
    SORT_ORDER=coordinate \
    RGID= $RG \
    RGLB= 1 \
    RGPL= illumina \
    RGPU= $PU \
    RGSM= $1 \
    CREATE_INDEX=True


# copy in the genome used
cp /fs/cbsubscb14/storage/jmf422/Drosophila_TEs/Dvir/Dvir_genome.fa .

java -Xmx32g -jar $picard CreateSequenceDictionary R=Dvir_genome.fa O=Dvir_genome.dict

samtools faidx Dvir_genome.fa

cp *.fai /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard
cp *.dict /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard
cp $1.sorted.dup.RG.ba* /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard


GATK="/programs/bin/GATK/GenomeAnalysisTK.jar"

export JAVA_HOME=/usr/local/jdk1.8.0_121
export PATH=$JAVA_HOME/bin:$PATH

java -Xmx32g -jar $GATK \
-T HaplotypeCaller \
-R Dvir_genome.fa \
-I $1.sorted.dup.RG.bam \
--emitRefConfidence GVCF \
-nct 1 -o $1.HapCaller.g.vcf


mv $1.HapCaller.g.vcf /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/GATK



cd ..
rm -r ./$SLURM_JOB_ID

#date
d2=$(date +%s)
sec=$(( ( $d2 - $d1 ) ))
hour=$(echo - | awk '{ print '$sec'/3600}')
echo Runtime: $hour hours \($sec\s\)