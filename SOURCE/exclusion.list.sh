#!/bin/bash
bcftools view --exclude 'AF<0.01' ../outputs/multisample_20201216.reheader.normID.GTflt.AB.noChrM.vcf.gz | \
	bcftools view --exclude 'AF>0.99' | \
  bcftools query -H -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\n' > ../outputs/fullVariantList_II.txt
