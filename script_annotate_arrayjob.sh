#!/bin/bash
#$ -S /bin/bash
#$ -pe orte 1
#$ -cwd
#$ -N arrayanne
#$ -j y 
#$ -q newnodes.q,shortterm.q,longterm.q

echo "##################################################################"
echo Running job $JOB_ID on host `hostname`
echo Time is `date`
echo Directory is `pwd`
echo Running shell from $SHELL
echo Local tmp dir $TMPDIR
echo Task id $SGE_TASK_ID
echo "##################################################################"
echo

#Load modules
module load jdk/1.8.0_15_26-b00 
module load zlib/1.2.8
module load htslib/1.3.1
module load bcftools/1.3.1

#Setup environment variables
shopt -s globstar
shopt -s nullglob

INPUTDIR=/home/alvesa/proj/hli/hg38/vcf/merged
OUTPUTDIR=/home/alvesa/proj/hli/hg38/vcf/merged/annotated
TMPINPUTDIR=$TMPDIR/INPUT
TMPOUTDIR=$TMPDIR/$USER/$JOB_ID
INPUTVCF='chr'$SGE_TASK_ID'_HG38_HLI_HIGHPASS_WG.vcf.gz'
INPUTTBI='chr'$SGE_TASK_ID'_HG38_HLI_HIGHPASS_WG.vcf.gz.tbi'
OUTFILE=$(basename $INPUTVCF .vcf.gz |  xargs -i echo {}'_dbsnp144.vcf')

#make dirs
ls $TMPDIR
mkdir -p $TMPOUTDIR
mkdir -p $TMPINPUTDIR

echo;echo "Copying input files from "$INPUTDIR
echo;echo "TMP input dir "$TMPINPUTDIR

#Copy input vcf and tbi files to local dir
cp $INPUTDIR/$INPUTVCF $TMPINPUTDIR/
cp $INPUTDIR/$INPUTTBI $TMPINPUTDIR/
cp /home/alvesa/annotations/hg38/dbsnp_144.hg38.chr.* $TMPINPUTDIR/
cp /home/alvesa/annotations/hg38/GRCh38.primary_assembly.genome.* $TMPINPUTDIR/

echo;echo "Filtering file "$INPUTFILE
echo;echo "TMP output dir "$TMPOUTDIR

#Go to input vcf files dir
cd $TMPINPUTDIR

echo "Annotating " $INPUTVCF; 
java -jar ~/bin/GenomeAnalysisTK.jar \
   -T VariantAnnotator \
   -R GRCh38.primary_assembly.genome.fa \
   -D dbsnp_144.hg38.chr.vcf.gz \
   -V $INPUTVCF \
   -o $TMPOUTDIR/$OUTFILE 

echo;echo "Changing directory to output dir "  $TMPOUTDIR; 
cd $TMPOUTDIR/

echo "BGZIP Compressing " $OUTFILE; 
bgzip -c $OUTFILE > $OUTFILE'.gz'

echo "Indexing with tabix " $OUTFILE'.gz'; 
tabix -p vcf $OUTFILE'.gz'

echo;echo Moving filtered file to file server
echo;echo `ls -h`

mv $OUTFILE'.gz' $OUTPUTDIR
mv $OUTFILE'.gz.tbi' $OUTPUTDIR

echo;echo Unlinking tmp files
rm -r $TMPDIR/

echo "##################################################################"
echo  Finished running script on host `hostname`
echo  Time is `date`
echo "##################################################################"


