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

Studyfolder=~/GBSS/K00309003/stats
cd $Studyfolder

if [ ! -e all_lesion.nii.gz ]
then

echo "Make sure you are in the correct directory."
exit 0

fi

mkdir filling
cp all_lesion.nii.gz filling/
cp all_fIC_skeletonised.nii.gz filling/
cp all_ODI_skeletonised.nii.gz filling/
cd filling
fslmaths all_lesion.nii.gz -sub 1 -mul -1 -mul all_fIC_skeletonised.nii.gz -thr 0 fIC_non_lesion

fslmaths fIC_non_lesion -s 2 fIC_non_lesion_s_2
fslmaths fIC_non_lesion -bin -s 2 fIC_non_lesion_bin_s_2

fslmaths fIC_non_lesion_s_2 -div fIC_non_lesion_bin_s_2 fIC_filler

fslmaths fIC_non_lesion_bin_s_2 -thr 0.05 -bin -mul all_lesion.nii.gz -mul fIC_filler -add fIC_non_lesion all_fIC_filled

fslmaths all_lesion.nii.gz -sub 1 -mul -1 -mul all_ODI_skeletonised.nii.gz -thr 0 ODI_non_lesion

fslmaths ODI_non_lesion -s 2 ODI_non_lesion_s_2
fslmaths ODI_non_lesion -bin -s 2 ODI_non_lesion_bin_s_2

fslmaths ODI_non_lesion_s_2 -div ODI_non_lesion_bin_s_2 ODI_filler

fslmaths ODI_non_lesion_bin_s_2 -thr 0.05 -bin -mul all_lesion.nii.gz -mul ODI_filler -add ODI_non_lesion all_ODI_filled

###pre-Randomise
mkdir ../final
cp all*filled.nii.gz ../final
cd ../final

fslmaths all_fIC_filled.nii.gz -thr 0.05 -bin all_bin
fslmaths all_bin.nii.gz -Tmean bin_mean
fslmaths bin_mean.nii.gz -thr 0.995 mask



#randomise -i all_fIC_filled.nii.gz -o gbss_fic -m mask.nii.gz -d plus.mat -t plus.con -n 100 --T2
