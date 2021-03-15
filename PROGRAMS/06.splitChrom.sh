#!/bin/bash
#some of the next few steps were too slow to do on the whole genome, and so I split my file in chromosomes.
#this is one of the steps that should 100% be performed using PBS arrays, if available, to speed up computing time

for chr in {1..22} X Y; do
  bcftools filter -r chr"${chr}" /../output_data/outputs/multisample2601_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz -Oz \
    > /../output_data/outputs/EUR/ALL.chr"${chr}".reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz
    tabix -p vcf /../output_data/outputs/EUR/ALL.chr"${chr}".reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz;
done

