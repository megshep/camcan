%% Initialise SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('defaults','FMRI');
spm_jobman('initcfg');

%% Define propagated native-space GM and WM directories
% These are the segmentations propagated back from the longitudinal
% average images into native scan space
prop_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/propagated';

%% Find propagated GM and WM images
% pc1avg = propagated GM
% pc2avg = propagated WM
%
% Recursive search is required because files are stored as:
% propagated/
%   sub-CCXXXXX/
%	ses-P2/
%           pc1avg_sub-CCXXXXX_ses-P2_T1w.nii


gm_struct = dir(fullfile(prop_dir,'**','pc1avg*.nii'));
wm_struct = dir(fullfile(prop_dir,'**','pc2avg*.nii'));


gm = fullfile({gm_struct.folder},{gm_struct.name});
wm = fullfile({wm_struct.folder},{wm_struct.name});


% Sort to maintain GM/WM pairing
gm = sort(gm);
wm = sort(wm);


%% Sanity checks
if isempty(gm) || isempty(wm)
    error('No propagated GM or WM images found - check directory');
end

if numel(gm) ~= numel(wm)
    error('GM (%d) and WM (%d) counts do not match', numel(gm), numel(wm));
end


fprintf('Found %d propagated scans\n', numel(gm));


%% Check GM/WM pairing
fprintf('\nChecking GM/WM pairing:\n')

for i = 1:min(5,numel(gm))

    [~,gm_name,~] = fileparts(gm{i});
    [~,wm_name,~] = fileparts(wm{i});

    fprintf('%s\n', gm_name);
    fprintf('%s\n\n', wm_name);

end

%% Add volume index (required by SPM)
gm = strcat(gm, ',1');
wm = strcat(wm, ',1');


% Convert to column vectors (SPM requirement)
gm = gm(:);
wm = wm(:);


%% DARTEL template creation

matlabbatch = [];

matlabbatch{1}.spm.tools.dartel.warp.images = {
    gm
    wm
};


% Template name
matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';


% No affine registration
matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;


%% Standard DARTEL parameters

params = [
    3 4    2	  1e-6 0 16
    3 2    1	  1e-6 0 8
    3 1    0.5    1e-6 1 4
    3 0.5  0.25   1e-6 2 2
    3 0.25 0.125  1e-6 4 1
    3 0.25 0.125  1e-6 6 0.5
];


for i = 1:6

    matlabbatch{1}.spm.tools.dartel.warp.settings.param(i).its = params(i,1);

    matlabbatch{1}.spm.tools.dartel.warp.settings.param(i).rparam = ...
        params(i,2:4);

    matlabbatch{1}.spm.tools.dartel.warp.settings.param(i).K = ...
        params(i,5);

    matlabbatch{1}.spm.tools.dartel.warp.settings.param(i).slam = ...
        params(i,6);

end

%% Optimisation settings

matlabbatch{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
matlabbatch{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.optim.its = 3;


%% Run DARTEL

disp('Starting CamCAN DARTEL template creation...');

spm_jobman('run',matlabbatch);


disp('DARTEL template creation complete!');

