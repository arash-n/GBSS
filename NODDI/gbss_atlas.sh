#!/bin/bash

#v0.1 Feb 21st 2016
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
# NODDI-GBSS (c) by Arash Nazeri, Jon Pipitone, and Tina Roostaei
# Kimel Family Translational Imaging-Genetics Research Lab
#
# NODDI-GBSS is licensed under a
# Creative Commons Attribution-NonCommercial 4.0 International License.
#
# You should have received a copy of the license along with this
# work.  If not, see <http://creativecommons.org/licenses/by-nc/4.0/>.


usage() {
echo ""
echo "You need to provide the GBSS output directory and GM threshold."
echo "    e.g gbss_atlas.sh gbss_out_dir GM_threshold"
echo "Additional atlas can be given as the second argument."

echo ""
exit 1
}

out_dir=$1
thr=$2
other_atlas=$3

[ "$thr" = "" ] && usage


mkdir $out_dir/atlas
cd $out_dir/atlas
echo $thr > log_GM_thr.txt

### 1. MNI to Template
cp $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz $out_dir/atlas/MNI.nii.gz

cp $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz ./
cp $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz ./
cp $FSLDIR/data/atlases/MNI/MNI-maxprob-thr25-1mm.nii.gz ./

cp $out_dir/FA/D1/D1_template.nii.gz $out_dir/atlas

ANTS 3 -m MI[D1_template.nii.gz,MNI.nii.gz,1,32] -o MNI_in_temp -i 30x90x20 -r Gauss[3,1] -t Elast[3]


if [ ! "${other_atlas}" = "" ]
then
cp $other_atlas $out_dir/atlas

name=`basename $other_atlas`
name=`imglob $name`

WarpImageMultiTransform 3 $other_atlas atlas_${name}_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

fi

WarpImageMultiTransform 3 HarvardOxford-sub-maxprob-thr25-1mm.nii.gz atlas_subHOx_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

WarpImageMultiTransform 3 HarvardOxford-cort-maxprob-thr25-1mm.nii.gz atlas_cortHOx_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

WarpImageMultiTransform 3 MNI-maxprob-thr25-1mm.nii.gz atlas_MNI_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

### 2. Template to MNI 


cd ${out_dir}/FA/FA

for a in *_FA.nii.gz

do 
subname=`echo ${a%_*}`

echo "Creating ROIs for ${subname} ...."

WarpImageMultiTransform 3 ${out_dir}/atlas/atlas_MNI_in_temp_space.nii.gz ${subname}_MNI_atl.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1/D1_${subname}_pseudoT1Affine.txt ${out_dir}/FA/D1/D1_${subname}_pseudoT1InverseWarp.nii.gz

WarpImageMultiTransform 3 ${out_dir}/atlas/atlas_cortHOx_in_temp_space.nii.gz ${subname}_cHOX_atl.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1/D1_${subname}_pseudoT1Affine.txt ${out_dir}/FA/D1/D1_${subname}_pseudoT1InverseWarp.nii.gz

WarpImageMultiTransform 3 ${out_dir}/atlas/atlas_subHOx_in_temp_space.nii.gz ${subname}_sHOX_atl.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1/D1_${subname}_pseudoT1Affine.txt ${out_dir}/FA/D1/D1_${subname}_pseudoT1InverseWarp.nii.gz

if [ ! "${other_atlas}" = "" ]
then
WarpImageMultiTransform 3 ${out_dir}/atlas/atlas_${name}_in_temp_space.nii.gz ${subname}_${name}_atl.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1/D1_${subname}_pseudoT1Affine.txt ${out_dir}/FA/D1/D1_${subname}_pseudoT1InverseWarp.nii.gz
fslmaths ${subname}_GM_frac -thr ${thr} -bin -mul ${subname}_${name}_atl.nii.gz ${subname}_${name}_atl_${thr}.nii.gz
fi

fslmaths ${subname}_GM_frac -thr ${thr} -bin -mul ${subname}_MNI_atl.nii.gz ${subname}_MNI_atl_${thr}.nii.gz
fslmaths ${subname}_GM_frac -thr ${thr} -bin -mul ${subname}_cHOX_atl.nii.gz ${subname}_atl_cHOX_${thr}.nii.gz
fslmaths ${subname}_GM_frac -thr ${thr} -bin -mul ${subname}_sHOX_atl.nii.gz ${subname}_sHOX_atl_${thr}.nii.gz

done
