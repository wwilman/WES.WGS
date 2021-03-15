#! /bin/bash

#this subsets the vcf to only the ancestry of interest. I took european ancestry as an example. This will need to be changed based on what you're working on.

#paths

#path to ancestry IDs
pathID=$DIROUT/eurIDsPCA.txt

#path to QCed vcf
pathQC=$INHAIL

#path to QCed vcf restricted to the ancestry of interest
pathAncestry=$OUT4

#this splits the vcf to only the ancestry of interest. To change based on what you're working on.

bcftools view -S $pathID $pathQC -Oz > $pathAncestry
  
tabix -p vcf $pathAncestry

