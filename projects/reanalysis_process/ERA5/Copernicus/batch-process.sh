#!/bin/bash -l

#SBATCH --job-name=ERA5_mpi
#SBATCH --account=P05010048
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=4
#SBATCH --time=01:00:00
#SBATCH --partition=dav
#SBATCH --output=ERA5_mpi.out.%j

module load parallel
module load ncl

ncl process-PSL.ncl

