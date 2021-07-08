#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
day=$2
cd /group/agreenb/iPadStudy/keith/data/$sbj/$day/rs/preproc

echo "Running motion correction in ${sbj}_${day}..."
# Register each volume to the base image
# -1Dfile ename: motion parameters. The output is in 6 ASCII formatted columns: roll pitch yaw dS  dL  dP
# -1Dmatrix_save ff: matrix transformation from base to input coordinates in file 'ff' (1 row per sub-brick in the input dataset). To get the inverse matrix (input to base), use the cat_matvec program, as in cat_matvec fred.aff12.1D -I. This matrix is the inverse of the matrix stored in the output dataset VOLREG_MATVEC_* attributes
rm -f dfile.r01.1D
3dvolreg -overwrite -verbose -zpad 1 -base vr_base_min_outlier.nii.gz -1Dfile dfile.r01.1D -prefix pb04.$sbj.r01.volreg.nii.gz -cubic -1Dmatrix_save mat.r01.vr.aff12.1D pb03.$sbj.r01.tshift.nii.gz
[ ! -f pb04.$sbj.r01.volreg.nii.gz ] && echo "ERROR: volreg file not generated" && exit 1

# Apply the mask to the EPI data to delete any time series with missing data
3dcalc -overwrite -a pb04.$sbj.r01.volreg.nii.gz -b pb02.$sbj.r01.fslbet_mask.nii.gz -expr 'a*b' -prefix pb04.$sbj.r01.volreg.nii.gz

# Re-name file with registration parameters to follow naming convention
# In the case of multiple runs the result will be the concatenation
rm -f dfile_rall.1D
cat dfile.r*.1D > dfile_rall.1D

# Compute motion magnitude time series: the Euclidean norm
# (sqrt(sum squares)) of the motion parameter derivatives
1d_tool.py -overwrite -infile dfile_rall.1D -set_nruns 1 -derivative -collapse_cols euclidean_norm -write motion_${sbj}_enorm.1D
[ ! -f motion_${sbj}_enorm.1D ] && echo "ERROR: motion enorm file not generated" && exit 1

# Create censor file motion_${sbj}_censor.1D for censoring motion
# If more than one run, the input would be dfile_rall.1D instead
# Using 1.5 as limit because it's slightly less than than the voxel size (1.6)
rm -f motion_${sbj}*
1d_tool.py -overwrite -infile dfile.r01.1D -set_nruns 1 -show_censor_count -censor_prev_TR -censor_motion 1.5 motion_${sbj}
[ ! -f motion_${sbj}_censor.1D ] && echo "ERROR: motion censor file not generated" && exit 1

# Compute de-meaned motion parameters for use in regression
# If more than one run, the input would be dfile_rall.1D instead
1d_tool.py -overwrite -infile dfile.r01.1D -set_nruns 1 -demean -write motion_demean.1D
[ ! -f motion_demean.1D ] && echo "ERROR: motion demean file not generated" && exit 1

# Compute motion parameters derivatives for use in regression
# If more than one run, the input would be dfile_rall.1D instead
1d_tool.py -overwrite -infile dfile.r01.1D -set_nruns 1 -derivative -demean -write motion_deriv.1D
[ ! -f motion_deriv.1D ] && echo "ERROR: motion deriv file not generated" && exit 1

# Combine multiple censor files
rm -f censor_${sbj}_combined_2.1D
1deval -a motion_${sbj}_censor.1D -b outcount_${sbj}_censor.1D -expr 'a*b' > censor_${sbj}_combined_2.1D
[ ! -f censor_${sbj}_combined_2.1D ] && echo "ERROR: combined censor file not generated" && exit 1 

echo "DONE volreg"
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