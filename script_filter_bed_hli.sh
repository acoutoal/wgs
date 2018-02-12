#!/bin/bash
#$ -S /bin/bash
#$ -pe orte 1
#$ -cwd
#$ -N filter
#$ -j y 
#$ -q newnodes.q,shortterm.q,longterm.q

echo "##################################################################"
echo Running job $JOB_ID on host `hostname`
echo Time is `date`
echo Directory is `pwd`
echo Running shell from $SHELL
echo Local tmp dir $TMPDIR
echo Processing file $INPUTFILE
echo "##################################################################"
echo

#Load modules
module load zlib/1.2.8
module load vcftools/0.1.15
module load htslib/1.3.1
#module load bcftools/1.3.1
module load tabix/0.2.6

#Setup environment variables
shopt -s globstar
shopt -s nullglob

ls $TMPDIR
mkdir -p $TMPDIR/$USER/$JOB_ID

INPUTDIR=/home/DTR/DTR_Shared_Data/HLI/HLI_HG38
TMPOUTDIR=$TMPDIR/$USER/$JOB_ID
OUTPUTDIR=/home/alvesa/proj/hli/hg38/vcf

#Go to vcf files dir
cd $INPUTDIR

echo;echo "Filtering file "$INPUTFILE
echo;echo "TMP output dir "$TMPOUTDIR

#Filter regions and generate a new VCF files
vcftools --bed high_pass_rate_region.bed --gzvcf $INPUTFILE --recode --recode-INFO-all -c | bgzip -c > $TMPOUTDIR/FILTERED_$INPUTFILE  
cd $TMPOUTDIR/
tabix -p vcf FILTERED_$INPUTFILE

echo;echo Moving filtered files to file server
mv * $OUTPUTDIR

echo;echo Unlinking tmp files
rm -r $TMPDIR/$USER

echo "##################################################################"
echo  Finished running script on host `hostname`
echo  Time is `date`
echo "##################################################################"



