#!/bin/bash

##=======================================================================
#PBS -N acc-calcs-batch
#PBS -A P05010048 
#PBS -l walltime=11:59:00
#PBS -q economy
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

date

module load parallel

hours=( 6 12 24 36 48 60 72 96 120 144 168 192 216 240)
#hours=( 6 12 24 48 72 96 120 144 192 240)
#hours=( 6 12 120 240)
regions=( "nhemi" "conus" )
#configs=( "hindcast_mp15a-120a-US_CAM5_L30" "hindcast_conus_30_x8_CAM4_L26" )
#configs=( "hindcast_conus_15_x16_CAM5_L30" "hindcast_conus_60_x4_CAM5_L30" "hindcast_mp15a-120a-US_CAM5_L30" "hindcast_conus_30_x8_CAM4_L26" "hindcast_conus_30_x8_CAM4_L26_HV" "hindcast_conus_30_x8_CAM5_L30" "hindcast_conus_30_x8_CAM6_L32" "hindcast_conus_30_x8_CAM5_L59" "hindcast_conus_30_x8_CAM5_L30_RTOPO" "hindcast_conus_30_x8_CAM5_L30_NOFILT" )
configs=( "hindcast_conus_15_x16_CAM5_L30" )
#vars=( "U200" "U850" "Z500" "T200" "T850" )
vars=( "Z500" )

TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

NUMCORES=1

rm stats.1.txt
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
  #jj=${configs[${i}]}
  cd /glade/scratch/zarzycki/${kk}/run/ 
  for zz in $( ls -d 201801* ); do
    echo $zz
    cd /glade/u/home/zarzycki/ncl/projects/tcforecast/CAM_GFS_CFSR_skill/
    echo YYYYMMDDHH=$zz region=${ii} hourForecast=${jj} fcst_config=${kk}
    NCLCOMMAND="ncl -n analyzeData.ncl YYYYMMDDHH=${zz} hourForecast=${jj} 'region=\"'${ii}'\"'  'azvar=\"'${ll}'\"' 'fcst_config=\"'${kk}'\"'                "
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

cat ./out-stats/hindcast_* > stats.1.txt
rm ${COMMANDFILE}
rm  ./out-stats/hindcast_*

date 
