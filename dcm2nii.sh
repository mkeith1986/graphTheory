#!/bin/bash
set -e
STARTTIME=$(date +%s)

projDir=/group/agreenb/iPadStudy/keith
sbj=$1
day=$2
sbjDir=$projDir/data/$sbj/$day

echo "Running dcm2nii on ${sbj}_${day}..."
for img in DWI EPI MPRAGE
do
	echo "Converting ${img}..."
	img_folder=$data_folder/$sbj/$day/$img
	if [ -d $img_folder/DICOM ] && [ ! -d $img_folder/NIFTI ]
	then
		echo "Converting to nifti"
		mkdir $img_folder/NIFTI
		dcm2niix -w 2 -z y -o $img_folder/NIFTI $img_folder/DICOM
	fi

	new_name=$img_folder/NIFTI/${sbj}_${day}_${img}
	n=$(ls $img_folder/NIFTI/*.nii.gz | wc -l)
	if [ ! -f $new_name.nii.gz ] && [ $n -eq 1 ]
	then
		echo "Renaming files"
		mv $img_folder/NIFTI/*.nii.gz $new_name.nii.gz
		if [ "$img" == "DWI" ]
		then
			echo "Renaming vectors"
			n1=$(ls $img_folder/NIFTI/*.bval | wc -l)
			n2=$(ls $img_folder/NIFTI/*.bvec | wc -l)
			[ $n1 -eq 1 ] && mv $img_folder/NIFTI/*.bval $new_name.bval
			[ $n2 -eq 1 ] && mv $img_folder/NIFTI/*.bvec $new_name.bvec
		fi
	fi
done

echo "DONE dcm2nii"
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