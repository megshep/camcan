%% Load SPM and initialise it
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('defaults','FMRI');
spm_jobman('initcfg');

%% Get participant index from the SLURM array
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));
if isnan(SUB_ID)
    error('SLURM_ARRAY_TASK_ID not found');
end

%% Set directories
data_dir   = '/mnt/iusers01/nm01/j90161ms/camcan_final/data';
dartel_dir = '/mnt/iusers01/nm01/j90161ms/camcan_final/output_files/dartel';

%% Find final DARTEL template
template_file = fullfile(dartel_dir, 'Template_6.nii');
if ~exist(template_file, 'file')
    error('DARTEL template not found: %s', template_file);
end
fprintf('Using DARTEL template:\n  %s\n', template_file);

%% Find all participants
sub_struct = dir(fullfile(data_dir, 'sub-*'));
sub_struct = sub_struct([sub_struct.isdir]);
sub_names  = sort({sub_struct.name});

if isempty(sub_names)
    error('No participant directories found in %s', data_dir);
end
fprintf('Found %d participants\n', numel(sub_names));

%% Select participant for this SLURM job
if SUB_ID < 1 || SUB_ID > numel(sub_names)
    error('SUB_ID %d is outside the participant range (1-%d)', SUB_ID, numel(sub_names));
end
sub_name = sub_names{SUB_ID};
fprintf('\nProcessing participant: %s\n', sub_name);

%% Find c1 GM images for this participant (all sessions)
c1_struct = dir(fullfile(data_dir, sub_name, 'ses-*', 'anat', 'c1*.nii'));
if isempty(c1_struct)
    error('No c1 images found for %s', sub_name);
end

c1_files = fullfile({c1_struct.folder}, {c1_struct.name});
c1_files = sort(c1_files(:));          % Nx1 cell, fixed order

fprintf('\nFound %d c1 images for %s:\n', numel(c1_files), sub_name);

%% Build matching flow-field list IN THE SAME ORDER
flow_files = cell(numel(c1_files), 1);

for i = 1:numel(c1_files)
    [~, c1_name, ~] = fileparts(c1_files{i});

    % c1sub-CC120065_ses-P2_T1w  ->  u_rc1sub-CC120065_ses-P2_T1w_Template.nii
    flow_name = [regexprep(c1_name, '^c1', 'u_rc1') '_Template.nii'];
    flow_file = fullfile(dartel_dir, flow_name);

    if ~exist(flow_file, 'file')
        error('DARTEL flow field not found:\n%s', flow_file);
    end
    flow_files{i} = flow_file;

    fprintf('\nPair %d:\n  GM image:   %s\n  Flow field: %s\n', i, c1_files{i}, flow_files{i});
end

%% DARTEL "Normalise to MNI Space": MANY SUBJECTS
% Flow fields and images are parallel lists, matched one-to-one by order.
matlabbatch = [];

matlabbatch{1}.spm.tools.dartel.mni_norm.template = {template_file};

matlabbatch{1}.spm.tools.dartel.mni_norm.data.subjs.flowfields = flow_files;     % Nx1 cell
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subjs.images     = {c1_files};     % 1x1 cell containing the Nx1 cell

%% Settings
matlabbatch{1}.spm.tools.dartel.mni_norm.vox      = [NaN NaN NaN];            % template voxel size
matlabbatch{1}.spm.tools.dartel.mni_norm.bb       = [NaN NaN NaN; NaN NaN NaN]; % default bounding box
matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 1;                        % modulated (preserve amount)
matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm     = [4 4 4];                  % 4 mm smoothing

%% Run
fprintf('\nStarting DARTEL MNI normalisation, modulation and smoothing...\n');
spm_jobman('run', matlabbatch);
fprintf('\nFinished participant %s.\n', sub_name);
