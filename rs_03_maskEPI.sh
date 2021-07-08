#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
projDir=/group/agreenb/iPadStudy/keith
sbj=$1
day=$2
outDir=$projDir/data/$sbj/$day/rs/preproc

echo "Masking despiked data in ${sbj}_${day}..."
bet $outDir/pb01.$sbj.r01.despike.orig.nii.gz $outDir/pb02.$sbj.r01.fslbet -F -f 0.1 -g 0 -n -m
rm $outDir/pb02.$sbj.r01.fslbet.nii.gz

echo "DONE maskEPI"
# Compute execution time
FINISHTIME=$(date +%s)
TOTDURATION_S=$((FINISHTIME - STARTTIME))
DURATION_H=$((TOTDURATION_S / 3600))
REMAINDER_S=$((TOTDURATION_S - (3600*DURATION_H)))
DURATION_M=$((REMAINDER_S / 60))
DURATION_S=$((REMAINDER_S - (60*DURATION_M)))
DUR_H=$(printf "%02d" ${DURATION_H})
DUR_M=$(printf "%02d" ${DURATION_M})
DUR_S=$(printf "%02d" ${DURATION_S})
echo "Total execution time was ${DUR_H} hrs ${DUR_M} mins ${DUR_S} secs"