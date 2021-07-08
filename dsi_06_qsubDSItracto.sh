#!/bin/bash
#SBATCH --job-name="DSItracto"
#SBATCH --time=65:00:00
#SBATCH --account=jbinder
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)

# Module loads
module load afni
module load dsistudio
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Variables
projDir=/scratch/u/mkeith/iPadStudy
cd $projDir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}
cd ${sbj}_day1
echo "**** Running tractography on ${sbj} ****"

##################################
# Generate ROIs for tractography #
##################################
echo "1. Generating ROIs..."
n=0
for h in lh rh
do
        3dmaskdump -overwrite -noijk -nozero -quiet -o tmp_${sbj}_${h}.txt DistFilt_${sbj}_${h}_VOL.diff.nii.gz
        cat tmp_${sbj}_${h}.txt | sort -nu > DistFilt_${sbj}_${h}_VOL.txt
        rm tmp_${sbj}_${h}.txt
        for val in $(cat DistFilt_${sbj}_${h}_VOL.txt)
        do
                fslmaths DistFilt_${sbj}_${h}_VOL.diff.nii.gz -thr $val -uthr $val ${sbj}_${h}_${val}.nii.gz
                ROIs[n++]=${h}_${val}
        done
done

#############################################
# Do tractography between each pair of ROIs #
#############################################
# Write the header of the csv file
if [ ! -f tracto_prev.csv ]
then
    echo "This is a fresh run"
    line=""
    for seed in ${ROIs[@]}; do line="${line},${seed}"; done
    echo $line >> tracto.csv
else
    echo "Restarting from an inturrupted run"
    # Remove the last row of previous result file (the seed that was running when it failed)
    N=$(cat tracto_prev.csv | wc -l)
    ((N--))
    cat tracto_prev.csv | head -n$N > tracto.csv
    # Remove the heather and last row to keep only the rows of the seeds that finished successfully
    cat tracto_prev.csv | tail -n$N | head -n$((N - 1)) > tmp.csv
    mv tmp.csv tracto_prev.csv
fi

echo "2. Running tractography..."; echo ""
for roi1 in ${ROIs[@]}
do
        # If re-running from an interrupted execution and this roi was already processed as a seed, skip it
        [ -f tracto_prev.csv ] && [ $(grep ${roi1}, tracto_prev.csv | wc -l) -gt 0 ] && echo "Skipping seed ${roi1}" && continue 
        
        seed=${sbj}_${roi1}
        line=$roi1
        for roi2 in ${ROIs[@]}
        do
                target=${sbj}_${roi2}
                echo "SEED: ${roi1}"; echo "SEED: ${roi1}" >> log.txt
                echo "TARGET: ${roi2}"; echo "TARGET: ${roi2}" >> log.txt

                tks=0
                if [ "$roi1" != "$roi2" ]
                then
                        echo "Running tracto between ${roi1} and ${roi2}..."; echo "Running tracto between ${roi1} and ${roi2}..." >> log.txt
                        dsi_studio --action=trk --source=${sbj}_day1_DWI.nii.gz.src.gz.gqi.1.25.fib.gz --output=${seed}_to_${target}.trk.gz --seed=$seed.nii.gz --end=$target.nii.gz --seed_count=1000000 --threshold_index=qa --dt_threshold=0.2 --turning_angle=75 --step_size=0.50 --smoothing=0.80 --min_length=20 --max_length=300 --method=0 --seed_plan=0 --initial_dir=0 --interpolation=0 --thread_count=1 --tip_iteration=0 --random_seed=1 >> tmp.txt
                        [ $(grep "tracts are generated" tmp.txt | wc -l) == 0 ] && rm -f ${seed}_to_${target}.trk.gz ${seed}_to_${target}.nii.gz ${seed}_to_${target}.txt || tks=$(grep "tracts are generated" tmp.txt | awk '{print $1}')
                        cat tmp.txt >> log.txt
                        echo "" >> log.txt
                        rm tmp.txt
                fi
                echo "RESULT: ${tks}"; echo "RESULT: ${tks}" >> log.txt
                echo ""; echo "" >> log.txt
                line="${line},${tks}"
        done
        echo $line >> tracto.csv
done
[ -f tmp.txt ] && mv tmp.txt trackingopts.txt

###############
# Remove ROIs #
###############
echo "3. Removing ROIs..."
for roi in ${ROIs[@]}
do
        rm ${sbj}_${roi}.nii.gz
done
echo "DONE DSItracto"

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
