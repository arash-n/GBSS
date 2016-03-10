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
echo "."
echo ""
echo "Here is the usage:"
echo "Usage: gbss_native.sh -i GM_frac_in_dwi.nii.gz -a label_file_in_dwi.nii.gz -s subcortical_thr"
echo "-r right_cortical_thr -l left_cortical_thr"
echo ""
echo "These are all mandatory:"
echo "    -i:  Input gray matter fraction (PVE) in the native diffusion space." 
echo "    -a:  Label file including subcortical, left, and right cortical labels in the"
echo "         native diffusion space"
echo "These are optional, if no input is provided the corresponding values from Freesurfer's aparc+aseg.mgz"
echo "    -s:  Maximum threshold to discard voxels in the subcortical structures in the label file [Freesurfer: 100]."
echo "    -r:  Minimum value of the right cortical structures in the label file [Freesurfer: 1000]."
echo "    -l:  Minimum value of the left cortical structures in the label file [Freesurfer: 2000]."
echo ""
echo "    -h:  Prints this message"

echo ""
exit 1
}

thr_sub=100
thr_right=1000
thr_left=2000

#Setting Defaults

while getopts ":i:a:s:r:l:h" OPT; do
   case $OPT in

     i) #template method

          gm_frac=$OPTARG

          if [[ ${#gm_frac} == 0 ]] ; then

          usage

          fi

          ;;

     a) # getopts issues an error message

          label=$OPTARG
          if [[ ${#label} == 0 ]] ; then
          usage
          fi

          ;;

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
