

usage() {
echo ""
echo "You need to provide the GBSS output directory."
echo "    e.g gbss_atlas.sh gbss_out_dir"

echo ""
exit 1
}

out_dir=$1

[ "$out_dir" = "" ] && usage


mkdir $out_dir/atlas
cd $out_dir/atlas
cp $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz $out_dir/MNI.nii.gz

cp $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz ./
cp $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz ./


ANTS 3 -m MI[D1_template.nii.gz,MNI.nii.gz,1,32] -o MNI_in_temp -i 30x90x20 -r Gauss[3,1] -t Elast[3]

WarpImageMultiTransform 3 MNI.nii.gz MNI_in_temp_space.nii.gz -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt


WarpImageMultiTransform 3 aal_fsl.nii.gz aal_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

WarpImageMultiTransform 3 HarvardOxford-sub-maxprob-thr25-1mm.nii.gz subHOx_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

WarpImageMultiTransform 3 HarvardOxford-cort-maxprob-thr25-1mm.nii.gz cortHOx_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt

WarpImageMultiTransform 3 MNI-maxprob-thr25-1mm.nii.gz atlasMNI_in_temp_space.nii.gz --use-NN -R D1_template.nii.gz MNI_in_tempWarp.nii.gz MNI_in_tempAffine.txt
