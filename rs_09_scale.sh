#!/bin/bash
set -e
STARTTIME=$(date +%s)

sbj=$1
day=$2
cd /group/agreenb/iPadStudy/keith/data/$sbj/$day/rs/preproc

echo "Performing scale step in ${sbj}_${day}..."
# Compute the mean of each voxel time series
# Normally would use the blurred file
# But because I'm not blurring in this project, here I use the volreg
3dTstat -overwrite -prefix mean_r01.nii.gz pb04.$sbj.r01.volreg.nii.gz

# Scale each voxel time series to have a mean of 100
3dcalc -overwrite -a pb04.$sbj.r01.volreg.nii.gz -b mean_r01.nii.gz -c pb02.$sbj.r01.fslbet_mask.nii.gz -expr 'c * min(200, a/b*100)*step(a)*step(b)' -prefix pb05.$sbj.r01.scale.nii.gz

rm -f bandpass_rall.1D
NV1=$(fslval pb05.$sbj.r01.scale.nii.gz dim4)
TR=$(fslval pb05.$sbj.r01.scale.nii.gz pixdim4)
1dBport -nodata $NV1 $TR -band 0.01 0.1 -invert -nozero > bandpass_rall.1D

echo "DONE scale"
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
