#!/bin/bash

##=======================================================================
#PBS -N test_gnu
#PBS -A P54048000 
#PBS -l walltime=11:49:00
#PBS -q regular
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

date

module load parallel

NUMCORES=30
NUMTIMES=120
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

thedate="1999-12-17-00000"

camconfig="ne0conus30x8_t12.exp003"

filetoprocess="/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5."${camconfig}"/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5."${camconfig}".cam.h2."${thedate}".nc"
filetoprocessbase=`basename ${filetoprocess}`

rm ${COMMANDFILE}
# create new line in command file for 1 -> NUMCORES
for i in `seq 1 ${NUMTIMES}`;
do
  imin1=`expr $i - 1`
  NCLCOMMAND="ncl verif-forecast-cam-unstruc-par.ncl INIX=${imin1} 'config=\"${camconfig}\"' 'origfull=\"${filetoprocess}\"'     " 
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done
 
# Launch GNU parallel
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

## concat files
outfilename="${filetoprocessbase/h2/h9}"

#/scratch/SEVEREPROC/ne30_g16
WORKDIR=/glade/scratch/zarzycki/SEVEREPROC/${camconfig}/
ncrcat -O ${WORKDIR}/tmp.nat2_*_${filetoprocessbase} ${WORKDIR}/${outfilename}
rm ${WORKDIR}/tmp.nat2_*_${filetoprocessbase}
rm ${COMMANDFILE}

date 
