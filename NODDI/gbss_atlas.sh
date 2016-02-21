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
echo "You need to provide the GBSS output directory."
echo "    e.g gbss_atlas.sh gbss_out_dir"
echo "Additional atlas can be given as the second argument."

echo ""
exit 1
}

out_dir=$1
other_atlas=$2
[ "$out_dir" = "" ] && usage


mkdir $out_dir/atlas
cd $out_dir/atlas

### 1. MNI to Template
cp $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz $out_dir/MNI.nii.gz

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

