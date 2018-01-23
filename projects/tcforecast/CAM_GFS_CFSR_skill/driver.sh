#!/bin/bash

cd /glade/scratch/zarzycki/hindcast_conus_30_x8_CAM4_L26/run/ 
for i in $( ls -d 201* ); do
  echo $i
  cd /glade/u/home/zarzycki/ncl/projects/tcforecast/CAM_GFS_CFSR_skill/
  ncl -n analyzeData.ncl YYYYMMDDHH=$i
done
