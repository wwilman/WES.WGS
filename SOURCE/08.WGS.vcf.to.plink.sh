#! /bin/bash

umask 006


#this function does two things necessary for regenie step 1 and 2 outputs
# 1) it outputs the QCed vcf restricted to the chosen ancestry to a plink binary file (used in step 1 and step 2)
# 2) from this plink binary file, it further filters variants to retain only those in linkage equilibrium with MAF>1% and that attained HWE (used in step 1 only)
# the filtering of variants above is used to build the polygenic score in regenie's step 1

#paths

#path to given ancestry QCed vcf
pathAncestry=$INVCF

#path to given ancestry QCed plink binary
pathPlink=$REGENIELD

#path to pruned variants
pathPruned=$REGENIEQC


plink --vcf $pathAncestry  \
  --make-bed \
  --exclude $DIROUT/excluded.all.txt \
  --double-id \
  --out $pathPlink

# LD pruned variants for regenie step 1
plink --bfile $pathPlink \
 --hwe 1E-15 midp \
 --maf 0.01 \
 --geno 0.1 \
 --indep-pairwise 50 5 0.05 \
 --double-id \
 --out $pathPruned

