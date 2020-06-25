#!/bin/bash
#SBATCH -J jupyter
#SBATCH --partition LONG
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --nodelist=compute-0-1
#SBATCH --output="stdout_jup.txt"
#SBATCH --error="stderr_jup.txt"
#SBATCH --mail-user=username@um.ac.ir
#SBATCH --mail-type=BEGIN,END,FAIL ## ALL
#SBATCH --mem-per-cpu=1000
#SBATCH --time=7-0:0:0
ulimit -s unlimited
cd $SLURM_SUBMIT_DIR
source /share/apps/anaconda3/etc/profile.d/conda.sh
conda activate base
###eval "$(/share/apps/anaconda3/bin/conda shell.bash hook)"
jupyter notebook --no-browser >& out.txt
