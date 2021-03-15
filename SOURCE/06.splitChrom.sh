#! /bin/bash

#some of the next few steps were too slow to do on the whole genome, and so I split my file in chromosomes.
#this is one of the steps that should 100% be performed using PBS arrays, if available, to speed up computing time

#path to QCed vcf restricted to given ancestry
pathAncestry=$INVCF

for chr in {1..22} X; do
  #path to split chromosomes output
  pathSplit=$DIROUT/"$PREFIX".chr"${chr}"$SUFFIX
  
  bcftools filter -r chr${chr}  ${pathAncestry} -Oz > ${pathSplit}
  tabix -p vcf ${pathSplit};
done
