#!/bin/bash
#v 0.1 March 14th 2016
#Arash Nazeri, Kimel Family Translational Imaging-Genetics Research Lab
#This script depends on FSL v4.1.9 (or higher)
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
echo "    -g:  Gaussian Kernel size [sigma=3]."
echo "    -t:  GM probability threshold [GM PVE > 0.7]"
echo ""
echo "    -h:  Prints this message"

echo ""
exit 1
}

[ "$2" = "" ] && usage

#Setting Defaults
thr_sub=100 #maximum value for subcortical ROIs in the label file 
thr_right=2000 #lowest value for the right cortical ROIs in the label file
thr_left=1000 #lowest value for the left cortical ROIs in the label file
diff=$(echo "$thr_right - $thr_left"|bc)
sigma=3 #smoothing kernel
thr=0.7 #GM threshold
max_rois=80 #number of ROIs (Freesurfer)
temp_number=$RANDOM #random number for intermediate files 
sthr=0.01 #minimum value after smoothing

vals="2 4 5 7 14 15 16 24 28 31 41 44 46 60 63 77" #Freesurfer subcortical regions to be excluded

#Input files
gm_frac=`imglob $1`
label_file=`imglob $2`

while getopts ":s:r:l:g:t:h" OPT; do
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
     g) # getopts issues an error message

          sigma=$OPTARG

          ;;
     t) # getopts issues an error message

          thr=$OPTARG

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
#set -x

### Skeletonization of GM_fraction in DWI space
tbss_skeleton -i $gm_frac -o ${gm_frac}_skel
fslmaths ${gm_frac}_skel -thr $thr -bin ${gm_frac}_skel_mask
#imcp  ${gm_frac}_skel ${gm_frac}_skel_1

imcp $label_file ${temp_number}_subcortical
for val in $vals 
do
fslmaths $label_file -thr $(echo "$val - 0.5"|bc) -uthr $(echo "$val + 0.5"|bc) -bin -mul 1000 ${temp_number}_ex_sub

fslmaths ${temp_number}_subcortical -sub ${temp_number}_ex_sub -thr 0 ${temp_number}_subcortical
done

fslmaths $label_file -mul 0 ${temp_number}_zero

k=$thr_left;j=0

mkdir ${temp_number}

while [ $j -lt $max_rois ]
do
min=$(echo "$k - 0.5"|bc)
max=$(echo "$k + 0.5"|bc)

min_r=$(echo "$min + $diff"|bc)
max_r=$(echo "$max + $diff"|bc)

tmp_val=`printf "%03d" $j`
fslmaths $label_file -thr $min -uthr $max -bin ${temp_number}/mask_${tmp_val}_r
fslmaths $label_file -thr $min_r -uthr $max_r -bin ${temp_number}/mask_${tmp_val}_l

if [ $j -gt 0 ]
then
fslmaths ${temp_number}_subcortical -thr $(echo "$j - 0.5"|bc) -uthr $(echo "$j + 0.5"|bc) -bin ${temp_number}/sub_mask_${tmp_val}
fi

j=$((j+1))
k=$((k+1))

done

fslmaths ${gm_frac}_skel_mask -sub ${temp_number}_subcortical -bin ${temp_number}_search_dis_map

cd ${temp_number}

for a in *nii.gz
do

vol=`fslstats $a -V | awk '{print $1}'`
if [ $vol -gt 0 ]
then

distancemap -i $a -o distance_${a} -m ../${temp_number}_search_dis_map
fslmaths  ../${temp_number}_search_dis_map -div -nan distance_${a} -odt float

else

imcp ../${temp_number}_zero distance_${a}

fi

done
cd ..

fslmerge -t ${temp_number}_all_dis_inverse ${temp_number}/distance*
fslmaths ${temp_number}_all_dis_inverse -Tmax ${temp_number}_nearest
fslmaths  ${gm_frac}_skel_mask -mul ${temp_number}_subcortical -add ${temp_number}_nearest 
