#!/bin/bash

##=======================================================================
#PBS -N precip-hist
#PBS -A P54048000 
#PBS -l walltime=03:59:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36:mem=109GB
################################################################

NUMCORES=5
COMMANDFILE=glist
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}




