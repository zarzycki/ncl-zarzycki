#!/bin/bash -l

#SBATCH --job-name=ERA5_mpi
#SBATCH --account=P05010048
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=4
#SBATCH --time=18:00:00
#SBATCH --partition=dav
#SBATCH --output=ERA5_mpi.out.%j

##=======================================================================
#> #PBS -N ERA5_MPI 
#> #PBS -A P93300642 
#> #PBS -l walltime=3:59:00
#> #PBS -q regular
#> #PBS -j oe
#> #PBS -l select=2:ncpus=2:mpiprocs=2:mem=109GB
################################################################

module load parallel
module load ncl
module load nco

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=1
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

for DATA_YEAR in {2016..2019}
do
  LINECOMMAND="ncl process-PSL.ncl YEAR=$DATA_YEAR"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

