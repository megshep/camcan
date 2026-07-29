%% Get SLURM job array index
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% BIDS directory
bids_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data/';

%% Get participant folders
participants = dir(fullfile(bids_dir, 'sub-*'));
participants = participants([participants.isdir]);

% Sort participant folders
participants = sort({participants.name});

%% Select participant based on SLURM ID
participant = participants{SUB_ID};

%%important when using CSF to see what is happening behind the curtain
fprintf('Processing %s\n', participant);

%% Find all T1w scans for this participant (need this to be all because some have 3 and some have 2)
t1_files = dir(fullfile(bids_dir, participant, '**', '*_T1w.nii.gz'));

% Convert to full file paths
this_files = cell(length(t1_files),1);

for i = 1:length(t1_files)
    this_files{i} = fullfile(t1_files(i).folder, t1_files(i).name);
end

%% Again, tells me what's behind the curtain
fprintf('Found %d T1 scans\n', length(this_files));


%% Assign scans to SPM batch
matlabbatch{1}.spm.spatial.preproc.channel.vols = this_files;

% Batch options
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];

% Tissue probability maps
tpm_path = '/mnt/iusers01/nm01/j90161ms/spm25/tpm/TPM.nii';

for i = 1:6
    matlabbatch{1}.spm.spatial.preproc.tissue(i).tpm = {[tpm_path ',' num2str(i)]};
end

% Tissue settings

% Grey matter
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];

% White matter
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];

% CSF
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];

% Bone
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];

% Soft tissue
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];

% Air/background
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];


% Warp settings
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN];


%% Run segmentation
spm_jobman('run', matlabbatch);
