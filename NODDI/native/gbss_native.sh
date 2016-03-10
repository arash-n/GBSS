#!/bin/bash
#v 0.1 March 10th 2016
#Arash Nazeri, Kimel Family Translational Imaging-Genetics Research Lab
#This script depends on ANTs v2.1 and FSL v4.1.9 (or higher)
#
#Developed at Kimel Family Translational Imaging Genetics Ressearch
#Laboratory (TIGR), Research Imaging Centre, Campbell Family Mental
#Health Institute,Centre for Addiction and Mental Health (CAMH),
#Toronto, ON, Canada
# http://imaging-genetics.camh.ca
#
# NODDI-GBSS (c) by Arash Nazeri Kimel Family 
#Translational Imaging-Genetics Research Lab
#
# NODDI-GBSS is licensed under a
# Creative Commons Attribution-NonCommercial 4.0 International License.
#
# You should have received a copy of the license along with this
# work.  If not, see <http://creativecommons.org/licenses/by-nc/4.0/>.

usage() {
echo ""
echo "This script depends on FSL v4.1.9 (or higher) and creates labeled GM skeleton in the native diffusion space."
echo ""
echo "Here is the usage:"
echo "gbss_native.sh GM_frac_in_dwi.nii.gz label_file_in_dwi.nii.gz [options]"
echo ""
echo "These are all mandatory:"
echo "    First input: gray matter fraction (PVE) in the native diffusion space." 
echo "    Second input: label file including subcortical, left, and right cortical"
echo "    labels in the native diffusion space"
echo ""
echo "These are optional, if no input is provided the corresponding values from Freesurfer's aparc+aseg.mgz"
echo "    -s:  Maximum threshold to discard voxels in the subcortical structures in the label file [Freesurfer: 100]."
echo "    -r:  Minimum value of the right cortical structures in the label file [Freesurfer: 1000]."
echo "    -l:  Minimum value of the left cortical structures in the label file [Freesurfer: 2000]."
echo ""
echo "    -h:  Prints this message"

echo ""
exit 1
}

[ "$2" = "" ] && usage

#Setting Defaults
thr_sub=100
thr_right=1000
thr_left=2000

#Input files
gm_frac=`imglob $1`
label_file=`imglob $2`

while getopts ":s:r:l:h" OPT; do
   case $OPT in

     s) # getopts issues an error message

          thr_sub=$OPTARG

          ;;
     r) # getopts issues an error message

          thr_right=$OPTARG
          ;;
     l) # getopts issues an error message

          thr_left=$OPTARG

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

### Skeletonization of GM_fraction in DWI space
tbss_skeleton -i $gm_frac -o ${gm_frac}_skel
#imcp  ${gm_frac}_skel ${gm_frac}_skel_1
fslmaths $label_file -uthr $thr_sub -mul 100 -sub ${gm_frac}_skel -mul -1 -thr 0 ${gm_frac}_skel
fslmaths $label_file -mul 0 zero

k=$thr_right;j=0
mkdir tmp_right

while true
then
(
min=$(echo "$k - 0.5"|bc)
max=$(echo "$k + 0.5"|bc)

tmp_val=`printf "%03d" $j`
fslmaths $label_file -thr $min -uthr $max -bin tmp_right/mask_${tmp_val}

volume_mask=`fslstats tmp_right/mask_${tmp_val} -V|awk '{print $1}'`

if [ $volume_mask -eq 0 ]
rm tmp_right/mask_${tmp_val}
fslmerge -t all_right_mask zero tmp_right/mask_*gz
break
fi

j=$((j+1))
k=$((k+1))

)
done
