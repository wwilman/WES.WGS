#! /bin/bash

umask 006

# This function exclude individuals if necessary

mv $INVCF $INVCF2

bcftools view -S ^$DIROUT/toBeRemove $INVCF2 -Oz > $INVCF
tabix -p vcf $INVCF
