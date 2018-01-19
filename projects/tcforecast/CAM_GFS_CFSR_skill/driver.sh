#!/bin/bash

cd /glade/scratch/zarzycki/forecast_conus_30_x8_CAM5/run/ 
for i in $( ls -d 201* ); do
  echo $i
  cd /glade/u/home/zarzycki/ncl/projects/tcforecast/CAM_GFS_CFSR_skill/
  ncl -n analyzeData.ncl YYYYMMDDHH=$i
done
