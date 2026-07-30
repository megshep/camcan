%% Get SLURM job array index
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% Load SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('Defaults','fMRI');
spm_jobman('initcfg');


%% Directories
data_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data/';
seg_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/long_reg/';
out_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/propagated/';


%% Read participants
T = readtable('/mnt/iusers01/nm01/j90161ms/camcan/data/participants.tsv', ...
    'FileType','text','Delimiter','\t');

%% Select participant
participant = T.participant_id{SUB_ID};
fprintf('\nProcessing %s\n', participant);


%% Find average segmentations
avg_gm = dir(fullfile(seg_dir, ['c1avg_' participant '*.nii']));
avg_wm = dir(fullfile(seg_dir, ['c2avg_' participant '*.nii']));
avg_csf = dir(fullfile(seg_dir, ['c3avg_' participant '*.nii']));

if isempty(avg_gm)
    error('No average segmentations found for %s', participant);
end

fprintf('Found average segmentations\n');

%% Find deformation fields for this participant
y_files = dir(fullfile(data_dir, participant, '**', ...
    ['y_' participant '*.nii']));

if isempty(y_files)
    error('No deformation fields found for %s', participant);
end

%% Create output folder
if ~exist(out_dir,'dir')
    mkdir(out_dir)
end

%% Loop through all visits
for i = 1:length(y_files)

    clear matlabbatch

    y_path = fullfile(y_files(i).folder,y_files(i).name);

    fprintf('\nApplying deformation %d/%d\n', i, length(y_files));
    fprintf('Using deformation:\n%s\n', y_path);
    
    % Pull back average segmentation into native space
    matlabbatch{1}.spm.util.defs.comp{1}.def = {y_path};
    matlabbatch{1}.spm.util.defs.out{1}.pull.fnames = {
        fullfile(avg_gm(1).folder, avg_gm(1).name)
        fullfile(avg_wm(1).folder, avg_wm(1).name)
        fullfile(avg_csf(1).folder, avg_csf(1).name)
        };
    matlabbatch{1}.spm.util.defs.out{1}.pull.savedir.saveusr = {out_dir};

    % interpolation
    matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 4;
    % masking
    matlabbatch{1}.spm.util.defs.out{1}.pull.mask = 1;
    % smoothing
    matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
    % prefix
    matlabbatch{1}.spm.util.defs.out{1}.pull.prefix = 'p';
    %% Run
    spm_jobman('run',matlabbatch);

    fprintf('Finished %s\n', y_files(i).name);
end

fprintf('\nFinished all visits for %s\n', participant);
