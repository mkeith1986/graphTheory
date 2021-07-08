#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Variables
sbj=$1
day=$2
cd /group/agreenb/iPadStudy/keith/data/$sbj/$day/rs/preproc

echo "Performing tissue based segmentation on ${sbj}..."
# Segment WM and CSF from Freesurfer
# WM values: 2, 7, 41, 46
# CSF values (ventricles): 4, 14, 15, 43, 72
3dcalc -overwrite -a aseg_al.nii.gz -exp 'or(a*(1-bool(a-2)),a*(1-bool(a-7)),a*(1-bool(a-41)),a*(1-bool(a-46)))' -prefix wm.nii.gz
3dcalc -overwrite -a aseg_al.nii.gz -exp 'or(a*(1-bool(a-4)),a*(1-bool(a-14)),a*(1-bool(a-15)),a*(1-bool(a-43)),a*(1-bool(a-72)))' -prefix csf.nii.gz

# Mask the segmentations to make sure they dont get out of the brain
3dcalc -overwrite -a brain_al.nii.gz -expr 'bool(a)' -prefix brain_mask.nii.gz
3dcalc -overwrite -a wm.nii.gz -b brain_mask.nii.gz -expr 'bool(a)*bool(b)' -prefix wm.nii.gz        
3dcalc -overwrite -a csf.nii.gz -b brain_mask.nii.gz -expr 'bool(a)*bool(b)' -prefix csf.nii.gz

# Dilatate the WM mask to make sure we're not including WM in the correlations
3dmask_tool -input wm.nii.gz -dilate_input 1 -overwrite -prefix wm_dil.nii.gz
for h in lh rh
do
	roi=DistFilt_${sbj}_${h}_VOL
	
	# Remove the WM from the ROI
        3dcalc -a $roi.orig.nii.gz -b wm_dil.nii.gz -expr 'a*not(b)' -overwrite -prefix ${roi}_masked.nii.gz

	# Separate the ROI in different files
	rm -f tmp_${sbj}_${h}.txt $roi.txt
	3dmaskdump -overwrite -noijk -nozero -quiet -o tmp_${sbj}_${h}.txt ${roi}_masked.nii.gz
	cat tmp_${sbj}_${h}.txt | sort -nu > $roi.txt
	rm tmp_${sbj}_${h}.txt
	for val in $(cat $roi.txt)
	do
		fslmaths ${roi}_masked.nii.gz -thr $val -uthr $val ${sbj}_${h}_${val}.nii.gz
	done
done

echo "DONE segm"
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
