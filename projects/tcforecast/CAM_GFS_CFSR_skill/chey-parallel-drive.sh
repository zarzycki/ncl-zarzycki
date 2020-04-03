#!/bin/bash

##=======================================================================
#PBS -N acc-calcs-batch
#PBS -A UNSB0017 
#PBS -l walltime=02:59:00
#PBS -q regular
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

date

module load parallel

hours=( 6 12 24 36 48 60 72 96 120 144 168 )
regions=( "nhemi" )
configs=( "Q-adjustPS-ne30-F2000climo" "Q-adjustALL-ne30-F2000climo" "Q-Ofilter-ne30-F2000climo" "Q-NOfilter-ne30-F2000climo")
vars=( "Z500" "TS" )

STATSFILE="stats.CMZtest.txt"

TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

NUMCORES=12

rm ${STATSFILE}
rm ${COMMANDFILE}
# create new line in command file for 1 -> NUMCORES
#for i in `seq 1 ${NUMCORES}`;
#do

for ii in "${regions[@]}"
do
for jj in "${hours[@]}"
do
for kk in "${configs[@]}"
do
for ll in "${vars[@]}"
do
  #forecastpath="/glade/u/home/zarzycki/acgd0005/CMZ/HINDCASTS/${kk}/"
  forecastpath="/glade/scratch/zarzycki/${kk}/run/"
  cd ${forecastpath} 
  for zz in $( ls -d 2018* ); do
    echo $zz
    cd /glade/u/home/zarzycki/ncl/projects/tcforecast/CAM_GFS_CFSR_skill/
    echo YYYYMMDDHH=$zz region=${ii} hourForecast=${jj} fcst_config=${kk}
    NCLCOMMAND="ncl -n analyzeData.ncl YYYYMMDDHH=${zz} hourForecast=${jj} 'region=\"'${ii}'\"'  'azvar=\"'${ll}'\"' 'fcst_config=\"'${kk}'\"' 'PATHTOCAM=\"'${forecastpath}'\"'                "
    echo ${NCLCOMMAND} >> ${COMMANDFILE}
  done
done
done
done
done

cd /glade/u/home/zarzycki/ncl/projects/tcforecast/CAM_GFS_CFSR_skill/
# Launch GNU parallel
#parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}
parallel --jobs ${NUMCORES} -u < ${COMMANDFILE}

cat ./out-stats/hindcast_* > ${STATSFILE}
rm ${COMMANDFILE}
rm  ./out-stats/hindcast_*

date 
