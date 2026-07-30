%% Add SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('Defaults','fMRI');
spm_jobman('initcfg');

%% SLURM index
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% Directories
prop_dir = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/propagated/';
if ~exist(prop_dir,'dir')
    mkdir(prop_dir)
end

%% Read participants
T = readtable('/mnt/iusers01/nm01/j90161ms/camcan/data/participants.tsv', ...
    'FileType','text','Delimiter','\t');

participant = T.participant_id{SUB_ID};
fprintf('\nProcessing %s\n', participant);

%% Find average segmentations
avg_files = dir(fullfile(...
    '/mnt/iusers01/nm01/j90161ms/camcan/output_files/long_reg/',...
    sprintf('c[123]avg_%s*.nii',participant)));

if isempty(avg_files)
    error('No average segmentations found for %s',participant)
end

fprintf('Found average segmentations\n');

%% Find all visits for this participant
anat_dir = fullfile(...
    '/mnt/iusers01/nm01/j90161ms/camcan/data/',...
    participant,...
    'ses-*',...
    'anat');

y_files = dir(fullfile(anat_dir,'y_*.nii'));

if isempty(y_files)
    error('No deformation fields found for %s',participant)
end

%% Loop over deformation fields
for d = 1:length(y_files)
    y_path = fullfile(y_files(d).folder,y_files(d).name);

    % identify visit
    visit_match = regexp(y_files(d).name,'ses-P\d+','match');

    if isempty(visit_match)
        warning('Could not identify visit for %s',y_files(d).name)
        continue
    end

    visit = visit_match{1};

    fprintf('\nApplying deformation for %s\n',visit);
    fprintf('Using deformation:\n%s\n',y_path);

    %% Build SPM deformation job
    clear matlabbatch
    matlabbatch{1}.spm.util.defs.comp{1}.def = {y_path};

    % apply to propagated average tissue maps
    input_files = cell(3,1);
    input_files{1} = fullfile(...
        avg_files(1).folder,...
        sprintf('c1avg_%s_ses-P2_T1w.nii',participant));
    input_files{2} = fullfile(...
        avg_files(1).folder,...
        sprintf('c2avg_%s_ses-P2_T1w.nii',participant));
    input_files{3} = fullfile(...
        avg_files(1).folder,...
        sprintf('c3avg_%s_ses-P2_T1w.nii',participant));

    matlabbatch{1}.spm.util.defs.out{1}.pull.fnames = input_files;
    matlabbatch{1}.spm.util.defs.out{1}.pull.savedir.saveusr = {prop_dir};
    matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 4;
    matlabbatch{1}.spm.util.defs.out{1}.pull.mask = 1;
    matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
    % temporary prefix
    matlabbatch{1}.spm.util.defs.out{1}.pull.prefix = 'p';

    %% Run pullback
    spm_jobman('run',matlabbatch);
    %% Rename outputs to preserve visit

    for tissue = 1:3
        old_file = fullfile(prop_dir,...
            sprintf('pc%davg_%s_ses-P2_T1w.nii',...
            tissue,participant));

        new_file = fullfile(prop_dir,...
            sprintf('pc%davg_%s_%s_T1w.nii',...
            tissue,participant,visit));

        if exist(old_file,'file')
            movefile(old_file,new_file);
            fprintf('Saved:\n%s\n',new_file)
        else
        warning('Missing output %s',old_file)
        end
    end
end

fprintf('\nFinished %s\n',participant);
