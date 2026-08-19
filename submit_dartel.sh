#!/bin/bash 
#SBATCH --job-name=dartel_template 
#SBATCH --output=/mnt/iusers01/nm01/j90161ms/camcan/dartel_logs/dartel_%j.out 
#SBATCH --error=/mnt/iusers01/nm01/j90161ms/camcan/dartel_logs/dartel_%j.err 
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=24 
#SBATCH --mem=32G 
#SBATCH --time=5-00:00:00 
#SBATCH --partition=himem 

# Load MATLAB 
module load apps/binapps/matlab/R2024b 

# Path to SPM installation export 
USER_SPM_DIR="/mnt/iusers01/nm01/j90161ms/scratch/spm25" 

# Change to the directory where you submitted the job 
cd "$SLURM_SUBMIT_DIR" 

# Run MATLAB non-interactively, calling the dartel template script 
matlab -nodisplay -nosplash -batch "try; addpath(getenv('USER_SPM_DIR')); run('/mnt/iusers01/nm01/j90161ms/trajectory/dartel.m'); catch ME; disp(getReport(ME)); exit(1); end; exit(0);"




