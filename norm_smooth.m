%% Load SPM and initialise it
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');

spm('defaults','FMRI');
spm_jobman('initcfg');


%% Get participant ID for the SLURM array
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

if isnan(SUB_ID)
    error('SLURM_ARRAY_TASK_ID not found');
end


%% Set directories
data_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data';

% Directory containing population-specific DARTEL template and flow fields
dartel_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/final_dartel';


%% Find final DARTEL template
template_file = fullfile(dartel_dir, 'Template_6.nii');

if ~exist(template_file, 'file')
    error('DARTEL template not found: %s', template_file);
end

fprintf('Using DARTEL template:\n  %s\n', template_file);


%% Find all participants
sub_struct = dir(fullfile(data_dir, 'sub-*'));
sub_struct = sub_struct([sub_struct.isdir]);

sub_names = sort({sub_struct.name});

if isempty(sub_names)
    error('No participant directories found in %s', data_dir);
end

fprintf('Found %d participants\n', numel(sub_names));


%% Select participant for this SLURM job
if SUB_ID < 1 || SUB_ID > numel(sub_names)
    error('SUB_ID %d is outside the participant range (1-%d)', ...
        SUB_ID, numel(sub_names));
end

sub_name = sub_names{SUB_ID};

fprintf('\nProcessing participant: %s\n', sub_name);


%% Find individual c1 GM images for this participant
% Search across all available sessions
c1_struct = dir(fullfile(data_dir, sub_name, ...
    'ses-*', 'anat', 'c1*.nii'));

if isempty(c1_struct)
    error('No c1 images found for %s', sub_name);
end

c1_files = fullfile({c1_struct.folder}, {c1_struct.name});
c1_files = sort(c1_files(:));

fprintf('\nFound %d c1 images for %s:\n', ...
    numel(c1_files), sub_name);

for i = 1:numel(c1_files)
    fprintf('  %s\n', c1_files{i});
end


%% Find the corresponding DARTEL flow field for each session
flow_files = cell(numel(c1_files), 1);

for i = 1:numel(c1_files)

    [~, c1_name, ~] = fileparts(c1_files{i});

    % Convert the c1 filename into the corresponding flow-field filename.
    %
    % Example:
    % c1sub-CC120065_ses-P2_T1w.nii
    %
    % becomes:
    % u_rc1sub-CC120065_ses-P2_T1w_Template.nii

    flow_name = regexprep(c1_name, '^c1', 'u_rc1');
    flow_name = [flow_name '_Template.nii'];

    flow_file = fullfile(dartel_dir, flow_name);

    if ~exist(flow_file, 'file')
        error('DARTEL flow field not found:\n%s', flow_file);
    end

    flow_files{i} = flow_file;

    fprintf('\nMatched session %d:\n', i);
    fprintf('  GM image:   %s\n', c1_files{i});
    fprintf('  Flow field: %s\n', flow_files{i});

end


%% DARTEL MNI normalisation
matlabbatch = [];

% Individual GM images for this participant
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(1).images = ...
    c1_files;

% Corresponding individual flow fields
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(1).flowfield = ...
    flow_files;

% Final population-specific DARTEL template
matlabbatch{1}.spm.tools.dartel.mni_norm.template = ...
    {template_file};


%% Normalisation settings

% Default voxel size
matlabbatch{1}.spm.tools.dartel.mni_norm.vox = ...
    [NaN NaN NaN];

% Default bounding box
matlabbatch{1}.spm.tools.dartel.mni_norm.bb = ...
    [NaN NaN NaN;
     NaN NaN NaN];

% Modulation ON
% Preserves local volume information after spatial normalisation
matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 1;

% Smoothing: 4 mm FWHM
matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = ...
    [4 4 4];


%% Run normalisation and smoothing
fprintf('\nStarting DARTEL MNI normalisation, modulation and smoothing...\n');

spm_jobman('run', matlabbatch);

fprintf('\nFinished participant %s.\n', sub_name);

