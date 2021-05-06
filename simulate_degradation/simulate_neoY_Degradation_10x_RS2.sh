#!/bin/bash -l
#SBATCH --job-name=simulate_neoY_Degradation_10x_RS2
#SBATCH --output=ssimulate_neoY_Degradation_10x_RS2.o%j
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=36000
#SBATCH --time=24:00:00
#SBATCH --partition=regular
#SBATCH --account=bscb02

# for i in {1..10}; do sbatch simulate_neoY_Degradation_10x_RS2.sh 0.000001 $i; done

#date
d1=$(date +%s)
echo $HOSTNAME
echo $1
echo $2


/programs/bin/labutils/mount_server cbsufsrv5 /data1
/programs/bin/labutils/mount_server cbsubscb14 /storage


mkdir -p /workdir/$USER/$SLURM_JOB_ID
cd /workdir/$USER/$SLURM_JOB_ID

# bring in the genome assembly and other things needed from before

cp /fs/cbsubscb14/storage/jmf422/Drosophila_TEs/Dvir/Dvir_genome.fa .
cp /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard/*.fai .
cp /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard/*.dict .


GATK="/programs/bin/GATK/GenomeAnalysisTK.jar"

########## Section 1: simulate mutations in Chr3 #############

echo "Chr_3" > select.chr

xargs samtools faidx Dvir_genome.fa < select.chr > Chr_3.fa

samtools faidx Dvir_genome.fa
cat Dvir_genome.fa.fai | cut -f 1 | grep -v "Chr_3" > contigs_except.Chr3

xargs samtools faidx Dvir_genome.fa < contigs_except.Chr3 > Dvir_genome.notChr3.fa


# set environment

source /programs/miniconda3/bin/activate mutation-simulator

# run command

mutation-simulator.py Chr_3.fa args --snp $1 -titv 2

mv Chr_3_ms.fa Chr_3.$1.fa
mv Chr_3_ms.vcf Chr_3.$1.vcf

g_muts=`cat Chr_3.$1.vcf | grep -v '^#' | grep 'Chr_3' | wc -l`
printf "%f\t%i\t%i\n" $1 $2 $g_muts > Chr_3.$1.$2.genome.muts

# combine with the genome, make diploid

cat Dvir_genome.fa Dvir_genome.notChr3.fa Chr_3.$1.fa > Dvir_genome.Chr3.$1.fa


################ Section 2: simulate Illumina reads with ART #######################

/programs/art-2016.06.05/art_illumina -i Dvir_genome.Chr3.$1.fa -l 150 -f 11.64 -o simreads.$1


############## Section 3: Map reads and then Mark duplicates with Picard ###############
# note, mapping to the original genome, not the mutated one

/programs/bowtie2-2.2.8/bowtie2-build Dvir_genome.fa dvir-chromosomes

#map to the genome
/programs/bowtie2-2.2.8/bowtie2 -x dvir-chromosomes -U simreads.$1.fq -S simreads.$1_aligned.sam -p 4

echo "mapped to genome: got sam file"

# Picard
picard="/programs/picard-tools-2.19.2/picard.jar"
java -Xmx32g -jar $picard CleanSam I=simreads.$1_aligned.sam O=simreads.$1.clean.sam VALIDATION_STRINGENCY=SILENT QUIET=true COMPRESSION_LEVEL=0
java -Xmx32g -jar $picard SortSam I=simreads.$1.clean.sam O=simreads.$1.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
java -Xmx32g -jar $picard MarkDuplicates I=simreads.$1.sorted.bam O=simreads.$1.sorted.dup.bam REMOVE_DUPLICATES=true METRICS_FILE=simreads.$1.sorted.dup.metrics VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true

# read group is needed
# need to check what the read group is, how the sam file looks

RG=sim$1
PU=S1

java -Xmx32g -jar $picard AddOrReplaceReadGroups \
    I= simreads.$1.sorted.dup.bam \
    O= simreads.$1.sorted.dup.RG.bam \
    SORT_ORDER=coordinate \
    RGID= $RG \
    RGLB= 1 \
    RGPL= illumina \
    RGPU= $PU \
    RGSM= $1 \
    CREATE_INDEX=True


mv simreads.$1.sorted.dup.RG.bam vir00.sorted.dup.RG.bam
mv simreads.$1.sorted.dup.RG.bai vir00.sorted.dup.RG.bai

############ Section 4: Haplotype Caller ##############

export JAVA_HOME=/usr/local/jdk1.8.0_121
export PATH=$JAVA_HOME/bin:$PATH

GATK="/programs/bin/GATK/GenomeAnalysisTK.jar"

java -Xmx32g -jar $GATK \
-T HaplotypeCaller \
-R Dvir_genome.fa \
-I vir00.sorted.dup.RG.bam \
--emitRefConfidence GVCF \
-o vir00.HapCaller.g.vcf


########### Section 5: Genotype GVCFs #################

cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir08.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir118.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir47.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir48.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir49.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir51.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir52.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir85.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir86.HapCaller.g.vcf .
cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping_RS2/GATK/vir9.HapCaller.g.vcf .

java -Xmx32g -jar $GATK \
-T GenotypeGVCFs \
-R Dvir_genome.fa \
-V vir00.HapCaller.g.vcf \
-V vir08.HapCaller.g.vcf \
-V vir118.HapCaller.g.vcf \
-V vir47.HapCaller.g.vcf \
-V vir48.HapCaller.g.vcf \
-V vir49.HapCaller.g.vcf \
-V vir51.HapCaller.g.vcf \
-V vir52.HapCaller.g.vcf \
-V vir85.HapCaller.g.vcf \
-V vir86.HapCaller.g.vcf \
-V vir9.HapCaller.g.vcf \
-o virilis.$1.GATK.vcf


cp /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/degradation_simulation/samplenames_rename.txt .

bcftools reheader -s samplenames_rename.txt virilis.$1.GATK.vcf > rename.$1.vcf

mv rename.$1.vcf virilis.$1.GATK.vcf


########### Section 6: Filter for singleton SNPs on Chr3 ##########
vcftools --vcf virilis.$1.GATK.vcf --singletons --out virilis.$1.GATK.vcf

cat virilis.$1.GATK.vcf.singletons | grep 'vir00' | cut -f 1,2 > virilis.$1.GATK.vcf.sim.singletons ## check this

vcftools --vcf virilis.$1.GATK.vcf --positions virilis.$1.GATK.vcf.sim.singletons --recode --recode-INFO-all --out virilis.GATK.vir00.$1.singletons


# note, will need to redo for the empirical as well

java -jar /programs/bin/GATK/GenomeAnalysisTK.jar -T SelectVariants \
-R Dvir_genome.fa \
-V virilis.GATK.vir00.$1.singletons.recode.vcf \
--excludeNonVariants --restrictAllelesTo BIALLELIC \
--selectTypeToInclude SNP \
--excludeFiltered \
--selectexpressions 'vc.getGenotype("vir00").getAD().1 >= 4 && vc.getGenotype("vir00").isHet() && vc.getGenotype("vir9").isHomRef() && vc.getGenotype("vir08").isHomRef() && vc.getGenotype("vir118").isHomRef() && vc.getGenotype("vir47").isHomRef() && vc.getGenotype("vir48").isHomRef() && vc.getGenotype("vir49").isHomRef() && vc.getGenotype("vir51").isHomRef() && vc.getGenotype("vir52").isHomRef() && vc.getGenotype("vir85").isHomRef() && vc.getGenotype("vir86").isHomRef()' \
-o virilis.GATK.vir00.$1.$2.singletons.hets.vcf

r_muts=`cat virilis.GATK.vir00.$1.$2.singletons.hets.vcf | grep -v '^#' | grep 'Chr_3' | wc -l`
printf "%f\t%i\t%i\n" $1 $2 $r_muts > Chr_3.$1.$2.read.muts

cp Chr_3.$1.$2.read.muts /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/degradation_simulation/sim10x/RS2
cp Chr_3.$1.$2.genome.muts /fs/cbsubscb14/storage/jmf422/virilis_diversity/Aug2019/mapping/GATK/degradation_simulation/sim10x/RS2

cd ..


rm -r ./$SLURM_JOB_ID

#date
d2=$(date +%s)
sec=$(( ( $d2 - $d1 ) ))
hour=$(echo - | awk '{ print '$sec'/3600}')
echo Runtime: $hour hours \($sec\s\)