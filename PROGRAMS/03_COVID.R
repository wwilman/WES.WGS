##****************************************************************
##*
##*
##*                      ....  COVID03 ....
##*
##*
##* 1) from the 1000G file, only use the variants also found in your specific cohort, and further prune them to MAF over 10% and in linkage equilibrium
##* 2) from your cohort variant file, only select those pruned variants from step 2
##* 3) merge the 1000G file and you cohort's file, with only those pruned variants
##* 4) perform PCA on 1000G using this variant set, and project your cohort's genotype on the resulting PCs
##* 5) train a random forest with 6 principal components on the 1000G dataset
##* 6) predict the ancestry in your cohort using that trained random forest and your cohort's projection on 1000G's PCs
##* 7) output files named like "afrIDsPCA.txt", for the study IDs of individuals predicted to be of a certain ancestry (here african, for example).
##****************************************************************

umask 006

date

#***  Input files ***
export DIROUT=$OUTPUT
export DIRDOWNLOADS=$DOWNLOADS

#*** Output files ***
export LOG3=$LOG/03.ancestryPCA.R.log

#*** run program ***
Rscript --vanilla $SOURCE/03.ancestryPCA.R $DIROUT $DIRDOWNLOADS    

rcode=$?
if [ $rcode -ne 0 ] ; then
   echo "error in BASH job $SOURCE/03.ancestryPCA.R.sh ";
   exit -1;
fi

date
