#!/bin/bash -l

#PBS -N JRA_mpi.out
#PBS -A UPSU0032
#PBS -l select=1:ncpus=4:mpiprocs=4:mem=80GB
#PBS -l walltime=24:00:00
#PBS -q casper
#PBS -j oe

module load parallel
module load ncl
module load nco

NUMCORES=4
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt
rm ${COMMANDFILE}

for YYYY in `seq 2020 2021`; do
  LINECOMMAND="./singleyear.sh ${YYYY}   "
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

#### Use this for Cheyenne batch jobs
#parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}
parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}
