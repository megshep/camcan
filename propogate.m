%% Add SPM
addpath('/mnt/iusers01/nm01/j90161ms/scratch/spm25');
spm('Defaults','fMRI');
spm_jobman('initcfg');

%% SLURM participant index
SUB_ID = str2double(getenv('SLURM_ARRAY_TASK_ID'));

%% Directories
long_dir  = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/long_reg/';
data_dir  = '/mnt/iusers01/nm01/j90161ms/camcan/data/';
prop_root = '/mnt/iusers01/nm01/j90161ms/camcan/output_files/propagated/';

%% Read participant list
T = readtable( ...
    fullfile(data_dir,'participants.tsv'), ...
    'FileType','text', ...
    'Delimiter','\t');

participant = T.participant_id{SUB_ID};

fprintf('\n=====================================\n');
fprintf('Processing %s\n',participant);
fprintf('=====================================\n');

gm_file = fullfile(long_dir,...
    sprintf('c1avg_%s_ses-P2_T1w.nii',participant));

wm_file = fullfile(long_dir,...
    sprintf('c2avg_%s_ses-P2_T1w.nii',participant));

csf_file = fullfile(long_dir,...
    sprintf('c3avg_%s_ses-P2_T1w.nii',participant));

if ~exist(gm_file,'file')
    error('Cannot find %s',gm_file);
end

if ~exist(wm_file,'file')
    error('Cannot find %s',wm_file);
end

if ~exist(csf_file,'file')
    error('Cannot find %s',csf_file);
end

fprintf('Found midpoint GM/WM/CSF\n');

% Find deformation fields
y_files = dir(fullfile( ...
    data_dir,...
    participant,...
    'ses-*',...
    'anat',...
    'y_*.nii'));

if isempty(y_files)
    error('No deformation fields found for %s',participant);
end

fprintf('Found %d deformation field(s)\n',length(y_files));

% Loop over all visits
for d = 1:length(y_files)

    y_path = fullfile(y_files(d).folder,y_files(d).name);
    visit = regexp(y_files(d).name,'ses-P\d+','match','once');

    fprintf('\n-------------------------------------\n');
    fprintf('Applying deformation for %s\n',visit);
    fprintf('Using deformation:\n%s\n',y_path);
    fprintf('-------------------------------------\n');

    %% Output directory
    visit_dir = fullfile(prop_root,participant,visit);

    if ~exist(visit_dir,'dir')
        mkdir(visit_dir);
    end

    %% Input images
    input_files = {
        gm_file
        wm_file
        csf_file
        };

    %% Build SPM batch
    clear matlabbatch
    matlabbatch{1}.spm.util.defs.comp{1}.def = {y_path};
    matlabbatch{1}.spm.util.defs.out{1}.pull.fnames = input_files;
    matlabbatch{1}.spm.util.defs.out{1}.pull.savedir.saveusr = {visit_dir};
    matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 4;
    matlabbatch{1}.spm.util.defs.out{1}.pull.mask = 1;
    matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
    matlabbatch{1}.spm.util.defs.out{1}.pull.prefix = 'p';

    %% Run deformation

    spm_jobman('run',matlabbatch);

    % Rename outputs to reflect visit

    for tissue = 1:3
        old_file = fullfile( ...
            visit_dir,...
            sprintf('pc%davg_%s_ses-P2_T1w.nii', ...
            tissue,participant));

        new_file = fullfile( ...
            visit_dir,...
            sprintf('pc%davg_%s_%s_T1w.nii', ...
            tissue,participant,visit));

        if exist(old_file,'file')

            % Only rename if needed
            if ~strcmp(old_file,new_file)
                movefile(old_file,new_file);
            end

            fprintf('✓ %s\n',new_file);

        else

            warning('Expected output missing:\n%s',old_file);

        end

    end

end

fprintf('\n=====================================\n');
fprintf('Finished %s\n',participant);
fprintf('=====================================\n');
