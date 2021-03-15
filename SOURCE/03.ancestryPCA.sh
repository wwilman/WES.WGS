#! /bin/bash

#this may take some time to run in its entirety

#based on this https://www.biostars.org/p/335605/
#requires plink 1.9 and bcftools >1.3

#the idea here is as follows:
#1) obtain the 1000G reference files (in GRCh38 always, only SNPs, and autosomal chromosomes), normalize and left-align them with the reference genome
#2) from this file, only use the variants also found in your specific cohort, and further prune them to MAF over 10% and in linkage equilibrium
#3) from your cohort variant file, only select those pruned variants from step 2
#4) merge the 1000G file and you cohort's file, with only those pruned variants
#5) perform PCA on 1000G using this variant set, and project your cohort's genotype on the resulting PCs
#6) train a random forest with 6 principal components on the 1000G dataset
#7) predict the ancestry in your cohort using that trained random forest and your cohort's projection on 1000G's PCs
#8) output files named like "afrIDsPCA.txt", for the study IDs of individuals predicted to be of a certain ancestry (here african, for example).


# download the GRCh38 1000G data, if not done already

#prefix="http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20181203_biallelic_SNV/ALL.chr"
#suffix=".shapeit2_integrated_v1a.GRCh38.20181129.phased.vcf.gz"

#for chr in {1..22}; do
#  wget "$prefix""$chr""$suffix" "$prefix""$chr""$suffix".tbi
#done

#now will need to download ancestry information from the 1000G
#wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/working/20130606_sample_info/20130606_g1k.ped

#download reference genome fasta file (GRCh38)
#wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
#gzip -d GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz


#convert 1000G vcf to bcf, normalizing and left-aligning variants
#for chr in {1..22}; do
#    bcftools norm -m-any --check-ref w -f $INFASTA \
#    $DIRDOWNLOADS/ALL.chr"${chr}""$SUFFIX".vcf.gz | \
#    bcftools annotate -x ID -I +'%CHROM:%POS:%REF:%ALT' | \
#     bcftools norm -Ob --rm-dup both  \
#         > $DIRDOWNLOADS/ALL.chr"${chr}""$SUFFIX".bcf ;
#
#    bcftools index -f $DIRDOWNLOADS/ALL.chr"${chr}""$SUFFIX".bcf ;
#done


#convert bcf to plink format
#for chr in {1..22}; do
#    plink --noweb \
#      --bcf $DIRDOWNLOADS/ALL.chr"${chr}""$SUFFIX".bcf \
#      --keep-allele-order \
#      --vcf-idspace-to _ \
#      --allow-extra-chr 0 \
#      --split-x b38 no-fail \
#      --make-bed \
#      --out $DIRDOWNLOADS/ALL.chr"${chr}"$SUFFIX ;
#done


#Obtain the list of variants for ancestry inference PCA
for chr in {1..22}; do
  bcftools filter -r chr${chr} $INHAIL -Ou | \
  bcftools query -f "%ID\n" > $DIRVARIANTS/variants.chr${chr}.txt;
done


#prune for common variants in linkage equilibrium, and only keeping variants also in your cohort
for chr in {1..22}; do
    plink --noweb \
      --bfile $DIRDOWNLOADS/ALL.chr"${chr}"$SUFFIX \
      --extract $DIRVARIANTS/variants.chr"${chr}".txt \
      --maf 0.10 --indep 50 5 1.5 \
      --out $DIRPRUNED/ALL.chr"${chr}"$SUFFIX ;

    plink --noweb \
      --bfile $DIRDOWNLOADS/ALL.chr"${chr}"$SUFFIX \
      --extract $DIRPRUNED/ALL.chr"${chr}""$SUFFIX".prune.in \
      --make-bed \
      --out $DIRPRUNED/ALL.chr"${chr}"$SUFFIX ;
done


#get a list of plink files
find $DIRPRUNED/ -name "*.bim" > $DIROUT/ForMerge.list


sed -i 's/.bim//g' $DIROUT/ForMerge.list ;


#merge all biles in one
plink --merge-list $DIROUT/ForMerge.list --out $DIROUT/Merge ;


#make plink file from the full all sample VCF from your cohort, only keeping the pruned variants, then merge with the 1000G plink files
awk '{ print $2 }' $DIROUT/Merge.bim > $DIROUT/MergeVariants.txt

plink --vcf $INHAIL \
 --noweb \
 --double-id \
 --extract $DIROUT/MergeVariants.txt \
 --make-bed \
 --out $DIRCOHORT/cohortSample

printf "$DIROUT/Merge\n$DIRCOHORT/cohortSample" > $DIROUT/ForMergeFull.list

plink --merge-list $DIROUT/ForMergeFull.list --out $DIROUT/MergeFullForPCA ;

if [ -f $DIROUT/MergeFullForPCA.missnp ]; then
 plink --bfile $DIROUT/Merge --exclude $DIROUT/MergeFullForPCA.missnp --make-bed --out $DIROUT/Merge ;
 plink --bfile $DIRCOHORT/cohortSample --exclude $DIROUT/MergeFullForPCA.missnp --make-bed --out $DIRCOHORT/cohortSample ;
 plink --merge-list $DIROUT/ForMergeFull.list --out $DIROUT/MergeFullForPCA ;  
 rm $DIROUT/*~
 rm $DIRCOHORT/*~
fi


#now divide between 1000G and cohort samples
awk '{ print $1,$2 }' $DIROUT/Merge.fam | awk '$(NF+1) = "1000G"' > $DIROUT/1000G.cluster.txt
awk '{ print $1,$2 }' $DIRCOHORT/cohortSample.fam | awk '$(NF+1) = "Cohort"' > $DIRCOHORT/cohort.cluster.txt
cat $DIROUT/1000G.cluster.txt $DIRCOHORT/cohort.cluster.txt > $DIROUT/clusters.txt


#now do PCA on 1000G dataset, and project the cohort genotype on these PCs
plink --bfile $DIROUT/MergeFullForPCA \
 --pca-cluster-names 1000G \
 --pca \
 --within $DIROUT/clusters.txt

mv $DIRJOBS/plink* $DIROUT/