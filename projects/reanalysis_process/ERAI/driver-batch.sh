#!/bin/bash -l

#SBATCH --job-name=ERAI_mpi
#SBATCH --account=P05010048
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=4
#SBATCH --time=18:00:00
#SBATCH --partition=dav
#SBATCH --output=ERAI_mpi.out.%j

module load parallel
module load ncl
module load nco

NUMCORES=4
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt
rm ${COMMANDFILE}

for YYYY in `seq 2017 2019`; do
  LINECOMMAND="./driver.sh ${YYYY}   "
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

#### Use this for Cheyenne batch jobs
#parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}
parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}
