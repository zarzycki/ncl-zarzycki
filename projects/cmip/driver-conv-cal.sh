#!/bin/bash -l

#PBS -N cmip-convert
#PBS -A P93300642
#PBS -l select=1:ncpus=10:mpiprocs=10:mem=200GB
#PBS -l walltime=24:00:00
#PBS -q casper
#PBS -j oe

module load parallel
module load ncl

NUMCORES=10
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt
PATH_TO_DATA=/glade/scratch/abolivar/tc_risk/input/HadGEM3-LM/r1i15p1f1/

for f in ${PATH_TO_DATA}/*nc; do
  echo $f
  LINECOMMAND="ncl convert-360-to-365.ncl 'filename=\"$f\"'"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

