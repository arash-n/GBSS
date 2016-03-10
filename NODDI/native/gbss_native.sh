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
echo "    -i:  Input gray matter fraction in the native diffusion space." 
echo ""
echo "    -a:  Label file including subcortical, left, and right cortical labels in the"
echo "         native diffusion space"
echo "    -s:  Maximum threshold to discard voxels in the "
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

while getopts ":i:t:w:n:f:p:h" OPT; do
   case $OPT in

     i) #template method

          gm_frac=$OPTARG

          if [[ ${#gm_frac} == 0 ]] ; then

          usage

          fi

          ;;

     t) # getopts issues an error message

          label=$OPTARG
          if [[ ${#label} == 0 ]] ; then
          usage
          fi

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
