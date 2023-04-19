#!/bin/bash

#v0.2.1 July 28th 2015
#Arash Nazeri and Jon Pipitone, Kimel Family Translational
#Imaging-Genetics Research Lab
#This script depends on ANTs v2.1 and FSL v4.1.9 (or higher)

#Developed at Kimel Family Translational Imaging Genetics Ressearch
#Laboratory (TIGR), Research Imaging Centre, Campbell Family Mental
#Health Institute,Centre for Addiction and Mental Health (CAMH),
#Toronto, ON, Canada
# http://imaging-genetics.camh.ca

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
echo "This script performs the following tasks:"
echo "1.Concatenating GM probability maps in the MNI space"
echo "2.Averaging across the sample size the regions with greater probability the given threshold"
echo "3.Skeletonizing GM using tbss_skeleton"
echo "4.Projecting other NODDI indices to the skeleton"
echo "5.Identifies voxels with sub-optimal GM probability (less than input threshold probability) in individual skeletonized GM maps. These could either be handled as lesions and submitted to the next script (setup_masks), or filled using a Gaussian kernel with nearby voxels in the gray matter skeleton (gbss_3_fill.sh)."
echo "Here is its usage:"
echo ""
echo "Usage: gbss_2_skel.sh input_directory [options]"
echo ""
echo "    -p:  % of Subjects who should have an acceptable voxel. (default: 0.7)"
echo ""
echo "    -t:  Input threshold. (Default: 0.65)"
echo ""
echo "    -d:  Output directory name. (Default: stats)"
echo ""
echo ""
echo "    -h:  prints this message"

echo ""
exit 1
}
[ "$1" = "" ] && usage

Sub_folder=$1
tmp_folder=${Sub_folder}/tmpspace
stats_folder=${Sub_folder}/stats
method=0
thresh=0.65 #GM Threshold
perc=0.7   #percentage of subjects

while getopts "c:h:m:t" OPT

do

case $OPT in

h) #help

usage

;;

m) #threshold method

method=$OPTARG

if [[ ${#method} -gt 1 ]] ; then

echo "-m option can only be 0 or 1"
exit 1

fi

;;

t)

thresh=$OPTARG

;;

p)

perc=$OPTARG

;;

\?) # getopts issues an error message

usage

exit 1

;;

esac

done


mkdir $stats_folder
cd $stats_folder

fslmerge -t all_GM ${tmp_folder}/*GM*
fslmaths all_GM -thr $thresh -bin -Tmean mean_GM
fslmaths mean_GM -thr 0.2 -bin GM_mask
tbss_skeleton -i mean_GM.nii.gz -o GM_skel
fslmaths GM_skel.nii.gz -thr $thresh -bin GM_skel_${thresh}

fslmaths GM_mask -mul -1 -add 1 -add GM_skel_${thresh} GM_mean_skeleton_mask_dst

distancemap -i GM_mean_skeleton_mask_dst -o GM_mean_skeleton_mask_dst

fslmaths ${FSLDIR}/data/standard/LowerCingulum_1mm -mul 0 zero
tbss_skeleton -i mean_GM -p ${thresh} GM_mean_skeleton_mask_dst zero all_GM all_GM_skeletonise

fslmaths all_GM_skeletonise.nii.gz -thr ${thresh} -bin -Tmean -thr $perc -bin mean_GM_skeleton_mask_general


fslmerge -t all_ODI ${out_dir}/${tmp_folder}/*ODI*
fslmerge -t all_fIC ${out_dir}/${tmp_folder}/*fIC*
fslmerge -t all_WM ${out_dir}/${tmp_folder}/*WM*
fslmerge -t all_CSF ${out_dir}/${tmp_folder}/*CSF*

tbss_skeleton -i mean_GM -p $thresh GM_mean_skeleton_mask_dst zero all_GM all_ODI_skeletonised -a all_ODI
tbss_skeleton -i mean_GM -p $thresh GM_mean_skeleton_mask_dst zero all_GM all_fIC_skeletonised -a all_fIC
tbss_skeleton -i mean_GM -p $thresh GM_mean_skeleton_mask_dst zero all_GM all_WM_skeletonised -a all_WM
tbss_skeleton -i mean_GM -p $thresh GM_mean_skeleton_mask_dst zero all_GM all_CSF_skeletonised -a all_CSF

fslmaths all_GM_skeletonise -mul mean_GM_skeleton_mask_general -uthr $thresh -bin all_lesion_GM
fslmaths all_WM_skeletonised -mul mean_GM_skeleton_mask_general -thr 0.3 -bin all_lesion_WM
fslmaths all_CSF_skeletonised -mul mean_GM_skeleton_mask_general -thr 0.4 -bin all_lesion_CSF
fslmaths all_fIC_skeletonised -mul mean_GM_skeleton_mask_general -thr 0.65 -bin all_lesion_fIC

fslmaths all_lesion_GM -add all_lesion_WM -add all_lesion_CSF -bin all_lesion
fslmaths all_lesion -Tmean lesion_mean

mkdir lesion

cp all_lesion.nii.gz lesion/

cd lesion

fslsplit all_lesion lesion

# Logging parameters
echo "Logging Parameters">../gbss_2_parameter_log.txt
echo "Method=$method">>../gbss_2_parameter_log.txt
echo "Gray Matter Thresold={$thresh}">>../gbss_2_parameter_log.txt
echo "Fraction of subjects with skeletonized voxel=${perc}">>../gbss_2_parameter_log.txt
