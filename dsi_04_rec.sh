#!/bin/bash
#SBATCH --job-name="reconstruction"
#SBATCH --time=1:00:00
#SBATCH --account=jbinder
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)
module load dsistudio

projDir=/scratch/u/mkeith/iPadStudy
cd $projDir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}
cd ${sbj}_day1

echo "Running reconstruction on ${sbj}..."
# method==4 GQI
# param0 Sampling length ratio
# odf_order: ODF Tessellation 6-fold, which results in 362 discrete sampling directions
# num_fiber: maximum count of resolving fibers
# Enable scheme balance
# CSF calibration enabled
dsi_studio --action=rec --source=${sbj}_day1_DWI.nii.gz.src.gz --method=4 --param0=1.25 --mask=nodif_brain_mask.nii.gz --odf_order=6 --num_fiber=5 --scheme_balance=1 --csf_calibration=1

echo "DONE reconstruction"
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
