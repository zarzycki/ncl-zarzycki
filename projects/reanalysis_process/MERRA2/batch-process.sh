#!/bin/bash -l

#SBATCH --job-name=MERRA2_mpi
#SBATCH --account=P05010048
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=4
#SBATCH --time=23:00:00
#SBATCH --partition=dav
#SBATCH --output=MERRA2_mpi.out.%j

module load parallel
module load ncl

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=4
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

for DATA_YEAR in {1980..2019}
do
  LINECOMMAND="/bin/bash ./driver-MERRA2.sh ${DATA_YEAR}"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

#### Use this for Cheyenne batch jobs
#parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}
parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

