#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
day=$2
cd /group/agreenb/iPadStudy/keith/data/$sbj/$day/rs/preproc

# Shifts the voxel time series from the input dataset so that the separate slices are aligned to the same temporal origin. Align slices to the beginning of the TR.
echo "Running tshift in ${sbj}_${day}..."
# Compute the polort number
# N: Number of time points in the data
rm -f polort.txt
N=$(fslval pb02.$sbj.r01.masked.nii.gz dim4); N=${N/ /}
TR=$(fslval pb02.$sbj.r01.masked.nii.gz pixdim4); TR=${TR/ /}
VAR=$(echo "( ${N} * ${TR} ) / 150" | bc -l); VAR=$(echo $VAR | awk '{print int($1)}')
POL=$(( 1 + $VAR ))
echo "**** USING POLORT ${POL} ****"
echo $POL >> polort.txt

# Compute outlier fraction for each volume
rm -f outcount.r01.1D
3dToutcount -mask pb02.$sbj.r01.fslbet_mask.nii.gz -fraction -polort ${POL} -legendre pb02.$sbj.r01.masked.nii.gz > outcount.r01.1D
        
# Censor outlier TRs per run
# Censor when more than 0.05 voxels are outliers
# step() defines which TRs to remove via censoring
# If there is more than one run, all rm.out.cen.r01.1D should be concatenated into outcount_${sbj}_censor.1D
rm -f rm.out.cen.r01.1D
1deval -a outcount.r01.1D -expr "1-step(a-0.05)" > rm.out.cen.r01.1D

# Outliers at TR 0 might suggest pre-steady state TRs
VAR=$(1deval -a outcount.r01.1D"{0}" -expr "step(a-0.4)")
[ $VAR -eq 1 ] && echo "** TR #0 outliers: possible pre-steady state TRs in run 01" && exit 1

# Get run number and TR index for minimum outlier volume
minindex=$(3dTstat -argmin -prefix - outcount.r01.1D\')
tr_counts=$(cat tr_counts.txt)
ovals=$(1d_tool.py -set_run_lengths $tr_counts -index_to_run_tr $minindex)
        
# Save run and TR indices for extraction of vr_base_min_outlier
IFS=' ' read -a ARRAY <<< "$ovals"
minoutrun=${ARRAY[0]}
minouttr=${ARRAY[1]}
rm -f out.min_outlier.txt
echo "min outlier: run $minoutrun, TR $minouttr" | tee out.min_outlier.txt

# Do Slice-timing correction
3dTshift -overwrite -tzero 0 -quintic -prefix pb03.$sbj.r01.tshift.nii.gz pb02.$sbj.r01.masked.nii.gz

# Extract volreg registration base
3dbucket -overwrite -prefix vr_base_min_outlier.nii.gz pb03.$sbj.r$minoutrun.tshift.nii.gz"[$minouttr]"

# Catenate outlier counts into a single time series
# Since there's only one run, it's just renaming to keep naming convention
rm -f outcount_rall.1D
cat outcount.r*.1D > outcount_rall.1D

# Catenate outlier censor files into a single time series
# Since there's only one run, it's just renaming to keep naming convention
rm -f outcount_${sbj}_censor.1D
cat rm.out.cen.r*.1D > outcount_${sbj}_censor.1D

echo "DONE tshift"
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
