#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
sbjDir=/group/agreenb/iPadStudy/keith/data/$sbj/day1/dsi

echo "Extracting brain on ${sbj}..."
# use bet
bet $sbjDir/${sbj}_day1_DWI $sbjDir/bet -f 0.5 -g 0 -n -m
echo "bet done"

# use 3dSkullStrip
3dSkullStrip -overwrite -input $sbjDir/${sbj}_day1_DWI.nii.gz -prefix $sbjDir/skullstrip.nii.gz -push_to_edge
echo "3dSkullStrip done"

echo "DONE brain_extraction"
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
