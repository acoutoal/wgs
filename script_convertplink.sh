#!/bin/bash
#$ -S /bin/bash
#$ -pe orte 1
#$ -cwd
#$ -N conplink
#$ -j y 
#$ -q newnodes.q,shortterm.q,longterm.q
#$ -l h=!node004

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
module load zlib/1.2.8
module load htslib/1.3.1
module load bcftools/1.3.1
module load plink/1.90b3.26

#Setup environment variables
shopt -s globstar
shopt -s nullglob

INPUTDIR=/home/alvesa/proj/hli/hg38/vcf/merged/annotated/
OUTPUTDIR=/home/alvesa/proj/hli/hg38/vcf/merged/plink
TMPINPUTDIR=$TMPDIR/INPUT
TMPOUTDIR=$TMPDIR/$USER/$JOB_ID
INPUTVCF='chr'$SGE_TASK_ID'_HG38_HLI_HIGHPASS_WG_dbsnp144.vcf.gz'
INPUTTBI='chr'$SGE_TASK_ID'_HG38_HLI_HIGHPASS_WG_dbsnp144.vcf.gz.tbi'
OUTFILE=$(basename $INPUTVCF .vcf.gz)

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
echo;echo `ls -lh`
echo;echo
echo "Converting to plink " $INPUTVCF; 
/home/alvesa/gitrepo/bcftools/bcftools norm -Ou -m -any $INPUTVCF |
/home/alvesa/gitrepo/bcftools/bcftools norm -Ou -f GRCh38.primary_assembly.genome.fa |
/home/alvesa/gitrepo/bcftools/bcftools annotate -Ob -x ID \
    -I +'%CHROM:%POS:%REF:%ALT' |
  plink --bcf /dev/stdin \
    --keep-allele-order \
    --vcf-idspace-to _ \
    --const-fid \
    --allow-extra-chr 0 \
    --split-x b38 no-fail \
    --make-bed \
    --out $TMPOUTDIR/$OUTFILE 

echo;echo "Changing directory to output dir "  $TMPOUTDIR; 
cd $TMPOUTDIR/

echo;echo Moving files to fileserver
echo;echo `ls -h`

mv * $OUTPUTDIR

echo;echo Unlinking tmp files
rm -r $TMPDIR/

echo "##################################################################"
echo  Finished running script on host `hostname`
echo  Time is `date`
echo "##################################################################"



