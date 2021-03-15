#!/bin/bash
#this subsets the vcf to only the ancestry of interest. I took european ancestry as an example. This will need to be changed based on what you're working on.

bcftools view -S /output_data/ancestryPCA_files/eurIDsPCA.txt \
  /output_data/outputs/multisample2401_20201216.reheader.normID.GTflt.AB.noChrM.vcf.gz -Oz > /output_data/outputs/multisample2601_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz
  
tabix -p vcf /output_data/outputs/multisample2601_20201216.reheader.EUR.normID.GTflt.AB.noChrM.vcf.gz
