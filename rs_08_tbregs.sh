#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
day=$2
cd /group/agreenb/iPadStudy/keith/data/$sbj/$day/rs/preproc
echo "Getting the tissue based regressors for ${sbj}..."

# Extract average time series from WM and CSF
# It has to be done in the data BEFORE blurring
rm -f $sbj.r01.wm_timeCourse.1D $sbj.r01.csf_timeCourse.1D
3dmaskave -quiet -mask wm.nii.gz pb04.$sbj.r01.volreg.nii.gz > $sbj.r01.wm_timeCourse.1D
3dmaskave -quiet -mask csf.nii.gz pb04.$sbj.r01.volreg.nii.gz > $sbj.r01.csf_timeCourse.1D

# Take the temporal derivative of the previous vectors (time courses of WM and CSF)
# This is the first backward difference
# value[0] = 0
# For the others: value[index]=value[index]-value[index-1]
rm -f $sbj.r01.wm_timeCourse_deriv.1D $sbj.r01.csf_timeCourse_deriv.1D
1d_tool.py -overwrite -infile $sbj.r01.wm_timeCourse.1D -set_nruns 1 -derivative -demean -write $sbj.r01.wm_timeCourse_deriv.1D
1d_tool.py -overwrite -infile $sbj.r01.csf_timeCourse.1D -set_nruns 1 -derivative -demean -write $sbj.r01.csf_timeCourse_deriv.1D

echo "DONE tbregs"
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
