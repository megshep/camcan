%% CamCAN DARTEL MNI normalisation + modulation + smoothing

% Load SPM and initialise it
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');

spm('defaults','FMRI');
spm_jobman('initcfg');


%% Get participant ID for the SLURM array
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

if isnan(SUB_ID)
    error('SLURM_ARRAY_TASK_ID not found');
end


%% Set directories
% Individual propagated c1 GM segmentations
data_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data';

% DARTEL template + participant flow fields
dartel_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/segmentation_avg_resampled_nii';


%% Find all participants
sub_struct = dir(fullfile(data_dir,'sub-*'));
sub_struct = sub_struct([sub_struct.isdir]);

sub_names = sort({sub_struct.name});

if isempty(sub_names)
    error('No participant directories found in %s', data_dir);
end

fprintf('Found %d participants\n', numel(sub_names));


%% Select participant for this SLURM job
if SUB_ID > numel(sub_names)
    error('SUB_ID %d exceeds number of participants (%d)', ...
        SUB_ID, numel(sub_names));
end

sub_name = sub_names{SUB_ID};

fprintf('\nProcessing participant: %s\n', sub_name);


%% Find all propagated c1 images for this participant
% Search across all sessions for this participant
c1_struct = dir(fullfile(data_dir,sub_name,'ses-*','anat','c1*.nii'));

c1_files = fullfile({c1_struct.folder},{c1_struct.name});
c1_files = sort(c1_files(:));


% Sanity check
if isempty(c1_files)
    error('No c1 images found for %s', sub_name);
end

fprintf('Found %d c1 images for %s:\n', numel(c1_files), sub_name);

for i = 1:numel(c1_files)
    fprintf('  %s\n', c1_files{i});
end


%% Find participant-specific DARTEL flow field
% Extract the participant ID from the folder name
participant_id = sub_name;

flow_struct = dir(fullfile(dartel_dir, ...
    ['u_c1avg_' participant_id '_*_Template.nii']));


% Sanity check
if isempty(flow_struct)
    error('No DARTEL flow field found for %s', participant_id);
elseif numel(flow_struct) > 1
    error('Multiple DARTEL flow fields found for %s', participant_id);
end

sub_flow = fullfile(flow_struct.folder,flow_struct.name);

fprintf('\nDARTEL flow field:\n');
fprintf('  %s\n', sub_flow);


%% DARTEL MNI normalisation
matlabbatch = [];

% Individual c1 images for this participant
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(1).images = ...
    c1_files;

% Participant-specific flow field
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(1).flowfield = ...
    {sub_flow};


%% DARTEL template
matlabbatch{1}.spm.tools.dartel.mni_norm.template = ...
    {template_file};


%% Normalisation settings
% Use default voxel size
matlabbatch{1}.spm.tools.dartel.mni_norm.vox = ...
    [NaN NaN NaN];

% Use default bounding box
matlabbatch{1}.spm.tools.dartel.mni_norm.bb = ...
    [NaN NaN NaN;
     NaN NaN NaN];

% Modulation ON
% Preserves local volume information after spatial normalisation
matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 1;

% 4 mm FWHM smoothing
matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = ...
    [4 4 4];


%% Run
fprintf('\nStarting DARTEL MNI normalisation, modulation and smoothing...\n');

spm_jobman('run',matlabbatch);

fprintf('\nFinished participant %s.\n', participant_id);
