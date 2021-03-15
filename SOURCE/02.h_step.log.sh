#! /bin/bash

umask 006

bcftools stats $VCF > $LOG2
