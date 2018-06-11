#!/bin/bash

################################################################
#PBS -N gnu-par
#PBS -A P54048000 
#PBS -l walltime=01:00:00
#PBS -q regular
#PBS -k oe
#PBS -e /glade/scratch/zarzycki/error.txt
#PBS -o /glade/scratch/zarzycki/output.txt
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36:mem=109GB
################################################################

module load parallel

YEAR=2071
NUMCORES=36
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

rm ${COMMANDFILE}
# create new line in command file for 1 -> NUMCORES
for ii in {001..035};       # 001..042 processes all available LENS data
do
  NUMSTORMS=`wc -l < /glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.${YEAR}.${ii}.5e-9_12.csv.SNOW.tempest.csv`
  counter=0
  while [ $counter -lt ${NUMSTORMS} ]
  do
    LINECOMMAND="ncl single-traj.ncl stormID=${counter} year=${YEAR} 'ensmem=\"${ii}\"' "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
    ((counter++))
  done
done

# Launch GNU parallel
#### Use this for login nodes (nohup ./batch.sh &)
#parallel --jobs ${NUMCORES} < ${COMMANDFILE}
#### Use this for Cheyenne batch jobs
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

date   
