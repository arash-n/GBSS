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

[ "thr" = "" ] && usage


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


if [ ! "other_atlas" = "" ]
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

for a in ????_FA.nii.gz

do 

WarpImageMultiTransform 3 ${out_dir}/ROI/atlas_${name}_in_temp_space.nii.gz ${a:0:4}_${aal}.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1/D1_${a:0:4}_psuedoT1Affine.txt ${out_dir}/FA/D1_intro/${a:0:4}_psuedoT1InverseWarp.nii.gz

#/projects/arash/home/ANTs/bin/WarpImageMultiTransformWarpImageMultiTransform 3 ../../ROIS/atlasMNI_in_temp_space.nii.gz ${a:0:4}_MNI.nii.gz  --use-NN -R ${a} -i ../D1/D1_${a:0:4}_psuedoT1Affine.txt  ${out_dir}/FA/D1_intro/${a:0:4}_psuedoT1InverseWarp.nii.gz

/projects/arash/home/ANTs/bin/WarpImageMultiTransform 3 ${out_dir}/ROI/cortHOx_in_temp_space.nii.gz ${a:0:4}_cHOX.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1_intro/${a:0:4}_psuedoT1Affine.txt  ${out_dir}/FA/D1_intro/${a:0:4}_psuedoT1InverseWarp.nii.gz

/projects/arash/home/ANTs/bin/WarpImageMultiTransform 3 ${out_dir}/ROI/subHOx_in_temp_space.nii.gz ${a:0:4}_sHOX.nii.gz  --use-NN -R ${a} -i ${out_dir}/FA/D1_intro/${a:0:4}_psuedoT1Affine.txt  ${out_dir}/FA/D1_intro/${a:0:4}_psuedoT1InverseWarp.nii.gz

#fslmaths ${a:0:4}_GM_frac -thr ${thr} -bin -mul ${a:0:4}_aal.nii.gz ${a:0:4}_aal_${thr}.nii.gz

#fslmaths ${a:0:4}_GM_frac -thr ${thr} -bin -mul ${a:0:4}_MNI.nii.gz ${a:0:4}_MNI_${thr}.nii.gz
fslmaths ${a:0:4}_GM_frac -thr ${thr} -bin -mul ${a:0:4}_cHOX.nii.gz ${a:0:4}_cHOX_${thr}.nii.gz
fslmaths ${a:0:4}_GM_frac -thr ${thr} -bin -mul ${a:0:4}_sHOX.nii.gz ${a:0:4}_sHOX_${thr}.nii.gz

done


ANTS 3 -m MI[MNI.nii.gz,D1_template.nii.gz,1,32] -o temp_in_MNI -i 30x90x20 -r Gauss[3,1] -t Elast[3]

WarpImageMultiTransform 3 D1_template.nii.gz template_MNI_warped.nii.gz -R MNI.nii.gz temp_in_MNIWarp.nii.gz temp_in_MNIAffine.txt

WarpImageMultiTransform 3 all_ODI_tfce_corrp_tstat1.nii.gz MNI_ODI_tfce_corrp_tstat1.nii.gz --use-NN -R ../../ROIS/MNI.nii.gz ../../ROIS/temp_in_MNIWarp.nii.gz ../../ROIS/temp_in_MNIAffine.txt
