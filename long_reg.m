%% Get SLURM task ID
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% Load SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('Defaults','fMRI');
spm_jobman('initcfg');

%% Directories
bids_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data/';
out_dir  = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/long_reg/';

%% Read participant table
T = readtable('/mnt/iusers01/nm01/j90161ms/camcan/data/participants.tsv', ...
    'FileType','text','Delimiter','\t');

%% Select participant
participant = T.participant_id{SUB_ID};

%% See behind the curtain
fprintf('Processing %s\n', participant);

% Find available raw T1 scans only

sessions = {'ses-P2','ses-P3','ses-P5'};

vols = {};
times = [];

for i = 1:length(sessions)

    % Only select original raw T1 images
    scan = dir(fullfile(bids_dir, participant, sessions{i}, 'anat', 'sub-*_T1w.nii'));

    if ~isempty(scan)

        fprintf('Using scan: %s\n', scan.name);

        vols{end+1,1} = [fullfile(scan.folder, scan.name) ',1'];

        if strcmp(sessions{i},'ses-P2')
            times(end+1,1) = T.p2_mri_age(SUB_ID);

        elseif strcmp(sessions{i},'ses-P3')
            times(end+1,1) = T.p3_mri_age(SUB_ID);

        elseif strcmp(sessions{i},'ses-P5')
            times(end+1,1) = T.p5_mri_age(SUB_ID);
        end

    end

end

%% See behind the curtain
fprintf('Found %d T1 scans\n', length(vols));

% Longitudinal registration batch

matlabbatch{1}.spm.tools.longit.series.vols  = vols;
matlabbatch{1}.spm.tools.longit.series.times = times;

matlabbatch{1}.spm.tools.longit.series.noise = NaN;

matlabbatch{1}.spm.tools.longit.series.wparam = [0 0 100 25 100];
matlabbatch{1}.spm.tools.longit.series.bparam = 1000000;

% Write outputs
matlabbatch{1}.spm.tools.longit.series.write_avg = 1;
matlabbatch{1}.spm.tools.longit.series.write_jac = 1;
matlabbatch{1}.spm.tools.longit.series.write_def = 1;

spm_jobman('run',matlabbatch);

fprintf('Finished %s\n', participant);
