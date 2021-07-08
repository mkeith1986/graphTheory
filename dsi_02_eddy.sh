#!/bin/bash
#SBATCH --job-name="eddy"
#SBATCH --time=5:00:00
#SBATCH --gres=gpu:1
#SBATCH --account=jbinder
#SBATCH --mem-per-cpu=30gb
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Variables
rundir=/scratch/u/mkeith/iPadStudy
cd $rundir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}
imain=${sbj}_day1/${sbj}_day1_DWI.nii.gz
mask=${sbj}_day1/nodif_brain_mask
index=${sbj}_day1/index.txt
acqp=${sbj}_day1/acqparams.txt
bvecs=${sbj}_day1/${sbj}_day1_DWI.bvec
bvals=${sbj}_day1/${sbj}_day1_DWI.bval
out=${sbj}_day1/eddy_unwarped_images
echo "Running eddy on ${sbj}..."
echo "imain: ${imain}"
echo "mask: ${mask}"
echo "index: ${index}"
echo "acqp: ${acqp}"
echo "bvecs: ${bvecs}"
echo "bvals: ${bvals}"
echo "output prefix: ${out}"

#### CREATE INDEX AND ACQPARAMS FILES ####
echo "Creating index file..."
nvols=$(fslval $imain dim4)
echo "${nvols} vols"
for ((i=1; i<=$nvols; i+=1)); do echo 1 >> $index; done
[ ! -f $index ] && echo "Index file was not created" && exit 1
echo "Creating acqparams file..."
echo "0 1 0 0.05" >> $acqp
[ ! -f $acqp ] && echo "Acqparams file was not created" && exit 1

#### RUN EDDY ####
echo "Running eddy..."
# N = #slices/#simultaneous_slices = 34/1 = 34
# 34/4=8.5 <= mporter <= 34/2=17
# ol_type: type of outliers (NOT multiband)
eddy_cuda --imain=$imain --mask=$mask --index=$index --acqp=$acqp --bvecs=$bvecs --bvals=$bvals --out=$out --fwhm=10,0,0,0,0 --repol --resamp=jac --fep --ol_type=sw --mporder=12 --very_verbose --cnr_maps

echo "DONE eddy"
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
