#This script performs the following tasks:

#1.Concatenating GM probability maps in the MNI space
#2.Averaging across the sample size the regions with greater probability than 70% of being
#3.Skeletonizing GM using tbss_skeleton
#4.Projecting other NODDI indices to the skeleton
#5.Identifies voxels with sub-optimal GM probability (less than 70% probability) in individual skeletonized GM maps. These could either handled as lesions and submitted to the next script, or filled using a Gaussian kernel with nearby voxels in the gray matter skeleton.

out_dir=/scratch/arash/NODDI/allPsych/
tmp_folder=u55_plus
stats_folder=`echo stats_${tmp_folder}`

thresh=0.65 #GM Threshold

cd $out_dir

mkdir $stats_folder
cd $stats_folder

fslmerge -t all_GM ${out_dir}/${tmp_folder}/*GM*
fslmaths all_GM -thr $thresh -bin -Tmean mean_GM
fslmaths mean_GM -thr 0.2 -bin GM_mask
tbss_skeleton -i mean_GM.nii.gz -o GM_skel
fslmaths GM_skel.nii.gz -thr $thresh -bin GM_skel_${thresh}

fslmaths GM_mask -mul -1 -add 1 -add GM_skel_${thresh} GM_mean_skeleton_mask_dst

distancemap -i GM_mean_skeleton_mask_dst -o GM_mean_skeleton_mask_dst

fslmaths ${FSLDIR}/data/standard/LowerCingulum_1mm -mul 0 zero
tbss_skeleton -i mean_GM -p ${thresh} GM_mean_skeleton_mask_dst zero all_GM all_GM_skeletonise

fslmaths all_GM_skeletonise.nii.gz -thr ${thresh} -bin -Tmean -thr 0.75 -bin mean_GM_skeleton_mask_general


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


######OPTION 1
mkdir lesion

cp all_lesion.nii.gz lesion/
cd lesion

fslsplit all_lesion lesion


