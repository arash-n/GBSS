#cd to FA folder

tbss_1_preproc *nii.gz
cd origdata

for a in *

do
subname=`imglob $a`;

fslmaths ../FA/${subname}_FA -bin ../${subname}_mask;
Atropos -d 3 -a ${a} -x  ../${subname}_mask.nii.gz -i Kmeans[2] -m [${mrf},1x1x1] -o [../segmentation.nii.gz,../${subname}_%02d.nii.gz]

fslmaths ../${subname}_mask -sub ../../FW/$subname -sub ../${subname}_02 -thr 0 ../../GM/$subname

done
