#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library(randomForest)

dirout = args[1]
dirdownloads = args[2]

# read in the eigenvectors, produced in PLINK
setwd(dirout)
eigenvec <- read.table('plink.eigenvec', header = FALSE, skip=0, sep = ' ')
eigenvec <- eigenvec[,2:ncol(eigenvec)]
colnames(eigenvec) <- c("Individual.ID",paste('PC', c(1:20), sep = ''))

# read in the PED data
setwd(dirdownloads)

PED <- read.table('20130606_g1k.ped', header = TRUE, skip = 0, sep = '\t')

#build data frame for random forest classifier
dataRF <- merge(eigenvec, PED[, c("Individual.ID", "Population")], all.x=TRUE)

#build plot
dataRF$Population <- factor(dataRF$Population, levels=c(
  "ACB","ASW","ESN","GWD","LWK","MSL","YRI",
  "CLM","MXL","PEL","PUR",
  "CDX","CHB","CHS","JPT","KHV",
  "CEU","FIN","GBR","IBS","TSI",
  "BEB","GIH","ITU","PJL","STU"))

dataRF$Continental <- rep(NA_character_, nrow(dataRF))
dataRF$Continental[which(dataRF$Population %in% c("ACB","ASW","ESN","GWD","LWK","MSL","YRI"))]<-"AFR"
dataRF$Continental[which(dataRF$Population %in% c("CLM","MXL","PEL","PUR"))]<-"AMR"
dataRF$Continental[which(dataRF$Population %in% c("CDX","CHB","CHS","JPT","KHV"))]<-"EAS"
dataRF$Continental[which(dataRF$Population %in% c("CEU","FIN","GBR","IBS","TSI"))]<-"EUR"
dataRF$Continental[which(dataRF$Population %in% c("BEB","GIH","ITU","PJL","STU"))]<-"SAS"
dataRF$Continental<-as.factor(dataRF$Continental)

setwd(dirout)
jpeg(filename = "03.ancestryPCA.jpeg", width = 1024, height = 1024, quality = 100, bg = "white")
  
  col <- colorRampPalette(c(
    "yellow","forestgreen","grey","royalblue","black"))(length(unique(dataRF$Continental)))[factor(dataRF$Continental)]


  #PCA plots, to see if you get ok results, you should see clusters.
  par(mar = c(5,5,5,5), cex = 1.25,
      cex.main = 2, cex.axis = 1.25, cex.lab = 1.25, mfrow = c(1,2))

  plot(dataRF[,2], dataRF[,3],
    type = 'n',
    main = 'A',
    adj = 0.5,
    xlab = 'First component',
    ylab = 'Second component',
    font = 2,
    font.lab = 2)
  points(dataRF[,2], dataRF[,3], col = col, pch = 20, cex = 1.25)
  legend('bottomright',
    bty = 'n',
    cex = 1.0,
    title = '',
    c('Population 1', 'Population 2', 'Population 3',
      'Population 4', 'Population 5'),
    fill = c('yellow', 'forestgreen', 'grey', 'royalblue', 'black'))

  plot(dataRF[,2], dataRF[,4],
    type="n",
    main="B",
    adj=0.5,
    xlab="First component",
    ylab="Third component",
    font=2,
    font.lab=2)
  points(dataRF[,2], dataRF[,4], col=col, pch=20, cex=1.25)
dev.off()


#random forest
rf_classifier = randomForest(Continental ~ ., data=dataRF[which(!is.na(dataRF$Continental)),c("PC1","PC2","PC3","PC4","PC5","PC6", "Continental")], ntree=10000, importance=TRUE)

#predict ancestries
dataPred<-dataRF[which(is.na(dataRF$Continental)),c("Individual.ID", "PC1", "PC2", "PC3","PC4","PC5","PC6")]
dataPred$Prediction<-rep(NA, nrow(dataPred))
dataPred$Prediction<-predict(rf_classifier,dataPred[,c("PC1","PC2","PC3","PC4","PC5","PC6")])


#if you want to see the results, here I provide an example with AFR ancestry
#from here, if the population is very admixted, other algorithms can be applied, or at least visual inspection can be done to remove clear outliers.
#the blank dots should cluster with the yellow dots (for AFR)
#setwd(dirout)
#jpeg(filename = "03.ancestryPCA_EUR.jpeg", width = 1024, height = 1024, quality = 100, bg = "white")
#dataEur<-dataPred %in% filter(Prediction=="EUR")
#plot(dataRF[,2], dataRF[,3],
#     type = 'n',
#     main = 'A',
#     adj = 0.5,
#     xlab = 'First component',
#     ylab = 'Second component',
#     font = 2,
#     font.lab = 2)
#points(dataRF[,2], dataRF[,3], col = col, pch = 20, cex = 1.25)
#points(dataEur[,2], dataEur[,3])
#plot(dataRF[,2], dataRF[,4],
#     type="n",
#     main="B",
#     adj=0.5,
#     xlab="First component",
#     ylab="Third component",
#     font=2,
#     font.lab=2)
#points(dataRF[,2], dataRF[,4], col=col, pch=20, cex=1.25)
#points(dataEur[,2], dataEur[,4])
#dev.off()


#write IDs per ancestry
write(as.character(subset(dataPred, Prediction=="AFR")$Individual.ID), "afrIDsPCA.txt")
write(as.character(subset(dataPred, Prediction=="AMR")$Individual.ID), "amrIDsPCA.txt")
write(as.character(subset(dataPred, Prediction=="EAS")$Individual.ID), "easIDsPCA.txt")
write(as.character(subset(dataPred, Prediction=="EUR")$Individual.ID), "eurIDsPCA.txt")
write(as.character(subset(dataPred, Prediction=="SAS")$Individual.ID), "sasIDsPCA.txt")

q()