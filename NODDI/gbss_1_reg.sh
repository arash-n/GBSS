
###v2.0 26/03/2015

###############################################################
######### PART 1.1: Making Directories/Copying Files ##########
###############################################################

#making output directory/subdirectories for the analysis

out_dir=/scratch/arash/NODDI/allPsych #output directory should be defined here
mkdir ${out_dir}/
mkdir ${out_dir}/FA
mkdir ${out_dir}/FA/nonlinear_reg
mkdir ${out_dir}/CSF
mkdir ${out_dir}/ODI
mkdir ${out_dir}/fIC
mkdir ${out_dir}/tmpsapce

sub_dirs=/scratch/arash/NODDI/allPsych/subdirs #The list of subject directories (in full path)

#Copying files to the output directories (from the list of subject directories). CAUTION: Only the last 4 characters in the folder names will be used as the subject IDs.

out_dir=/projects/arash/NODDI/NODDI-G/newPsych

while read a; do

string=`basename $a`
subid=`echo ${string:(-4)}` #The number of characters can be modified here.

fslmaths ${a}/DTI_FA.nii.gz -mul ${a}/brain_mask ${out_dir}/FA/${subid}.nii.gz ;
 
cp ${a}/*${string}_fiso.nii.gz ${out_dir}/CSF/${subid}.nii.gz ;
cp ${a}/*${string}_odi.nii.gz ${out_dir}/ODI/${subid}.nii.gz ;
cp ${a}/*${string}_ficvf.nii.gz ${out_dir}/fIC/${subid}.nii.gz ;

echo "$string copied"

done<${sub_dirs}

#OPTIONAL: If there is an additional selection criteria to restrict analysis
#Provide only the subject ids (sub_incl) that need to be included in the analysis

cd ${out_dir}/FA

mkdir included
while read line
do

cp ${line}.nii.gz included

done<sub_incl
mkdir all
mv *nii.gz all/
mv included/*gz ./

###############################################################
################## PART 1.2: tbss_1_preproc ###################
###############################################################

#Starting TBSS preproc to discard the high intensity rim of the FA files.
#out_dir=/scratch/arash/NODDI/allPsych

tbss_1_preproc *nii.gz

###############################################################
### PART 1.3: GM/WM PVE estimation/Creating PseudoT1 Images ###
###############################################################

out_dir=/scratch/arash/NODDI/allPsych
cd ${out_dir}/FA/FA

#GM probability map is created by subtracting WM and CSF probabilities maps form 1.
module load FSL/5.0.6
module load ANTS/2.1.0
for a in ????_FA.nii.gz 
do

fslmaths ${a} -bin ${a:0:4}_mask

Atropos -d 3 -a ${a} -x  ${a:0:4}_mask.nii.gz -c[5,1.e-5] -i Kmeans[2] -o [segmentation.nii.gz, ${a:0:4}_%02d.nii.gz]

fslmaths  ${a:0:4}_02 ${a:0:4}_WM_frac

fslmaths ${a:0:4}_mask -mul ${out_dir}/ODI/${a:0:4}.nii ${out_dir}/ODI/${a:0:4}_m.nii
fslmaths ${a:0:4}_mask -mul ${out_dir}/fIC/${a:0:4}.nii ${out_dir}/fIC/${a:0:4}_m.nii

fslmaths ${a:0:4}_WM_frac -add ../../CSF/${a:0:4} -sub 1 -mul -1 -thr 0 -mul ${a:0:4}_mask  ${a:0:4}_GM_frac 

fslmaths ${a:0:4}_WM_frac -mul 2 ${a:0:4}_WM_con
fslmaths ${a:0:4}_GM_frac -mul 1 ${a:0:4}_GM_con
fslmaths ../../CSF/${a:0:4} -mul 0 -add ${a:0:4}_GM_con -add ${a:0:4}_WM_con ${a:0:4}_psuedoT1 #400

done

###############################################################
### PART 1.4.a: Creating Template/ Estimating Warp Fields  ####
###############################################################
#OPTION 1: Generates Template image

cd ${out_dir}/FA/FA
mkdir ../D1
cp ????_psuedoT1.nii.gz ../D1/
cd ../D1
buildtemplateparallel.sh  -d 3 -j 1 -o D1_ -n 0 -s MI -i 8 -m 30x50x20 -t GR -z /projects/arash/NODDI/NODDI-G/newPsych/FA/D1_template.nii.gz  *_psuedoT1.nii.gz
#buildtemplateparallel.sh -c 1 -j 1 -d 3 -o D1_ -n 0 -s MI -i 8 -m 30x50x20 -t GR -z /scratch/arash/NODDI_PD/GBSS/FA/D1_template.nii.gz  p0*.nii.gz
#buildtemplateparallel.sh  -c 0 -d 3 -j 1 -o D1_ -n 0 -s MI -i 8 -m 30x50x20 -t GR -z /scratch/arash/NODDI/allPsych/FA/D1_series/D1_template.nii.gz  *_psuedoT1.nii.gz

###############################################################
#### PART 1.4.b: Nonlinear Transformation to the Template  ####
###############################################################
#OPTION 2: Requires pre-estimated Template image

for a in *_psuedoT1.nii.gz
do
label=`imglob ${a}`

fsl_sub -N ANTS_${label} antsIntroduction.sh -d 3 -i ${a} -o ${label} -n 0 -s MI -m 30x50x20 -t GR -r /scratch/arash/NODDI/allPsych/FA/D1_series/D1_template.nii.gz  *_psuedoT1.nii.gz

done

###############################################################
######### PART 1.5: Applying Warp Fields to Images  ###########
###############################################################

module load ANTS
out_dir=/scratch/arash/NODDI/allPsych
cd ${out_dir}/FA/FA

D1_folder=FA/D1_intro #Warp field/Affine Transfrom Directory
ref=$out_dir/FA/D1/D1_template.nii.gz

for FAs in  *_FA.nii.gz
do
a=`echo ${FAs} |cut -f1 -d"_"` # No "_" is permitted in the subject IDs

 fsl_sub antsApplyTransforms -i ${a}_GM_frac.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_GM.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${a}_WM_frac.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_WM.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/fIC/${a}_m.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_fIC.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/ODI/${a}_m.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_ODI.nii.gz --float

 fsl_sub antsApplyTransforms -i  ${out_dir}/CSF/${a}.nii.gz -d 3 -e 0 -n BSpline -r ${ref} -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Warp.nii.gz -t ${out_dir}/${D1_folder}/*${a}_psuedoT1Affine.txt -o ${out_dir}/tmpspace/${a}_CSF.nii.gz --float

done
