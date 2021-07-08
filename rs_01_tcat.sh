#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
day=$2
sbjDir=/group/agreenb/iPadStudy/keith/data/$sbj/$day
rawEPI=$sbjDir/rs/${sbj}_${day}_EPI.nii.gz
outDir=$sbjDir/rs/preproc
mkdir -p $outDir
echo "Running tcat in ${sbj}..."

# Remove the first 3 TRs: images at the beginning of a high speed fMRI imaging run are usually of different quality than the later images, due to transient effects before longitudinal magnetization settles into a steady-state value.
3dTcat -overwrite -prefix $outDir/pb00.$sbj.r01.tcat.nii.gz ${rawEPI}'[3..$]'

# Make note of repetitions (TRs) per run
tr_orig=$(fslsize $rawEPI | grep dim4 | head -n1 | awk '{print $2}')
tr_counts=$(( $tr_orig - 3 ))
rm -f $outDir/tr_counts.txt
echo $tr_counts >> $outDir/tr_counts.txt

echo "DONE tcat"
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

