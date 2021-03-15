#! /bin/bash

umask 006

#this function outputs PCA results from common and rare variants from the selected ancestry obtained in the previous step.
#these PCs will be used in the covar file input in regenie (code to build that file is not shown in the git, since it's too dependent on how your data is stored

#paths

#path to QCed vcf restricted to ancestry of interest
pathAncestry=$INVCF

#path to ouput directory
pathPCA=$DIRPCA

#common
plink --vcf $pathAncestry \
--biallelic-only strict \
--chr 1-22 \
--geno 0.05 \
--snps-only 'just-acgt' \
--hwe 1E-6 midp \
--indep-pairwise 50 5 0.05 \
--keep-allele-order \
--mac 5 \
--maf 0.01 \
--double-id \
--out "${pathPCA}"/commonAllelesPruned


plink --vcf $pathAncestry \
--extract "${pathPCA}"/commonAllelesPruned.prune.in \
--pca 10 \
--double-id \
--out "${pathPCA}"/commonPCA.txt


#rare

plink --vcf $pathAncestry \
--biallelic-only strict \
--chr 1-22 \
--geno 0.05 \
--snps-only 'just-acgt' \
--hwe 1E-6 midp \
--indep-pairwise 50 5 0.05 \
--keep-allele-order \
--max-maf 0.01 \
--mac 2 \
--double-id \
--out "${pathPCA}"/rareAllelesPruned


plink --vcf $pathAncestry \
--extract "${pathPCA}"/rareAllelesPruned.prune.in \
--pca 20 \
--double-id \
--out "${pathPCA}"/rarePCA.txt
