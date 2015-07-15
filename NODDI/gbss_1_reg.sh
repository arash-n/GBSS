#!/bin/bash

#v2.1 July 28th 2015
#Arash Nazeri and Jon Pipitone, Kimel Family Translational
#Imaging-Genetics Research Lab
#This script depends on ANTs v2.1 and FSL v4.1.9 (or higher)
#
#Developed at Kimel Family Translational Imaging Genetics Ressearch
#Laboratory (TIGR), Research Imaging Centre, Campbell Family Mental
#Health Institute,Centre for Addiction and Mental Health (CAMH),
#Toronto, ON, Canada
# http://imaging-genetics.camh.ca
#
# NODDI-GBSS (c) by Arash Nazeri and Jon Pipitone, Kimel Family Translational
# Imaging-Genetics Research Lab
#
# NODDI-GBSS is licensed under a
# Creative Commons Attribution-NonCommercial 4.0 International License.
#
# You should have received a copy of the license along with this
# work.  If not, see <http://creativecommons.org/licenses/by-nc/4.0/>.


usage() {
echo ""
echo "This script nonlinearly registers diffusion images to a template space."
echo "Outputs from the NODDI and DTI models should be already available."
echo ""
echo "This script works as follows:"
echo "1) The input older containing the following subdirectories:"
echo "FA, CSF, ODI, fIC"
echo "2) Each Folder should contain corresponding image files with the same subject name in all folders."
echo "NOTE: Remove any underline (_) from your filenames."
echo "Here is its usage:"
echo "Usage: gbss_1_reg.sh input_directory [options]"
echo ""
echo "    -c:  to create or use a pre-existing template (default: 1, creates a template"
echo "         0: use pre-existing template)"
echo "    -t:  input template file here. This will be used as the initial template or"
echo "         final template depending on -c option input."
echo "    -h:  prints this message"

echo ""
exit 1
}

[ "$1" = "" ] && usage

#Setting Defaults
method=1;
template="${FSLDIR}/MNI152_T1_1mm.nii.gz"

while getopts "c:h:t" OPT

do

case $OPT in

h) #help

usage

;;

c) #threshold method

method=$OPTARG

if [[ ${#method} == 0 ]] ; then

echo "Using a pre-existing template file..."

fi

;;

t) # getopts issues an error message

template=$OPTARG

;;


\?) # getopts issues an error message

usage

exit 1

;;

esac

done


###############################################################
################# PART 1.1: Making Directories ################
###############################################################

#making output directory/subdirectories for the analysis

out_dir=$1 #output directory
mkdir ${out_dir}/tmpsapce

###############################################################
################## PART 1.2: tbss_1_preproc ###################
###############################################################

echo "Starting TBSS preproc to discard the high intensity rim of the FA files..."

cd ${out_dir}/FA
tbss_1_preproc *nii.gz

###############################################################
### PART 1.3: GM/WM PVE estimation/Creating PseudoT1 Images ###
###############################################################
echo "GM/WM PVE estimation/Creating PseudoT1 Images..."

cd ${out_dir}/FA/FA

#GM probability map is created by subtracting WM and CSF probabilities maps form 1.
for a in *_FA.nii.gz
do

subname=`echo ${a%_*}`
fslmaths ${a} -bin ${subname}_mask

Atropos -d 3 -a ${a} -x  ${subname}_mask.nii.gz -c[5,1.e-5] -i Kmeans[2] -o [segmentation.nii.gz, ${subname}_%02d.nii.gz]

fslmaths  ${subname}_02 ${subname}_WM_frac

fslmaths ${subname}_mask -mul ${out_dir}/ODI/${subname}.nii ${out_dir}/ODI/${subname}_m.nii
fslmaths ${subname}_mask -mul ${out_dir}/fIC/${subname}.nii ${out_dir}/fIC/${subname}_m.nii

fslmaths ${subname}_WM_frac -add ../../CSF/${subname} -sub 1 -mul -1 -thr 0 -mul ${subname}_mask  ${subname}_GM_frac 

fslmaths ${subname}_WM_frac -mul 2 ${subname}_WM_con
fslmaths ${subname}_GM_frac -mul 1 ${subname}_GM_con
fslmaths ../../CSF/${subname} -mul 0 -add ${subname}_GM_con -add ${subname}_WM_con ${subname}_psuedoT1

done

###############################################################
### PART 1.4.a: Creating Template/ Estimating Warp Fields  ####
###############################################################
mkdir ../D1
cp *_psuedoT1.nii.gz ../D1/
cd ../D1

if [ ${#method} == 1 ]
then

echo "OPTION 1: Creating Template Image"

buildtemplateparallel.sh  -d 3 -j 1 -o D1_ -n 0 -s MI -i 8 -m 30x50x20 -t GR -z $template  *_psuedoT1.nii.gz

fi

###############################################################
#### PART 1.4.b: Nonlinear Transformation to the Template  ####
###############################################################
#OPTION 2: Requires pre-estimated Template image
if [ ${#method} == 0 ]
then
echo "OPTION 0: Nonlinear Transformation to a Pre-existing Template Image"

for a in *_psuedoT1.nii.gz
do
label=`${a%_*}`

fsl_sub -N ANTS_${label} antsIntroduction.sh -d 3 -i ${a} -o ${label} -n 0 -s MI -m 30x50x20 -t GR -r /scratch/arash/NODDI/allPsych/FA/D1_series/D1_template.nii.gz  *_psuedoT1.nii.gz

done

jobcount=`qstat|grep ANTS_|wc -l`
if [ $jobcount -gt 0 ]
then
sleep 120
fi
fi

###############################################################
######### PART 1.5: Applying Warp Fields to Images  ###########
###############################################################

cd ${out_dir}/FA/FA

D1_folder=FA/D1 #Warp field/Affine Transfrom Directory
ref=${out_dir}/FA/D1/D1_template.nii.gz

for FAs in  *_FA.nii.gz
do
a=`echo ${FAs} |cut -f1 -d"_"` # No "_" is permitted in the subject IDs

 fsl_sub antsApplyTransforms -i ${a}_GM_frac.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_GM.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${a}_WM_frac.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_WM.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/fIC/${a}_m.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_fIC.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/ODI/${a}_m.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_ODI.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/CSF/${a}.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_CSF.nii.gz --float

done
