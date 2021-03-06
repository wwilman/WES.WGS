#! /bin/bash

umask 006


#this file may be difficult to understand, but essentially it just builds the --set-list and --anno-file (regenie step 2 inputs) from the VEP annotation output
#if PBS arrays are available on your cluster, I highly suggest you to do it this way (instead of the for loop below).


#paths
#path to where the many temporary files will be stored
pathTmp="$DIRTMP"/
mkdir -p "${pathTmp}"tmp

#path to the regenie inputs
pathReg="$DIRREGENIE"/

for x in {1..22} X; do
#path to the VEP annotation outputs
  pathAnnot=$DIRANNOTATION/finalAnnot.chr${x}.txt

#--set-list for regenie below

  awk '/CANONICAL=YES/ && (/IMPACT=HIGH/ || /inframe_insertion/ || /inframe_deletion/ || /protein_altering_variant/ || /missense_variant/)' $pathAnnot | \
    awk '{ print $4, $1 }' | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"canon.chr${x}.var.gene.txt
  awk '{ print $1 }' "${pathTmp}"canon.chr${x}.var.gene.txt | sort | uniq | \
    awk -v a="$x" '$(NF+1) = a' | \
    awk '$(NF+1) = (FNR FS $(NF+1))' > "${pathTmp}"canon.chr${x}.gene.txt


  gene=($(awk '{print $1}' "${pathTmp}"canon.chr${x}.gene.txt))
  for ((i=0;i<${#gene[@]};++i)); do awk -v a="${gene[i]}" '{if ($1==a) print $2}' "${pathTmp}"canon.chr${x}.var.gene.txt | \
    uniq | \
    awk -f "$DIRSOURCE"/transpose.awk | \
    tr -s '[:blank:]' ","|
    awk 'BEGIN{FS=",";OFS=","} { $1=$1; print $0 }' ; done | \
    paste -d'\0'  "${pathTmp}"canon.chr${x}.gene.txt -  > "${pathTmp}"regenie.set.list.chr${x}.txt

  rm "${pathTmp}"canon.chr${x}.*

#--anno-file for regenie below

#pLOF i.e. VEP high impact

  awk '/IMPACT=HIGH/ && /CANONICAL=YES;/' $pathAnnot | \
    awk '{ print $1, $4 }' | \
    sort -u -k 1.5,1 -k 2.6,2 | \
    awk '$(NF+1) = "pLoF"' > "${pathTmp}"pLoF.chr${x}.txt


#Moderate impacts non missense 

  awk '(/inframe_insertion/ || /inframe_deletion/ || /protein_altering_variant/) && /CANONICAL=YES;/ && /IMPACT=MODERATE/' $pathAnnot | \
    awk '{ print $1, $4 }' | \
    sort -u -k 1.5,1 -k 2.6,2 | \
    awk '$(NF+1) = "moderate.non.missense"' > "${pathTmp}"moderate.non.missense.chr${x}.txt


#Missense in general, to be used below


# first only take missense variants in the canonical transcript, with a VEP_canonical annotation, and with at least one of the five in-silico algorithms annotation
  awk '/missense_variant/ && !(/inframe_insertion/ || /inframe_deletion/ || /protein_altering_variant/) && /IMPACT=MODERATE/ && /CANONICAL=YES;/ && (/SIFT_pred/ || /Polyphen2_HVAR_pred/ || /Polyphen2_HDIV_pred/ || /MutationTaster_pred/ || /LRT_pred/)' $pathAnnot > "${pathTmp}"tmp/Missense.annot.chr${x}.txt

#sift
  awk '( /VEP_canonical=[,\.]*Y/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep -o -P "(SIFT_pred=[,\.DT]*D[,\.DT]*;)" | grep -o -P "(=[,\.DT]*D[,\.DT]*;)" > "${pathTmp}"tmp/tmp.sift.count.chr${x}.txt
  awk '( /SIFT_pred=[,\.DT]*D[,\.DT]*;/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep -o -P "(VEP_canonical=.*)" | grep -o -P "(=[,\.]*Y)" | awk '{ print length }' > "${pathTmp}"tmp/tmp.siftCanonical.count.chr${x}.txt
  awk '( /VEP_canonical=[,\.]*Y/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep "SIFT_pred=[,\.DT]*D[,\.DT]*;" | awk '{ print $1, $4 }' > "${pathTmp}"tmp/tmp.siftVariant.chr${x}.txt
  paste "${pathTmp}"tmp/tmp.siftVariant.chr${x}.txt "${pathTmp}"tmp/tmp.sift.count.chr${x}.txt "${pathTmp}"tmp/tmp.siftCanonical.count.chr${x}.txt > "${pathTmp}"tmp/sift.chr${x}.txt
  rm "${pathTmp}"tmp/tmp.siftVariant.chr${x}.* "${pathTmp}"tmp/tmp.sift.count.chr${x}.* "${pathTmp}"tmp/tmp.siftCanonical.count.chr${x}.*
  awk '{ if (substr($3,$4,1) ~ /D/) { print $1, $2 } }' "${pathTmp}"tmp/sift.chr${x}.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/sift.chr${x}.del.prelim.canon.txt
  awk '{ if (!(substr($3,$4,1) ~ /D/)) { print $1, $2 } }' "${pathTmp}"tmp/sift.chr${x}.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/sift.chr${x}.nondel.canon.txt

#LRT
  awk '(/LRT_pred=D;/ && /CANONICAL=YES;/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | awk '{ print $1, $4 }' | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/LRT.chr${x}.del.prelim.canon.txt 
  awk '(/LRT_pred=[NU];/ && /CANONICAL=YES;/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | awk '{ print $1, $4 }' | sort -u -k 1.5,1 -k 2.6,2  > "${pathTmp}"tmp/LRT.chr${x}.nondel.canon.txt 

#mutation taster
  awk '(/MutationTaster_pred=[,ADNP\.]*[AD][,ADNP\.]*;/ && /CANONICAL=YES;/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | awk '{ print $1, $4 }' | sort -u -k 1.5,1 -k 2.6,2  > "${pathTmp}"tmp/mutationTaster.chr${x}.del.prelim.canon.txt
  awk '(/MutationTaster_pred=[,NP\.]*;/ && /CANONICAL=YES;/)' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | awk '{ print $1, $4 }' | sort -u -k 1.5,1 -k 2.6,2  > "${pathTmp}"tmp/mutationTaster.chr${x}.nondel.canon.txt 

#polyphen HVAR  
  grep "VEP_canonical=[,\.]*Y" "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep -o -P "(Polyphen2_HVAR_pred=[,DPB\.]*D[,DPB\.]*;)" | grep -o -P "(=[,DPB\.]*D[,DPB\.]*;)"  > "${pathTmp}"tmp/tmp.pphenHVAR.count.chr${x}.txt
  grep "Polyphen2_HVAR_pred=[,DPB\.]*D[,DPB\.]*;" "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep -o -P "(VEP_canonical=.*)" | grep -o -P "(=[,\.]*Y)" | awk '{ print length }' > "${pathTmp}"tmp/tmp.pphenHVARCanonical.count.chr${x}.txt
  grep "VEP_canonical=[,\.]*Y" "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep "Polyphen2_HVAR_pred=[,DPB\.]*D[,DPB\.]*;" | awk '{ print $1, $4 }' > "${pathTmp}"tmp/tmp.pphenHVARVariant.chr${x}.txt
  paste "${pathTmp}"tmp/tmp.pphenHVARVariant.chr${x}.txt "${pathTmp}"tmp/tmp.pphenHVAR.count.chr${x}.txt "${pathTmp}"tmp/tmp.pphenHVARCanonical.count.chr${x}.txt > "${pathTmp}"tmp/pphenHVAR.chr${x}.txt
  rm "${pathTmp}"tmp/tmp.pphenHVARVariant.chr${x}.* "${pathTmp}"tmp/tmp.pphenHVAR.count.chr${x}.* "${pathTmp}"tmp/tmp.pphenHVARCanonical.count.chr${x}.*
  awk '{ if (substr($3,$4,1) ~ /D/) { print $1, $2 } }' "${pathTmp}"tmp/pphenHVAR.chr${x}.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/pphenHVAR.chr${x}.del.prelim.canon.txt
  awk '{ if (!(substr($3,$4,1) ~ /D/)) { print $1, $2 } }' "${pathTmp}"tmp/pphenHVAR.chr${x}.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/pphenHVAR.chr${x}.nondel.canon.txt

#polyphen HDIV
  grep "VEP_canonical=[,\.]*Y" "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep -o -P "(Polyphen2_HDIV_pred=[,DPB\.]*D[,DPB\.]*;)" | grep -o -P "(=[,DPB\.]*D[,DPB\.]*;)"  > "${pathTmp}"tmp/tmp.pphenHDIV.count.chr${x}.txt
  grep "Polyphen2_HDIV_pred=[,DPB\.]*D[,DPB\.]*;" "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep -o -P "(VEP_canonical=.*)" | grep -o -P "(=[,\.]*Y)" | awk '{ print length }' > "${pathTmp}"tmp/tmp.pphenHDIVCanonical.count.chr${x}.txt
  grep "VEP_canonical=[,\.]*Y" "${pathTmp}"tmp/Missense.annot.chr${x}.txt | grep "Polyphen2_HDIV_pred=[,DPB\.]*D[,DPB\.]*;" | awk '{ print $1, $4 }' > "${pathTmp}"tmp/tmp.pphenHDIVVariant.chr${x}.txt
  paste "${pathTmp}"tmp/tmp.pphenHDIVVariant.chr${x}.txt "${pathTmp}"tmp/tmp.pphenHDIV.count.chr${x}.txt "${pathTmp}"tmp/tmp.pphenHDIVCanonical.count.chr${x}.txt > "${pathTmp}"tmp/pphenHDIV.chr${x}.txt
  rm "${pathTmp}"tmp/tmp.pphenHDIVVariant.chr${x}.* "${pathTmp}"tmp/tmp.pphenHDIV.count.chr${x}.* "${pathTmp}"tmp/tmp.pphenHDIVCanonical.count.chr${x}.*
  awk '{ if (substr($3,$4,1) ~ /D/) { print $1, $2 } }' "${pathTmp}"tmp/pphenHDIV.chr${x}.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/pphenHDIV.chr${x}.del.prelim.canon.txt
  awk '{ if (!(substr($3,$4,1) ~ /D/)) { print $1, $2 } }' "${pathTmp}"tmp/pphenHDIV.chr${x}.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/pphenHDIV.chr${x}.nondel.canon.txt


#find the ones that don't have an annotation (but still deleterious elsewhere)
#first combine all that are not deleterious in at least one of the algorithm
  cat "${pathTmp}"tmp/sift.chr${x}.nondel.canon.txt "${pathTmp}"tmp/pphenHVAR.chr${x}.nondel.canon.txt "${pathTmp}"tmp/pphenHDIV.chr${x}.nondel.canon.txt "${pathTmp}"tmp/mutationTaster.chr${x}.nondel.canon.txt "${pathTmp}"tmp/LRT.chr${x}.nondel.canon.txt | sort -u -k 1.5,1 -k 2.6,2  > "${pathTmp}"tmp/nondel.combined.chr${x}.txt

#now for each algorithm obtain the variants that are non annotated AND not-not-deleterious in any other algorithm. Then combine them with the list of deleterious variant for that algorithm
#This combined list is therefore made up of either variants that are deleterious by that algorithm, or not annotated by that algorithm but not benign in any other algorithm.
#Note that due to Missense.annot.chrZ.txt only containing variants with at least one annotation for the in-silico algorithm, these only contain variants with at least one of the in-silico algorithm annotations.
  awk 'NR==FNR{a[$1];next} { if ( !/SIFT_pred/ && /CANONICAL=YES;/ && !($1 in a)) { print $1, $4 } }' "${pathTmp}"tmp/nondel.combined.chr${x}.txt "${pathTmp}"tmp/Missense.annot.chr${x}.txt > "${pathTmp}"tmp/sift.chr${x}.NotAnnotated.txt 
  cat "${pathTmp}"tmp/sift.chr${x}.NotAnnotated.txt "${pathTmp}"tmp/sift.chr${x}.del.prelim.canon.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/sift.chr${x}.del.canon.txt 

  awk 'NR==FNR{a[$1];next} { if (!/Polyphen2_HVAR_pred/ && /CANONICAL=YES;/ && !($1 in a)) { print $1, $4 } }' "${pathTmp}"tmp/nondel.combined.chr${x}.txt "${pathTmp}"tmp/Missense.annot.chr${x}.txt > "${pathTmp}"tmp/pphenHVAR.chr${x}.NotAnnotated.txt   
  cat "${pathTmp}"tmp/pphenHVAR.chr${x}.NotAnnotated.txt "${pathTmp}"tmp/pphenHVAR.chr${x}.del.prelim.canon.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/pphenHVAR.chr${x}.del.canon.txt

  awk 'NR==FNR{a[$1];next} { if (!/Polyphen2_HDIV_pred/ && /CANONICAL=YES;/ && !($1 in a)) { print $1, $4 } }' "${pathTmp}"tmp/nondel.combined.chr${x}.txt "${pathTmp}"tmp/Missense.annot.chr${x}.txt > "${pathTmp}"tmp/pphenHDIV.chr${x}.NotAnnotated.txt 
  cat "${pathTmp}"tmp/pphenHDIV.chr${x}.NotAnnotated.txt "${pathTmp}"tmp/pphenHDIV.chr${x}.del.prelim.canon.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/pphenHDIV.chr${x}.del.canon.txt

  awk 'NR==FNR{a[$1];next} { if (!/MutationTaster_pred/ && /CANONICAL=YES;/ && !($1 in a)) { print $1, $4 } }' "${pathTmp}"tmp/nondel.combined.chr${x}.txt "${pathTmp}"tmp/Missense.annot.chr${x}.txt > "${pathTmp}"tmp/mutationTaster.chr${x}.NotAnnotated.txt 
  cat "${pathTmp}"tmp/mutationTaster.chr${x}.NotAnnotated.txt "${pathTmp}"tmp/mutationTaster.chr${x}.del.prelim.canon.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/mutationTaster.chr${x}.del.canon.txt

  awk 'NR==FNR{a[$1];next} { if (!/LRT_pred/ && /CANONICAL=YES;/ && !($1 in a)) { print $1, $4 } }' "${pathTmp}"tmp/nondel.combined.chr${x}.txt "${pathTmp}"tmp/Missense.annot.chr${x}.txt > "${pathTmp}"tmp/LRT.chr${x}.NotAnnotated.txt
  cat "${pathTmp}"tmp/LRT.chr${x}.NotAnnotated.txt "${pathTmp}"tmp/LRT.chr${x}.del.prelim.canon.txt | sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/LRT.chr${x}.del.canon.txt

#combine for missense 5 in 5
  comm -12 "${pathTmp}"tmp/sift.chr${x}.del.canon.txt \
    "${pathTmp}"tmp/pphenHVAR.chr${x}.del.canon.txt | \
    sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/tmp.chr${x}.1.txt
  comm -12 "${pathTmp}"tmp/tmp.chr${x}.1.txt \
    "${pathTmp}"tmp/pphenHDIV.chr${x}.del.canon.txt | \
    sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/tmp.chr${x}.2.txt
  comm -12 "${pathTmp}"tmp/tmp.chr${x}.2.txt \
    "${pathTmp}"tmp/mutationTaster.chr${x}.del.canon.txt | \
    sort -u -k 1.5,1 -k 2.6,2 > "${pathTmp}"tmp/tmp.chr${x}.3.txt
  comm -12 "${pathTmp}"tmp/tmp.chr${x}.3.txt \
    "${pathTmp}"tmp/LRT.chr${x}.del.canon.txt | \
    sort -u -k 1.5,1 -k 2.6,2 | \
    awk '$(NF+1) = "missense.5in5"'> "${pathTmp}"missense.5in5.chr${x}.txt

#combine for missense 1 in 5, note that this will include the 5 in 5 too
  cat "${pathTmp}"tmp/sift.chr${x}.del.canon.txt \
    "${pathTmp}"tmp/pphenHVAR.chr${x}.del.canon.txt \
    "${pathTmp}"tmp/pphenHDIV.chr${x}.del.canon.txt \
    "${pathTmp}"tmp/mutationTaster.chr${x}.del.canon.txt \
    "${pathTmp}"tmp/LRT.chr${x}.del.canon.txt | \
    sort -u -k 1.5,1 -k 2.6,2 | \
    awk 'NR==FNR{a[$1]=$1;next} !($1 in a) {print $1, $2}' "${pathTmp}"missense.5in5.chr${x}.txt - | \
    awk '$(NF+1) = "missense.1in5"'> "${pathTmp}"missense.1in5.chr${x}.txt
  
#missense only file, without in-silico algorithms support
  awk '{ print $1, $4 }' "${pathTmp}"tmp/Missense.annot.chr${x}.txt | \
    sort -u -k 1.5,1 -k 2.6,2 | \
    awk 'NR==FNR{a[$1]=$1;next} !($1 in a) {print $1, $2}' "${pathTmp}"missense.1in5.chr${x}.txt - | \
    awk 'NR==FNR{a[$1]=$1;next} !($1 in a) {print $1, $2}' "${pathTmp}"missense.5in5.chr${x}.txt - | \
    awk '$(NF+1) = "missense.0in5"' > "${pathTmp}"missense.0in5.chr${x}.txt



  rm "${pathTmp}"tmp/LRT.chr${x}.*
  rm "${pathTmp}"tmp/mutationTaster.chr${x}.*
  rm "${pathTmp}"tmp/pphenHDIV.chr${x}.*
  rm "${pathTmp}"tmp/pphenHVAR.chr${x}.*
  rm "${pathTmp}"tmp/sift.chr${x}.*
  rm "${pathTmp}"tmp/tmp.chr${x}.*
  rm "${pathTmp}"tmp/nondel.combined.chr${x}.*
  rm "${pathTmp}"tmp/Missense.annot.chr${x}.*;
done

#now build the necessary regenie step 2 inputs
cat "${pathTmp}"pLoF.chr* "${pathTmp}"moderate.non.missense.chr* "${pathTmp}"missense.5in5.chr* "${pathTmp}"missense.1in5.chr* "${pathTmp}"missense.0in5.chr* > "${pathReg}"regenie.anno.file.txt
rm "${pathTmp}"pLoF.chr* "${pathTmp}"moderate.non.missense.chr* "${pathTmp}"missense.5in5.chr* "${pathTmp}"missense.1in5.chr* "${pathTmp}"missense.0in5.chr*

cat "${pathTmp}"regenie.set.list.chr* > "${pathReg}"regenie.set.list.txt
rm "${pathTmp}"regenie.set.list.chr*
