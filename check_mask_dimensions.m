mask_file = 'N:\meg_proj\camcan_run2\mask\bilateral_amygdala.nii';   
img_file  = 'N:\meg_proj\camcan_run2\norm_smooth2\data\sub-CC120049\ses-P5\anat\smwc1sub-CC120049_ses-P5_T1w.nii';

Vm = spm_vol(mask_file);
Vi = spm_vol(img_file);

fprintf('Mask: dim = %s, voxel size = %s mm\n', mat2str(Vm.dim), mat2str(round(sqrt(sum(Vm.mat(1:3,1:3).^2)),3)));
fprintf('Img:  dim = %s, voxel size = %s mm\n', mat2str(Vi.dim), mat2str(round(sqrt(sum(Vi.mat(1:3,1:3).^2)),3)));

same_dim = isequal(Vm.dim, Vi.dim);
same_mat = max(abs(Vm.mat(:) - Vi.mat(:))) < 1e-3;
fprintf('Same dim: %d | Same affine: %d\n', same_dim, same_mat);
