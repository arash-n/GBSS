#!/bin/bash

#v0.1 Feb 23rd 2016
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

out_dir=$1
atlas=$2 
[ "$atlas" = "" ] && usage


usage() {
echo ""
echo "You need to provide the GBSS output directory and atlas for ROIs."
echo "    e.g gbss_stats.sh gbss_out_dir atlas_name"

echo ""
exit 1
}

cd $out_dir/FA/FA

first_file=`ls *$atlas* | head -n 1`
largest=`fslstats $first_file -R|awk '{print $2}'`


for a in *_FA.nii.gz

do 
subname=`echo ${a%_*}`

for i in `seq 1 $largest`;         
do

min=`echo "$i-0.5"|bc`
max=`echo "$i+0.5"|bc`
ind=`echo "$i-1"|bc`

fslmaths ${subname}_${atlas}_*.*.nii.gz -thr $min -uthr $max -bin mask
odi[$ind]=,`fslstats $out_dir/ODI/$subname -k mask -M`
fic[$ind]=,`fslstats $out_dir/fIC/$subname -k mask -M`
vol[$ind]=,`fslstats mask -V|awk '{print $2}'`

done
echo "$subname ${odi[*]}">>${atlas}_ODI.csv
echo "$subname ${fic[*]}">>${atlas}_fIC.csv
echo "$subname ${vol[*]}">>${atlas}_vol.csv

done
