#!/bin/bash

##=======================================================================
#PBS -N gnu-par
#PBS -A P54048000 
#PBS -l walltime=00:59:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
#####PBS -l select=1:ncpus=36:mem=109GB
################################################################

NUMCORES=18
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

#declare -a CONFIGS=("RCE.QPC5.ne0np4tcfplane.ne15x8.exp001" "RCE.QPC5.ne0np4tcfplane.ne15x8.exp002" "RCE.QPC5.ne0np4tcfplane.ne15x8.exp003" "RCE.QPC5.ne0np4tcfplane.ne15x8.exp004")
declare -a CONFIGS=("RCE.QPC6.ne0np4tcfplane.ne15x8.exp998" "RCE.QPC6.ne0np4tcfplane.ne15x8.exp999")
declare -a DAYS=("08" "09" "10" "11")
declare -a ENSNUMS=("001" "002" "003")
#declare -a ENSNUMS=("001")
## now loop through the above array
for ii in "${CONFIGS[@]}"
do
  for zz in "${DAYS[@]}"
  do
    for yy in "${ENSNUMS[@]}"
    do
      THISCONFIG=${ii}.${yy}
      LINECOMMAND="ncl kepert-repro.ncl 'config=\"${THISCONFIG}\"' 'dayofsim=\"${zz}\"'"
      echo ${LINECOMMAND} >> ${COMMANDFILE}
    done
  done
done

#### Use this for Cheyenne batch jobs
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}





