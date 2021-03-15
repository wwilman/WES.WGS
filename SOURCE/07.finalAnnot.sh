#! /bin/bash

umask 006

####################################################
#this annotates each chromosome using VEP and dbNSFP
#again, this could be sped up using PBS arrays if your cluster permits
#it assumes that vep was installed to work offline, and with a cache directory
#the --fork 10 makes it faster, but can give trouble sometimes
#here I did it on the european population, but it can be done once on the whole sample (then used in each ancestry stratified analysis).
####################################################

for chr in {1..22} X; do
  vep -i $DIROUT/"$PREFIX".chr"${chr}""$SUFFIX" \
    --plugin dbNSFP,$DIRDOWNLOADS/dbNSFP4.1a_grch38.gz,Ensembl_transcriptid,Uniprot_acc,VEP_canonical,LRT_pred,SIFT_pred,MutationTaster_pred,Polyphen2_HDIV_pred,Polyphen2_HVAR_pred \
    --everything \
    --buffer_size 10000 \
    --fork 10 \
    --offline \
    --no_stats \
    --cache -o $DIRANNOT/finalAnnot.chr"${chr}".txt ;
done
