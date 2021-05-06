#!/bin/bash -l
#SBATCH --job-name=GenotypeGVCFs_RS2_Yfushet
#SBATCH --output=GenotypeGVCFs_RS2_Yfushet.o%j
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=36000
#SBATCH --time=04:00:00
#SBATCH --partition=short
#SBATCH --account=bscb02


#qsub HaplotypeCaller.sh <line name>


#date
d1=$(date +%s)
echo $HOSTNAME
echo $1

/programs/bin/labutils/mount_server cbsuclarkfs1 /storage ## Mount data server
/programs/bin/labutils/mount_server cbsubscb14 /storage

mkdir -p /workdir/$USER/$SLURM_JOB_ID

cd /workdir/$USER/$SLURM_JOB_ID


# copy in the genome files
cp /fs/cbsubscb14/storage/jmf422/Drosophila_TEs/Dvir/Dvir_genome.fa .
cp /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard/*.fai .
cp /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/Picard/*.dict .

cp /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/GATK/virilis_3versions.GATK.vcf .

GATK="/programs/bin/GATK/GenomeAnalysisTK.jar"

export JAVA_HOME=/usr/local/jdk1.8.0_121
export PATH=$JAVA_HOME/bin:$PATH


java -jar /programs/bin/GATK/GenomeAnalysisTK.jar -T SelectVariants \
-R Dvir_genome.fa \
-V virilis_3versions.GATK.vcf \
--excludeNonVariants --restrictAllelesTo BIALLELIC \
--selectTypeToInclude SNP \
--excludeFiltered \
--selectexpressions 'vc.getGenotype("Yfus").isHet() && vc.getGenotype("vir08").isHomRef() && vc.getGenotype("vir118").isHomRef() && vc.getGenotype("vir47").isHomRef() && vc.getGenotype("vir48").isHomRef() && vc.getGenotype("vir49").isHomRef() && vc.getGenotype("vir51").isHomRef() && vc.getGenotype("vir52").isHomRef() && vc.getGenotype("vir85").isHomRef() && vc.getGenotype("vir86").isHomRef() && vc.getGenotype("vir9").isHomRef()' \
-o virilis_3versions.Yfushets.only.GATK.vcf 

java -jar /programs/bin/GATK/GenomeAnalysisTK.jar -T SelectVariants \
-R Dvir_genome.fa \
-V virilis_3versions.GATK.vcf \
--excludeNonVariants --restrictAllelesTo BIALLELIC \
--selectTypeToInclude SNP \
--excludeFiltered \
--selectexpressions 'vc.getGenotype("Xfus").isHet() && vc.getGenotype("vir08").isHomRef() && vc.getGenotype("vir118").isHomRef() && vc.getGenotype("vir47").isHomRef() && vc.getGenotype("vir48").isHomRef() && vc.getGenotype("vir49").isHomRef() && vc.getGenotype("vir51").isHomRef() && vc.getGenotype("vir52").isHomRef() && vc.getGenotype("vir85").isHomRef() && vc.getGenotype("vir86").isHomRef() && vc.getGenotype("vir9").isHomRef()' \
-o virilis_3versions.Xfushets.only.GATK.vcf

java -jar /programs/bin/GATK/GenomeAnalysisTK.jar -T SelectVariants \
-R Dvir_genome.fa \
-V virilis_3versions.GATK.vcf \
--excludeNonVariants --restrictAllelesTo BIALLELIC \
--selectTypeToInclude SNP \
--excludeFiltered \
--selectexpressions 'vc.getGenotype("Nofus-1").isHet() && vc.getGenotype("vir08").isHomRef() && vc.getGenotype("vir118").isHomRef() && vc.getGenotype("vir47").isHomRef() && vc.getGenotype("vir48").isHomRef() && vc.getGenotype("vir49").isHomRef() && vc.getGenotype("vir51").isHomRef() && vc.getGenotype("vir52").isHomRef() && vc.getGenotype("vir85").isHomRef() && vc.getGenotype("vir86").isHomRef() && vc.getGenotype("vir9").isHomRef()' \
-o virilis_3versions.Nofushets.only.GATK.vcf



cp virilis_3versions.*fushets.only.GATK.vcf /fs/cbsuclarkfs1/storage/jmf422/vir00_3versions/catfiles/mapping/GATK/

cd ..
rm -r ./$SLURM_JOB_ID

#date
d2=$(date +%s)
sec=$(( ( $d2 - $d1 ) ))
hour=$(echo - | awk '{ print '$sec'/3600}')
echo Runtime: $hour hours \($sec\s\)