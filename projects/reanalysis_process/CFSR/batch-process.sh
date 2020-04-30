#!/bin/bash -l

#SBATCH --job-name=CFSR_mpi
#SBATCH --account=P05010048
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=4
#SBATCH --time=18:00:00
#SBATCH --partition=dav
#SBATCH --output=CFSR_mpi.out.%j

module load parallel
module load ncl
module load nco

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=4
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

for DATA_YEAR in {2011..2019}
do
  LINECOMMAND="/bin/bash ./driver-CFS.sh ${DATA_YEAR}"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

