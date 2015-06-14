
addpath( genpath('/usr/share/fsl/5.0/etc/matlab'));

%% Reading Files
clear all
seg=read_avw('T1w_acpc_dc_restore_brain_seg.nii.gz');
wm=read_avw('T1w_acpc_dc_restore_brain_pve_2.nii.gz');
gm=read_avw('T1w_acpc_dc_restore_brain_pve_1.nii.gz');
csf=read_avw('T1w_acpc_dc_restore_brain_pve_0.nii.gz');
t1t2=read_avw('T1toT2_acpc_dc_restore_brain.nii.gz');
lesion=read_avw('lesion_in_T1HCP.nii.gz');

corrected_T1T2=t1t2;
corrected=zeros(size(t1t2));

%% PVE Correction

gm_vox=find(seg==2); %limits the analyses to voxels with high GM PV 
[a b c]= ind2sub(size(seg),gm_vox);
mask=zeros(size(gm));

f=1;
for i=1:length(gm_vox)
   TS=5;%smallest half cube for local PVE correction

    if gm(a(i),b(i),c(i))<0.99
        brk=0;
        while brk==0
            xs=a(i)-TS:a(i)+TS;
            ys=b(i)-TS:b(i)+TS;
            zs=c(i)-TS:c(i)+TS;
            [X,Y,Z] = meshgrid(xs,ys,zs);
             
            f=f+1;
            for j=1:length(X(:))
        
                wm_s(j)= wm(X(j),Y(j),Z(j));
                gm_s(j)= gm(X(j),Y(j),Z(j));
                csf_s(j)=csf (X(j),Y(j),Z(j));
                t1t2_s(j)= t1t2(X(j),Y(j),Z(j));
                mask_s(j)= mask(X(j),Y(j),Z(j));
            end
            
            data=[wm_s;gm_s;csf_s;t1t2_s;mask_s];
            
            %Setting criteria for input voxels    
            
            data1=data(:,find(data(5,:)==0 ...
            & data(4,:) >0 ...
            & data(4,:) <5  ...
            & (data(1,:)+data(2,:))>0 ...
            & not (data(4,:)>2.5 & data(1,:)<0.1)));
            c_wm=length(data1(1,find(data1(1,:)>0.5)));
            c_gm=length(data1(1,find(data1(2,:)>0.5)));
            c_csf=length(data1(1,find(data1(3,:)>0.5)));
            min_size=size(data1,2);
            
            if c_wm >=5 & c_gm >=5 & c_csf >=5
                bs=regress(data1(4,:)',data1(1:3,:)');
                corrected_T1T2(a(i),b(i),c(i))=bs(2);
                corrected(a(i),b(i),c(i))=1;
                brk=1;
                
            else
        
                TS=TS+1;
        
            end
         clear X Y Z xs ys zs data data1 wm_s gm_s t1t2_s csf_s mask_s

        end
    end
    
end

save_avw(corrected_T1T2,'corrected_T1T2.nii.gz','d',[1 1 1 1]);
save_avw(corrected,'corrected_mask.nii.gz','d',[1 1 1 1]);
