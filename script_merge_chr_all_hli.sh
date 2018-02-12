#!/bin/bash
#$ -S /bin/bash
#$ -pe orte 1
#$ -cwd
#$ -N merge
#$ -j y 
#$ -q newnodes.q,shortterm.q,longterm.q

echo "##################################################################"
echo Running job $JOB_ID on host `hostname`
echo Time is `date`
echo Directory is `pwd`
echo Running shell from $SHELL
echo Local tmp dir $TMPDIR
echo Processing task id $SGE_TASK_ID
echo "##################################################################"
echo

#Load modules
#module load vcftools/0.1.15
module load zlib/1.2.8
module load htslib/1.3.1
module load bcftools/1.3.1

#Setup environment variables
shopt -s globstar
shopt -s nullglob

INPUTDIR=/home/alvesa/proj/hli/hg38/vcf/chr
TMPOUTDIR=$TMPDIR/$USER/$JOB_ID
TMPINPUTDIR=$TMPDIR/INPUT
OUTPUTDIR=/home/alvesa/proj/hli/hg38/vcf/merged
INPUTCHR='chr'$SGE_TASK_ID
IDFILE=hli_raw_ids_sorted.txt

#make dirs
ls $TMPDIR
mkdir -p $TMPOUTDIR
mkdir -p $TMPINPUTDIR

echo;echo "Task id "$SGE_TASK_ID
echo;echo "TMP input dir "$TMPINPUTDIR

#Copy input vcf and tbi files to local dir
cp $INPUTDIR/'PASS_'$INPUTCHR'_'* $TMPINPUTDIR/
cp /home/alvesa/proj/hli/bin/hli_rename_ids.txt $TMPINPUTDIR/

echo;echo "Processing "$INPUTCHR
echo;echo "TMP output dir "$TMPOUTDIR

#Generate list of input VCF file name
cat $IDFILE | xargs -i echo 'PASS_'$INPUTCHR'_'{}'.vcf.gz' > $TMPINPUTDIR/input_vcf_files.txt
echo;echo "Generating list of input vcf files. Number of files "$(wc -l $TMPINPUTDIR/input_vcf_files.txt)

#Go to input vcf files dir
cd $TMPINPUTDIR
OUTFILE=$INPUTCHR'_HG38_HLI_HIGHPASS_WG.vcf.gz'
/home/alvesa/gitrepo/bcftools/bcftools merge \
-0 \
-i END:max,SNVSB:avg,SNVHPOL:max,REFREP:max,IDREP:max \
-l $TMPINPUTDIR/input_vcf_files.txt \
-m both \
-O v | /home/alvesa/gitrepo/bcftools/bcftools reheader -s hli_rename_ids.txt | bgzip -c > $TMPOUTDIR/$OUTFILE

cd $TMPOUTDIR/
echo "Indexing with tabix " $OUTFILE; 
tabix -p vcf $OUTFILE

echo;echo Moving filtered files to file server
cd $TMPOUTDIR/
echo;echo `ls -h`
echo;echo "Number of files moved: " `ls | wc -l`
mv * $OUTPUTDIR

echo;echo Unlinking tmp files
rm -r $TMPDIR/

echo "##################################################################"
echo  Finished running script on host `hostname`
echo  Time is `date`
echo "##################################################################"
