#this is somewhat of a long file, because it is split in four masks.
#it uses the M1.GT.R M2.GT.R M3.GT.R and M4.GT.R functions

#builds the header for the vcf file I'm building
zcat /scratch/richards/guillaume.butler-laporte/WGS/allSamples.Eur.normID.rehead.GTflt.AB.noChrXYM.vqsr.flt.vcf.gz | head -n 5000 | grep '#CHROM'  > /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/VCF.sct.regenie/columns.txt

###### M1 note that this uses max AF among 1000 genomes, ESP, and gnomAD populations, combined. ######
#first filter for the correct variants
for i in {1..22}; do awk '/LoF=HC/ && /CANONICAL=YES/ && !/MAX_AF=0.[0-9][1-9]*;/' /scratch/richards/guillaume.butler-laporte/WGS/annotation/finalAnnot.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.annot.chr${i}.txt; done

#now obtain files listing the variants and their corresponding genes, ordered by chromosomal position
for i in {1..22}; do awk '{ print $4, $1 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.annot.chr${i}.txt | sort -k 2 | uniq > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.long.chr${i}.txt; done
for i in {1..22}; do awk '{ print $2 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.long.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.variants.chr${i}.txt; done

#now use bcftools to view only those variants and obtain each sample's genotype
for i in {1..22}; do bcftools view -i "%ID=@/scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.variants.chr${i}.txt" /scratch/richards/guillaume.butler-laporte/WGS/splitChrom/allSamples.chr${i}.Eur.normID.rehead.GTflt.AB.noChrXYM.vqsr.flt.vcf.gz -Ou | bcftools filter -i 'INFO/MAF<=0.01' -Ou | bcftools query -f '%ID [ %GT] \n' > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/M1.GT.chr${i}.txt; done

#now use R to build the genotype
Rscript /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/finalScripts/M1.GT.R
for i in {1..22}; do cat /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/VCF.sct.regenie/headerStep1.txt /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/M1.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/M1.chr${i}.vcf; done

#now use plink to build 
for i in {1..22}; do plink --vcf /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/M1.chr${i}.vcf --make-bed --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/M1.chr${i}; done

#get a list of those plink files
find /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/ -name "*.bim" | grep -e "Pruned" > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/ForMerge.list ;

sed -i 's/.bim//g' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/ForMerge.list ;

#merge all files in one
plink --merge-list /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/ForMerge.list --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M1/finalMask/MergeM1 ;



####### M2, again note the max AF issue #########
#first filter for the correct variants
for i in {1..22}; do awk '(/LoF=HC/ || /missense_variant/) && /CANONICAL=YES/ && !/MAX_AF=0.[0-9][1-9]*;/' /scratch/richards/guillaume.butler-laporte/WGS/annotation/finalAnnot.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.annot.chr${i}.txt; done

#now obtain files listing the variants and their corresponding genes, ordered by chromosomal position
for i in {1..22}; do awk '{ print $4, $1 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.annot.chr${i}.txt | sort -k 2 | uniq > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.long.chr${i}.txt; done
for i in {1..22}; do awk '{ print $2 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.long.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.variants.chr${i}.txt; done

#now use bcftools to view only those variants and obtain each sample's genotype
for i in {1..22}; do bcftools view -i "%ID=@/scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.variants.chr${i}.txt" /scratch/richards/guillaume.butler-laporte/WGS/splitChrom/allSamples.chr${i}.Eur.normID.rehead.GTflt.AB.noChrXYM.vqsr.flt.vcf.gz -Ou | bcftools filter -i 'INFO/MAF<=0.01' -Ou | bcftools query -f '%ID [ %GT] \n' > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/M2.GT.chr${i}.txt; done

#now use R to build the genotype
Rscript /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/finalScripts/M2.GT.R
for i in {1..22}; do cat /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/VCF.sct.regenie/headerStep1.txt /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/M2.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/M2.chr${i}.vcf; done

#now use plink to build 
for i in {1..22}; do plink --vcf /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/M2.chr${i}.vcf --make-bed --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/M2.chr${i}; done

#get a list of those plink files
find /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/ -name "*.bim" | grep -e "Pruned" > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/ForMerge.list ;

sed -i 's/.bim//g' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/ForMerge.list ;

#merge all files in one
plink --merge-list /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/ForMerge.list --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M2/finalMask/MergeM2 ;



####### M3, again note the max AF issue #########
#first filter for the correct variants
for i in {1..22}; do awk '(/loF=HC/ || (/missense_variant/ && /SIFT_pred=[,DT]*D/ && /Polyphen2_HVAR_pred=[,DPB]*D[,DPB]*;/ && /Polyphen2_HDIV_pred=[,DPB]*D[,DPB]*;/ && (/MutationTaster_pred=[,ADNP]*D[,ADNP]*;/ || /MutationTaster_pred=[,ADNP]*A[,ADNP]*;/) && /LRT_pred=[;DNU]*D[;DNU]*;/)) && /CANONICAL=YES/ && !/MAX_AF=0.[0-9][1-9]*;/' /scratch/richards/guillaume.butler-laporte/WGS/annotation/finalAnnot.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.annot.chr${i}.txt; done

#now obtain files listing the variants and their corresponding genes, ordered by chromosomal position
for i in {1..22}; do awk '{ print $4, $1 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.annot.chr${i}.txt | sort -k 2 | uniq > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.long.chr${i}.txt; done
for i in {1..22}; do awk '{ print $2 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.long.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.variants.chr${i}.txt; done

#now use bcftools to view only those variants and obtain each sample's genotype
for i in {1..22}; do bcftools view -i "%ID=@/scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.variants.chr${i}.txt" /scratch/richards/guillaume.butler-laporte/WGS/splitChrom/allSamples.chr${i}.Eur.normID.rehead.GTflt.AB.noChrXYM.vqsr.flt.vcf.gz -Ou | bcftools filter -i 'INFO/MAF<=0.01' -Ou | bcftools query -f '%ID [ %GT] \n' > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/M3.GT.chr${i}.txt; done

#now use R to build the genotype
Rscript /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/finalScripts/M3.GT.R
for i in {1..22}; do cat /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/VCF.sct.regenie/headerStep1.txt /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/M3.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/M3.chr${i}.vcf; done

#now use plink to build 
for i in {1..22}; do plink --vcf /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/M3.chr${i}.vcf --make-bed --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/M3.chr${i}; done

#get a list of those plink files
find /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/ -name "*.bim" | grep -e "Pruned" > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/ForMerge.list ;

sed -i 's/.bim//g' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/ForMerge.list ;

#merge all files in one
plink --merge-list /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/ForMerge.list --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M3/finalMask/MergeM3 ;



####### M4, again note the max AF issue #########
#first filter for the correct variants
for i in {1..22}; do awk '(/loF=HC/ || (/missense_variant/ && (/SIFT_pred=[,DT]*D/ || /Polyphen2_HVAR_pred=[,DPB]*D[,DPB]*;/ || /Polyphen2_HDIV_pred=[,DPB]*D[,DPB]*;/ || /MutationTaster_pred=[,ADNP]*D[,ADNP]*;/ || /MutationTaster_pred=[,ADNP]*A[,ADNP]*;/ || /LRT_pred=[;DNU]*D[;DNU]*;/))) && /CANONICAL=YES/ && !/MAX_AF=0.[0-9][1-9]*;/' /scratch/richards/guillaume.butler-laporte/WGS/annotation/finalAnnot.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.annot.chr${i}.txt; done

#now obtain files listing the variants and their corresponding genes, ordered by chromosomal position
for i in {1..22}; do awk '{ print $4, $1 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.annot.chr${i}.txt | sort -k 2 | uniq > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.long.chr${i}.txt; done
for i in {1..22}; do awk '{ print $2 }' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.long.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.variants.chr${i}.txt; done

#now use bcftools to view only those variants and obtain each sample's genotype
for i in {1..22}; do bcftools view -i "%ID=@/scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.variants.chr${i}.txt" /scratch/richards/guillaume.butler-laporte/WGS/splitChrom/allSamples.chr${i}.Eur.normID.rehead.GTflt.AB.noChrXYM.vqsr.flt.vcf.gz -Ou | bcftools filter -i 'INFO/MAF<=0.01' -Ou | bcftools query -f '%ID [ %GT] \n' > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/M4.GT.chr${i}.txt; done

#now use R to build the genotype
Rscript /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/finalScripts/M4.GT.R
for i in {1..22}; do cat /project/richards/guillaume.butler-laporte/WGS/bqc.individual.wgs.20200908/VCF.sct.regenie/headerStep1.txt /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/M4.chr${i}.txt > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/M4.chr${i}.vcf; done

#now use plink to build 
for i in {1..22}; do plink --vcf /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/M4.chr${i}.vcf --make-bed --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/M4.chr${i}; done

#get a list of those plink files
find /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/ -name "*.bim" | grep -e "Pruned" > /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/ForMerge.list ;

sed -i 's/.bim//g' /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/ForMerge.list ;

#merge all files in one
plink --merge-list /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/ForMerge.list --out /scratch/richards/guillaume.butler-laporte/WGS/Masks/M4/finalMask/MergeM4 ;

