#!/bin/bash

#v0.2.1 July 21st 2015
#Arash Nazeri, Jon Pipitone, and Tina Roostaei, Kimel Family Translational
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
echo "This script requires the following:"
echo "1) The input_directory containing the following subdirectories:"
echo "From DTI: FA; from NODDI: CSF, ODI, fIC"
echo "2) Each Folder should contain corresponding image files with the same subject name in all folders."
echo "NOTE: Remove any underline (_) from your filenames."
echo "NOTE: Provide the absolute path for input_directory "
echo ""
echo "Here is its usage:"
echo "Usage: gbss_1_reg.sh [options] input_directory"
echo ""
echo "    -c:  To create or use a pre-existing template (1 [default]: creates a template;"
echo "         0: use pre-existing template)"
echo "    -t:  Input template file here. This will be used as the initial template or"
echo "         final template depending on -c option input."
echo "    -f:  MRF parameter to atropos (0-1)."
echo "    -w:  To use prior white matter probability maps in the diffusion space (1 [default]:"
echo "         uses Atropos Kmeans as the priors; 0: uses input prior probability maps in the."
echo "         This option requires a WM folder available. 2: just uses WM probability maps from"
echo "         T1w images.)"
echo "    -p:  Prior weighting in Atropos (between 0-1 [if -w 0 is used])."
echo "    -n:  Number of iterations in buildtemplateparallel.sh"
echo "    -h:  Prints this message"

echo ""
exit 1
}


#Setting Defaults
ANTSdir=~/ANTS
method=1;
template="${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz"
atropos_method=1;
ants_number=4;
mrf=0.3;
prior=0.2;
while getopts ":c:t:w:n:f:p:h" OPT; do
   case $OPT in

     c) #template method

          method=$OPTARG

          if [[ ${#method} == 0 ]] ; then

          echo "Using a pre-existing template file..."

          fi

          ;;

     t) # getopts issues an error message

          template=$OPTARG

          ;;

     w) # getopts issues an error message

          atropos_method=$OPTARG

          ;;
     n) # getopts issues an error message

          ants_number=$OPTARG
          ;;
     f) # getopts issues an error message

          mrf=$OPTARG

          ;;
     p) # getopts issues an error message

          prior=$OPTARG

          ;;
     h) #help

          usage
          exit 1;
          ;;
     *) # getopts issues an error message

           usage

           exit 1

           ;;

   esac

done

shift $((OPTIND-1))
out_dir=$1 #output directory is the same as the input directory

[ "$out_dir" = "" ] && usage

echo "List of parameters:"
echo "prior=$prior"
echo "ANTS Method=$atropos_method"
echo "Template File: $template"
echo "MRF=$mrf"
echo "Output directory: $out_dir"

###############################################################
################# PART 1.1: Making Directories ################
###############################################################

#making output directory/subdirectories for the analysis

mkdir ${out_dir}/tmpspace

###############################################################
################## PART 1.2: tbss_1_preproc ###################
###############################################################

echo "Starting TBSS preproc to discard the high intensity rim of the FA files..."

cd ${out_dir}/FA
tbss_1_preproc *nii.gz
set -x

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

if [ ${atropos_method} -eq 1 ] ; then
echo "Using FA images to estimate WM PVE"
Atropos -d 3 -a ${a} -x  ${subname}_mask.nii.gz -i Kmeans[2] -m [${mrf},1x1x1] -o [segmentation.nii.gz,${subname}_%02d.nii.gz]

elif  [ ${atropos_method} -eq 0 ]
then
echo "Combining FA images with WM-PVE estimated from structural images to estimate final WM PVE"

cp ${out_dir}/WM/${subname}.nii.gz ${out_dir}/FA/FA/${subname}_prior02.nii.gz
fslmaths ${subname}_mask.nii.gz -sub ${subname}_prior02.nii.gz ${subname}_prior01.nii.gz

Atropos -d 3 -a ${a} -x  ${subname}_mask.nii.gz --i PriorProbabilityImages[2,${subname}_prior%02d.nii.gz, ${prior}] -m [ ${mrf},1x1x1] -o [segmentation.nii.gz, ${subname}_%02d.nii.gz]

fslmaths ${subname}_02.nii.gz -thr 0.2 -bin mask1
ImageMath 3 mask2.nii.gz FillHoles mask1.nii.gz

fslmaths mask2 -sub mask1 -mul ${subname}_prior02.nii.gz -add ${subname}_02.nii.gz ${subname}_02.nii.gz

elif  [ ${atropos_method} -eq 2 ]

then
echo "Using WM-PVE estimated from the structural images as the ultimate WM-PVE"

cp ${out_dir}/WM/${subname}.nii.gz ${subname}_02.nii.gz

fi

immv  ${subname}_02 ${subname}_WM_frac

fslmaths ${subname}_mask -mul ${out_dir}/ODI/${subname} ${out_dir}/ODI/${subname}_m
fslmaths ${subname}_mask -mul ${out_dir}/fIC/${subname} ${out_dir}/fIC/${subname}_m

fslmaths ${subname}_WM_frac -add ${out_dir}/CSF/${subname} -sub 1 -mul -1 -thr 0 -mul ${subname}_mask  ${subname}_GM_frac 

#fslmaths ${out_dir}/fIC/${subname} -thr 0.65 -bin -sub 1 -mul -1 -mul ${subname}_GM_frac -thr 0 ${subname}_GM_frac

#Discarding high FA voxels outside of the brain
if [ ${atropos_method} -lt 2 ]
then
echo "Getting the Largest Component for WM fraction"
ImageMath 3 ${subname}_WM_l_component.nii.gz GetLargestComponent ${subname}_WM_frac.nii.gz
fslmaths ${subname}_WM_frac.nii.gz -bin -sub ${subname}_WM_l_component.nii.gz -thr 0 -bin ${subname}_rim
fi

fslmaths ${subname}_WM_frac -mul ${subname}_WM_l_component.nii.gz -mul 2 ${subname}_WM_con
fslmaths ${subname}_GM_frac -thr 0 -mul 1 ${subname}_GM_con
fslmaths ${subname}_GM_con -add ${subname}_WM_con ${subname}_pseudoT1

done

###############################################################
### PART 1.4.a: Creating Template/ Estimating Warp Fields  ####
###############################################################
mkdir ${out_dir}/FA/D1
cp ${out_dir}/FA/FA/*_pseudoT1.nii.gz ${out_dir}/FA/D1/
cd ${out_dir}/FA/D1

if [ ${#method} == 1 ]
then

echo "OPTION 1: Creating Template Image"

bash ${ANTSdir}/ANTs/Scripts/buildtemplateparallel.sh -c 0  -d 3 -j 1 -o D1_ -n 0 -s MI -i $ants_number -m 30x50x20 -t GR -z $template  *_pseudoT1.nii.gz

fi

###############################################################
#### PART 1.4.b: Nonlinear Transformation to the Template  ####
###############################################################
#OPTION 2: Requires pre-estimated Template image
if [ ${method} == 0 ]
then
echo "OPTION 0: Nonlinear Transformation to a Pre-existing Template Image"

for a in *_psuedoT1.nii.gz
do
label=`${a%_*}`

fsl_sub -N ANTS_${label} antsIntroduction.sh -d 3 -i ${a} -o ${label} -n 0 -s MI -m 30x50x20 -t GR -r /scratch/arash/NODDI/allPsych/FA/D1_series/D1_template.nii.gz

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

 fsl_sub antsApplyTransforms -i ${a}_GM_frac.nii.gz -d 3 -e 0 -n NearestNeighbor -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Affine.txt -o ${out_dir}/tmpspace/${a}_GM.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${a}_WM_frac.nii.gz -d 3 -e 0 -n NearestNeighbor -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Affine.txt -o ${out_dir}/tmpspace/${a}_WM.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/fIC/${a}_m.nii.gz -d 3 -e 0 -n NearestNeighbor -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Affine.txt -o ${out_dir}/tmpspace/${a}_fIC.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/ODI/${a}_m.nii.gz -d 3 -e 0 -n NearestNeighbor -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Affine.txt -o ${out_dir}/tmpspace/${a}_ODI.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/CSF/${a}.nii.gz -d 3 -e 0 -n NearestNeighbor -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_pseudoT1Affine.txt -o ${out_dir}/tmpspace/${a}_CSF.nii.gz --float

done
