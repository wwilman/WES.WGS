#!/bin/bash
#this function outputs PCA results from common and rare variants from the selected ancestry obtained in the previous step.
#again I assume european ancestry here, as per previous step.

#mkdir -p PCA

#common
plink --vcf /output_data/outputs/multisample2401_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz \
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
--out commonAllelesPruned


plink --vcf /output_data/outputs/multisample2401_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz \
--extract commonAllelesPruned.prune.in \
--pca 10 \
--double-id \
--out commonPCA.txt


#rare, given the relatively small size of my cohort, I set a MAC threshold of 2. This can be adjusted by each cohort.

plink --vcf /output_data/outputs/multisample2401_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz \
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
--out rareAllelesPruned


plink --vcf /output_data/outputs/multisample2401_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz \
--extract rareAllelesPruned.prune.in \
--pca 20 \
--double-id \
--out rarePCA.txt
