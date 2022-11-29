#!/bin/bash -l

#PBS -N NARR_mpi.out
#PBS -A UPSU0032
#PBS -l select=1:ncpus=4:mpiprocs=4:mem=80GB
#PBS -l walltime=24:00:00
#PBS -q casper
#PBS -j oe

module load parallel
module load ncl
module load nco

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=4
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

for DATA_YEAR in {2019..2021}
do
  LINECOMMAND="/bin/bash ./driver-NARR.sh ${DATA_YEAR}"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

