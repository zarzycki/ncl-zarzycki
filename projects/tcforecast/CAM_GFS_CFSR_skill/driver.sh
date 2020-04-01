#!/bin/bash

hours=( 6 12 24 36 48 60 72 96 120 144 168 192 216 240)
regions=( "nhemi" "conus" )
#configs=( "hindcast_conus_30_x8_CAM4_L26" "hindcast_conus_30_x8_CAM4_L26_HV" "hindcast_conus_30_x8_CAM5_L30" "hindcast_conus_30_x8_CAM6_L32" "hindcast_conus_30_x8_CAM5_L59" "hindcast_conus_30_x8_CAM5_L30_RTOPO" )
#configs=( "hindcast_mp15a-120a-US_CAM5_L30" )
configs=( "hindcast_conus_30_x8_CAM5_L30" "hindcast_conus_30_x8_CAM5_L30_NOLAND" )

for ii in "${regions[@]}"
do
for jj in "${hours[@]}"
do
for kk in "${configs[@]}"
do
  cd /glade/scratch/zarzycki/${kk}/run/ 
  for i in $( ls -d 201908* ); do
    echo $i
    cd /glade/u/home/zarzycki/ncl/projects/tcforecast/CAM_GFS_CFSR_skill/
    echo YYYYMMDDHH=$i region=${ii} hourForecast=${jj} fcst_config=${kk}
    ncl -n analyzeData.ncl YYYYMMDDHH=$i hourForecast=${jj} 'region="'${ii}'"'  'fcst_config="'${kk}'"'
  done
done
done
done




