#!/bin/bash
set -e
STARTTIME=$(date +%s)

sbj=$1
day=$2

echo "Performing nuisance regression and bandpass filtering in ${sbj}_${day}..."
cd /group/agreenb/iPadStudy/keith/data/$sbj/$day/rs/preproc

# Get polort
POL=$(cat polort.txt)

# Run 3dDeconvolve to calculate the regression matrix to regress out signals of no interest
# -censor: 317 lines (one per volume). line==1 if time point included, line==0 if not
# -ortvec: equivalent to one stim_file per column
# bandpass_rall.1D has one line per volume (317) and 230 columns. These regression columns will appear last in the matrix.
# -x1D_uncensored: this will be input in 3dTproject to generate the "clean" data
# -x1D_stop: suing 3dDeconvolve just to set up the matrix file so stop when that's done
# -x1D: censored matrix will be used after to check things
rm -f X.* errts.* stats.REML_cmd fitts.*
3dDeconvolve -input pb05.$sbj.r*.scale.nii.gz                           \
-censor censor_${sbj}_combined_2.1D                                     \
-ortvec bandpass_rall.1D bandpass                                       \
-polort $POL                                                            \
-num_stimts 12                                                          \
-stim_file 1 motion_demean.1D'[0]' -stim_base 1 -stim_label 1 roll_01   \
-stim_file 2 motion_demean.1D'[1]' -stim_base 2 -stim_label 2 pitch_01  \
-stim_file 3 motion_demean.1D'[2]' -stim_base 3 -stim_label 3 yaw_01    \
-stim_file 4 motion_demean.1D'[3]' -stim_base 4 -stim_label 4 dS_01     \
-stim_file 5 motion_demean.1D'[4]' -stim_base 5 -stim_label 5 dL_01     \
-stim_file 6 motion_demean.1D'[5]' -stim_base 6 -stim_label 6 dP_01     \
-stim_file 7 motion_deriv.1D'[0]' -stim_base 7 -stim_label 7 roll_02    \
-stim_file 8 motion_deriv.1D'[1]' -stim_base 8 -stim_label 8 pitch_02   \
-stim_file 9 motion_deriv.1D'[2]' -stim_base 9 -stim_label 9 yaw_02     \
-stim_file 10 motion_deriv.1D'[3]' -stim_base 10 -stim_label 10 dS_02   \
-stim_file 11 motion_deriv.1D'[4]' -stim_base 11 -stim_label 11 dL_02   \
-stim_file 12 motion_deriv.1D'[5]' -stim_base 12 -stim_label 12 dP_02   \
-fout -tout -x1D X.xmat.1D -xjpeg X.jpg                                 \
-x1D_uncensored X.nocensor.xmat.1D                                      \
-fitts fitts.$sbj                                                       \
-errts errts.$sbj                                                       \
-x1D_stop                                                               \
-bucket stats.$sbj

# Use 3dTproject to project out regression matrix and generate "clean" data
# -ort: matrix generated with 3dDeconvolve with regressors to regress out (signals of no interest)
# -cenmode KILL: removed censored volumes
# -prefix: should be the "clean" data
3dTproject -polort 0 -input pb05.$sbj.r01.scale.nii.gz -censor censor_${sbj}_combined_2.1D -cenmode KILL -ort X.nocensor.xmat.1D -prefix errts.${sbj}.tproject.nii.gz

# Display any large pairwise correlations from the X-matrix
rm -f out.cormat_warn.txt
1d_tool.py -show_cormat_warnings -infile X.xmat.1D |& tee out.cormat_warn.txt

# TRs that are not censored
ktrs=$(1d_tool.py -infile censor_${sbj}_combined_2.1D -show_trs_uncensored encoded)

# Create a temporal signal to noise ratio dataset
# signal: if 'scale' block, mean should be 100
# noise : compute standard deviation of errts
3dTstat -overwrite -mean -prefix rm.signal.all.nii.gz pb05.$sbj.r01.scale.nii.gz"[$ktrs]"
3dTstat -overwrite -stdev -prefix rm.noise.all.nii.gz pb05.$sbj.r01.scale.nii.gz"[$ktrs]"
3dcalc -overwrite -a rm.signal.all.nii.gz -b rm.noise.all.nii.gz -c pb02.$sbj.r01.fslbet_mask.nii.gz -expr 'c*a/b' -prefix TSNR.$sbj.orig.nii.gz
rm rm.signal.all* rm.noise.all*

# Extract time series
mkdir -p ts_mot
for hem in lh rh
do
	echo "Extracting the time series for hemisphere ${hem}..."
        for val in $(cat DistFilt_${sbj}_${hem}_VOL.txt)
        do
        	3dmaskave -mask ${sbj}_${hem}_${val}.nii.gz errts.${sbj}.tproject.nii.gz > ts_mot/tmp.txt
                cat ts_mot/tmp.txt | awk '{print $1}' > ts_mot/${hem}_${val}.txt
                rm ts_mot/tmp.txt
        done
done

echo "DONE nuissReg_mot"
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
