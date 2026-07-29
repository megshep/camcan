!/bin/bash
#SBATCH --job-name=longreg_camcan
#SBATCH --output=/mnt/iusers01/nm01/j90161ms/camcan/long_reg/logs/longreg_camcan_%A_%a.out
#SBATCH --error=/mnt/iusers01/nm01/j90161ms/camcan/long_reg/logs/longreg_camcan_%A_%a.err
#SBATCH --array=1-139%50
#SBATCH --time=24:00:00
#SBATCH --mem=20G
#SBATCH --cpus-per-task=1

# Load MATLAB
module load apps/binapps/matlab/R2024b

# Set SPM path
export USER_SPM_DIR="/mnt/iusers01/nm01/j90161ms/scratch/spm25"

# Run from submission directory
cd "$SLURM_SUBMIT_DIR"

SUB_ID=$SLURM_ARRAY_TASK_ID

# Run MATLAB script
matlab -nodisplay -nosplash -batch "try; addpath(getenv('USER_SPM_DIR')); run('/mnt/iusers01/nm01/j90161ms/camcan/long_reg/long_reg.m'); catch ME; fprintf(2,'Error: %s\n',ME.message); disp(getReport(ME,'extended')); end; exit"

