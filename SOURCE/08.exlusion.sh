#! /bin/bash

for chr in {1..22} X; do
  zcat $DIROUT/$PREFIX.chr"${chr}"$SUFFIX | sed '/^#/d' | awk '{print $3}' | uniq -d > $DIROUT/excluded.chr"${chr}".txt
done

cat $DIROUT/excluded.chr* >> $DIROUT/excluded.all.txt

