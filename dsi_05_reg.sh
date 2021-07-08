#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
projDir=/group/agreenb/iPadStudy/keith
sbj=$1
sbjDir=$projDir/data/$sbj/day1
dwiDir=$sbjDir/dsi
anatDir=$sbjDir/anat
outDir=$sbjDir/transforms
rm -rf $outDir
mkdir $outDir
cd $outDir

echo "Registering subject ${sbj}..."
flirt -in $anatDir/brain.nii.gz -ref $dwiDir/nodif_brain.nii.gz -out anat2diff_fsl.nii.gz -omat anat2diff_fsl.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear
echo "DONE reg"

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
