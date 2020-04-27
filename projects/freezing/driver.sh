#!/bin/bash

##=======================================================================
#PBS -N ptype
#PBS -A UPSU0032 
#PBS -l walltime=11:59:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=4:ncpus=12:mpiprocs=12:mem=109GB
################################################################

module load ncarenv
module load python
ncar_pylib 20200417

# GNUPARALLEL SETTINGS
module load parallel
NUMCORES=12
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt
UQNODEFILE=unique-nodelist.${TIMESTAMP}.txt

# Get unique nodes
sort -u $PBS_NODEFILE > ${UQNODEFILE}

# Create commands.txt file for GNU parallel
rm ${COMMANDFILE}
shopt -s nullglob
for ii in `seq 0 15 1464`; do 
  echo $ii
  # Add a random 60s sleep to semi-distribute the I/O calls across tasks
  RANDSLP = $(( ( RANDOM % 60 )  + 1 ))
  NCLCOMMAND="module load ncarenv ; module load python ; ncar_pylib 20200417 ; sleep ${RANDSLP} ; python ./era5_xarray.py ${ii}  "
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} -u --sshloginfile ${UQNODEFILE} --workdir $PWD < ${COMMANDFILE}

# Clean up
rm ${COMMANDFILE}
rm ${UQNODEFILE}
