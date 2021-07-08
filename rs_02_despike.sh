#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
projDir=/group/agreenb/iPadStudy/keith
sbj=$1
day=$2
sbjDir=$projDir/data/$sbj/$day/rs/preproc
cd $sbjDir

# This one can be paralelized. See despike help.
# Removes 'spikes' from the dataset
echo "Running despike in ${sbj}_${day}..."

# Apply 3dDespike to each run
3dDespike -overwrite -prefix pb01.$sbj.r01.despike.orig.nii.gz -nomask -NEW pb00.$sbj.r01.tcat.nii.gz

# Make sure output has no negative values
fslmaths pb01.$sbj.r01.despike.orig.nii.gz -thr 0 pb01.$sbj.r01.despike.orig.nii.gz

echo "DONE despike"
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