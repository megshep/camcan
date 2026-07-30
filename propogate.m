%% Propagate longitudinal average segmentations back to each time point
% Uses SPM25 Deformations -> Pullback
% Applies y_ deformation fields to c1/c2/c3 average segmentations

%% Get SLURM job array index
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% Load SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('Defaults','fMRI');
spm_jobman('initcfg');


%% Directories
bids_dir = '/mnt/iusers01/nm01/j90161ms/camcan/data/';
avg_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/long_reg/';
out_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/propagated/';

%% Read participants

T = readtable('/mnt/iusers01/nm01/j90161ms/camcan/data/participants.tsv',...
    'FileType','text',...
    'Delimiter','\t');

%% Select participant

participant = T.participant_id{SUB_ID};
fprintf('\nProcessing %s\n',participant);

%% Find average segmentations
c1_file = dir(fullfile(avg_dir,['c1avg_' participant '*.nii']));
c2_file = dir(fullfile(avg_dir,['c2avg_' participant '*.nii']));
c3_file = dir(fullfile(avg_dir,['c3avg_' participant '*.nii']));


if isempty(c1_file) || isempty(c2_file) || isempty(c3_file)
    error('Missing average segmentation for %s',participant)
end


c1 = fullfile(c1_file(1).folder,c1_file(1).name);
c2 = fullfile(c2_file(1).folder,c2_file(1).name);
c3 = fullfile(c3_file(1).folder,c3_file(1).name);
fprintf('Found average segmentations\n');

%% Store tissue images
tissue_files = {
    c1
    c2
    c3
    };

%% Sessions
sessions = {'P2','P3','P5'};



%% Loop through timepoints
for s = 1:length(sessions)
    ses = sessions{s};
    fprintf('\nApplying deformation for %s\n',ses);


    %% Find deformation field
    y_file = dir(fullfile(bids_dir,...
        participant,...
        ['ses-' ses],...
        'anat',...
        'y_*.nii'));

    if isempty(y_file)
        error('No deformation field found for %s %s',participant,ses)
    end

    y_path = fullfile(y_file(1).folder,y_file(1).name);
    fprintf('Using deformation:\n%s\n',y_path);


    %% Clear previous batch
    matlabbatch = {};

    %% Apply deformation (SPM25 Pullback)
    matlabbatch{1}.spm.util.defs.comp{1}.def = {y_path};


    %% Images to transform
matlabbatch{1}.spm.util.defs.out{1}.pull.fnames = {
        tissue_files{1}
        tissue_files{2}
        tissue_files{3}
        };

    %% Output directory
matlabbatch{1}.spm.util.defs.out{1}.pull.savedir.saveusr = {out_dir};

    %% Same settings as GUI
matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 4;
matlabbatch{1}.spm.util.defs.out{1}.pull.mask = 1;
matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
matlabbatch{1}.spm.util.defs.out{1}.pull.prefix = 'p';

    %% Run
    spm_jobman('run',matlabbatch);
    fprintf('Finished %s %s\n',participant,ses);

end


fprintf('\nFinished participant %s\n',participant);
