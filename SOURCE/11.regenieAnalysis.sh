#! /bin/bash

umask 006

#this performs the actual regenie analyses (steps 1 and 2, with and without the common variant exclusion file)
#note that the --htp option in regenie step 2 is important for the meta-analysis, so please make sure to use it

#paths

#path to QCed plink binaries
pathPlink=$REGENIELD
#path to covariates file
pathCov="$DIRPCA"/covar.txt
#path to phenotype file
pathPheno="$DIRREGENIE"/pheno.txt
#path to regenie tmp folder
pathTmpReg="$DIRREGENIEOUT"/tmp/
#path to pruned variants
pathPruned=$REGENIEQC
#path to regenie inputs, where the mask.def, set.list, anno.file, and aaf.file are located. mask.def can be found on the git
pathReg="$DIRREGENIE"/
#path to regenie results folder
pathOut="$DIRREGENIEOUT"/



#step 1 is common to all

regenie \
  --step 1 \
  --bed $pathPlink \
  --covarFile $pathCov \
  --phenoFile $pathPheno \
  --bt \
  --lowmem \
  --lowmem-prefix "${pathTmpReg}"tmp_rg \
  --extract "${pathPruned}".prune.in \
  --bsize 1000 \
  --out "${pathOut}"step1AllPhenoLD


#with the local and gnomAD exclusion only
regenie \
  --step 2 \
  --minMAC 1 \
  --covarFile $pathCov \
  --phenoFile $pathPheno \
  --bed $pathPlink \
  --aaf-bins 0.01,0.001 \
  --build-mask 'max' \
  --mask-def "${pathReg}"regenie.mask.def.txt \
  --set-list "${pathReg}"regenie.set.list.txt \
  --anno-file "${pathReg}"regenie.anno.file.txt \
  --aaf-file "${pathReg}"regenie.aaf.file.txt \
  --bt \
  --htp \
  --firth --approx \
  --pred "${pathOut}"step1AllPhenoLD_pred.list \
  --bsize 200 \
  --out "${pathOut}"burden.res.gnomad
  
  
  
#with the pooled exclusion list (named exclusionList.txt below), to be given to the participating cohorts
#regenie \
#  --step 2 \
#  --exclude-sets $DIROUT/common.zero.one.perc.ExomeEur.txt \
#  --minMAC 1 \
#  --covarFile $pathCov \
#  --phenoFile $pathPheno \
#  --bed $pathPlink \
#  --aaf-bins 0.01,0.001 \
#  --build-mask 'max' \
#  --mask-def "${pathReg}"regenie.mask.def.txt \
#  --set-list "${pathReg}"regenie.set.list.txt \
#  --anno-file "${pathReg}"regenie.anno.file.txt \
#  --aaf-file "${pathReg}"regenie.aaf.file.txt \
#  --bt \
#  --htp \
#  --firth --approx \
#  --pred "${pathOut}"step1AllPhenoLD_pred.list \
#  --bsize 200 \
#  --out "${pathOut}"burden.res.common