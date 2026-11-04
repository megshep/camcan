
%% Initialise SPM

addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('defaults','FMRI');
spm_jobman('initcfg');


%% Define directories

data_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data/';

final_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/final_dartel/';

if ~exist(final_dir,'dir')
    mkdir(final_dir);
end


%% Find individual DARTEL-imported GM images

% rc1 = GM
% rc2 = WM

gm_struct = spm_select('FPListRec', data_dir, ...
    '^rc1sub-.*_T1w\.nii$');

gm_source = cellstr(gm_struct);
gm_source = strtrim(gm_source);
gm_source = gm_source(~cellfun('isempty',gm_source));

gm_source = sort(gm_source);


%% Match each GM image to its WM image

gm = {};
wm = {};

for i = 1:numel(gm_source)

    gm_file = gm_source{i};

    wm_file = regexprep(gm_file, 'rc1sub-', 'rc2sub-');

    if ~exist(wm_file,'file')
        error('Matching WM image not found for: %s', gm_file);
    end

    % Copy images into final_dartel
    [~,gm_name,gm_ext] = fileparts(gm_file);
    [~,wm_name,wm_ext] = fileparts(wm_file);

    gm_dest = fullfile(final_dir,[gm_name gm_ext]);
    wm_dest = fullfile(final_dir,[wm_name wm_ext]);

    copyfile(gm_file,gm_dest,'f');
    copyfile(wm_file,wm_dest,'f');

    gm{end+1,1} = gm_dest;
    wm{end+1,1} = wm_dest;

end


%% Sanity checks

if isempty(gm) || isempty(wm)
    error('No DARTEL-imported GM or WM images found.');
end

if numel(gm) ~= numel(wm)
    error('GM and WM counts do not match.');
end

fprintf('Found %d individual session scans.\n',numel(gm));


%% Check GM/WM pairing

fprintf('\nChecking GM/WM pairing:\n');

for i = 1:min(5,numel(gm))

    [~,gm_name,~] = fileparts(gm{i});
    [~,wm_name,~] = fileparts(wm{i});

    fprintf('%s\n',gm_name);
    fprintf('%s\n\n',wm_name);

end


%% Add volume index

gm = strcat(gm,',1');
wm = strcat(wm,',1');

gm = gm(:);
wm = wm(:);


%% DARTEL template creation

matlabbatch = [];

matlabbatch{1}.spm.tools.dartel.warp.images = {
    gm
    wm
};

matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';

matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;


%% Standard DARTEL parameters

params = [
    3 4    2      1e-6 0 16
    3 2    1      1e-6 0 8
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

disp('Starting DARTEL population template creation from individual segmentations...');

spm_jobman('run',matlabbatch);

disp('DARTEL population template creation complete!');
disp(['Outputs saved in: ' final_dir]);
