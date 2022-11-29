#!/bin/bash -l

#PBS -N MERRA_mpi.out
#PBS -A UPSU0032
#PBS -l select=1:ncpus=4:mpiprocs=4:mem=80GB
#PBS -l walltime=24:00:00
#PBS -q casper
#PBS -j oe

module load parallel
module load ncl

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=4
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

for DATA_YEAR in {2020..2021}
do
  LINECOMMAND="/bin/bash ./driver-MERRA.sh ${DATA_YEAR}"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

#### Use this for Cheyenne batch jobs
#parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}
parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

