#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
day=$2
sbjDir=/group/agreenb/iPadStudy/keith/data/$sbj/$day
roiDir=$sbjDir/anat
anat=$roiDir/brain.nii.gz
outDir=$sbjDir/rs/preproc

echo "Aligning anatomical with rs in ${sbj}..."
flirt -in $anat -ref $outDir/vr_base_min_outlier.nii.gz -out $outDir/brain_al.nii.gz -omat $outDir/brain_al.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear

# Apply transformation to brain
flirt -in $anat -applyxfm -init $outDir/brain_al.mat -out $outDir/brain_al.nii.gz -paddingsize 0.0 -interp trilinear -ref $outDir/vr_base_min_outlier.nii.gz

# Apply transformation to the aseg file
fslreorient2std $roiDir/aseg.nii.gz $roiDir/aseg.nii.gz
flirt -in $roiDir/aseg.nii.gz -applyxfm -init $outDir/brain_al.mat -out $outDir/aseg_al.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref $outDir/vr_base_min_outlier.nii.gz

# Apply transformation to ROI files
flirt -in $roiDir/DistFilt_${sbj}_lh_${day}_VOL.orig.nii.gz -applyxfm -init $outDir/brain_al.mat -out $outDir/DistFilt_${sbj}_lh_VOL.orig.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref $outDir/vr_base_min_outlier.nii.gz
flirt -in $roiDir/DistFilt_${sbj}_rh_${day}_VOL.orig.nii.gz -applyxfm -init $outDir/brain_al.mat -out $outDir/DistFilt_${sbj}_rh_VOL.orig.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref $outDir/vr_base_min_outlier.nii.gz

echo "DONE align"
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
