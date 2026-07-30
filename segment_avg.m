%% Get SLURM job array index
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% Load SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('Defaults','fMRI');
spm_jobman('initcfg');

%% Directory containing longitudinal average images
long_reg_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/long_reg/';

%% Read participants
T = readtable('/mnt/iusers01/nm01/j90161ms/camcan/data/participants.tsv', ...
    'FileType','text','Delimiter','\t');

%% Select participant
participant = T.participant_id{SUB_ID};

fprintf('Processing %s\n', participant);

%% Find longitudinal average image
avg_file = dir(fullfile(long_reg_dir, ['avg_' participant '*.nii']));

if isempty(avg_file)
    error('No average image found for %s', participant);
end

avg_path = fullfile(avg_file(1).folder, avg_file(1).name);

fprintf('Using average image:\n%s\n', avg_path);

%% --------------------------------------------------------------------
%% SEGMENT AVERAGE IMAGE
%% --------------------------------------------------------------------

matlabbatch{1}.spm.spatial.preproc.channel.vols = {[avg_path ',1']};

matlabbatch{1}.spm.spatial.preproc.channel.biasreg  = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write    = [0 0];

%% Tissue probability maps
tpm_path = '/mnt/iusers01/nm01/j90161ms/scratch/spm25/tpm/TPM.nii';

for i = 1:6
    matlabbatch{1}.spm.spatial.preproc.tissue(i).tpm = ...
        {[tpm_path ',' num2str(i)]};
end

%% Grey matter
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus  = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];

%% White matter
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus  = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];

%% CSF
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus  = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];

%% Bone
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus  = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];

%% Soft tissue
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus  = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];

%% Air/background
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus  = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];

%% Warp settings
matlabbatch{1}.spm.spatial.preproc.warp.mrf     = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg     = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg  = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm    = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp    = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write   = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.vox     = NaN;
matlabbatch{1}.spm.spatial.preproc.warp.bb      = [NaN NaN NaN;
                                                    NaN NaN NaN];

%% Run segmentation
spm_jobman('run', matlabbatch);

fprintf('Finished %s\n', participant);
