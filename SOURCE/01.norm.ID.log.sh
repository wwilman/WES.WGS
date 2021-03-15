#! /bin/bash

umask 006

bcftools stats $ORGVCF > $LOG1
bcftools stats $OUTVCF > $LOG2
