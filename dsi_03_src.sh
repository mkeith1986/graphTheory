#!/bin/bash
#SBATCH --job-name="create_src"
#SBATCH --time=1:00:00
#SBATCH --account=jbinder
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)

projDir=/scratch/u/mkeith/iPadStudy
cd $projDir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}
cd ${sbj}_day1
module load dsistudio

echo "Creating src file for ${sbj}..."
# up_sampling=0: no upsampling
dsi_studio --action=src --source=eddy_unwarped_images.nii.gz --bval=${sbj}_day1_DWI.bval --bvec=eddy_unwarped_images.eddy_rotated_bvecs --output=${sbj}_day1_DWI.nii.gz.src.gz --up_sampling=0
echo "DONE create_src"

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
