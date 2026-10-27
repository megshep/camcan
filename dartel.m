%% Initialise SPM

addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('defaults','FMRI');
spm_jobman('initcfg');


%% Define directories

data_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/propagated';

% Separate directory for the new individual-session DARTEL template
out_dir = '/mnt/iusers01/nm01/j90161ms/camcan/dartel_individual_sessions';

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

cd(out_dir);


%% Find propagated individual-session GM and WM images

% pc1 = propagated grey matter
% pc2 = propagated white matter

gm_struct = dir(fullfile(data_dir, '**', 'pc1*.nii'));
wm_struct = dir(fullfile(data_dir, '**', 'pc2*.nii'));

gm_paths = fullfile({gm_struct.folder}, {gm_struct.name});
wm_paths = fullfile({wm_struct.folder}, {wm_struct.name});

gm_paths = gm_paths(:);
wm_paths = wm_paths(:);


%% Check that matching GM and WM images exist

if isempty(gm_paths) || isempty(wm_paths)
    error('No pc1 or pc2 images found. Check the propagated directory.');
end

% Extract participant/session identifiers from each filename and path
gm_keys = cell(size(gm_paths));
wm_keys = cell(size(wm_paths));

for i = 1:numel(gm_paths)
    gm_keys{i} = regexprep(gm_paths{i}, '^.*(sub-CC[^/]+/ses-P[^/]+/).*pc1', '$1pc');
end

for i = 1:numel(wm_paths)
    wm_keys{i} = regexprep(wm_paths{i}, '^.*(sub-CC[^/]+/ses-P[^/]+/).*pc2', '$1pc');
end

[gm_keys, gm_order] = sort(gm_keys);
[wm_keys, wm_order] = sort(wm_keys);

gm_paths = gm_paths(gm_order);
wm_paths = wm_paths(wm_order);

if numel(gm_paths) ~= numel(wm_paths)
    error('GM count (%d) and WM count (%d) differ.', ...
        numel(gm_paths), numel(wm_paths));
end

if ~isequal(gm_keys, wm_keys)
    error(['GM and WM files do not match by participant/session. ' ...
           'Check filenames before running DARTEL.']);
end

fprintf('Found %d matching individual-session GM/WM pairs.\n', ...
    numel(gm_paths));


%% Display first 10 pairs for verification

fprintf('\nFirst 10 GM/WM pairs:\n');

for i = 1:min(10, numel(gm_paths))
    fprintf('GM: %s\nWM: %s\n\n', gm_paths{i}, wm_paths{i});
end


%% Add volume index required by SPM

gm = strcat(gm_paths, ',1');
wm = strcat(wm_paths, ',1');


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
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(i).its = ...
        params(i,1);

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

fprintf('\nStarting DARTEL with individual-session segmentations...\n');
fprintf('Output directory: %s\n', out_dir);

spm_jobman('run', matlabbatch);

fprintf('\nDARTEL template creation complete!\n');
