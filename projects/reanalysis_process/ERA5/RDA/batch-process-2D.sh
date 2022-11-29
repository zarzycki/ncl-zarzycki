#!/bin/bash

##=======================================================================
#PBS -N gnu-par
#PBS -A P93300642 
#PBS -l walltime=06:00:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36:mem=109GB
################################################################

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=12
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

GRIDCONFIG="ll025"  # regn320sc

for DATA_YEAR in {2020..2021}
do

# Add PSL files
FILES=`find /glade/u/home/zarzycki/rda/ds633.0/ -name "*e5*oper.an.sfc.128_151_msl.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-PSL.ncl 'filename=\"$f\"'"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# # Add snow files
# FILES=`find /glade/u/home/zarzycki/rda/ds633.4/ -name "*e5*oper.fc.sfc.accumu.128_144_sf.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
# for f in $FILES
# do
#   LINECOMMAND="ncl process-SNOW.ncl 'filename=\"$f\"'"
#   echo ${LINECOMMAND} >> ${COMMANDFILE}
# done

done

#### Use this for Cheyenne batch jobs
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

