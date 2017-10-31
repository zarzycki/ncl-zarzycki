#!/bin/bash

cd ~/scratch/TCFORECAST_2013/
for i in $( ls -d 2013* ); do
  echo $i
  cd /glade/u/home/zarzycki/CFSRscripts 
  ncl -n analyzeData.ncl YYYYMMDDHH=$i
done
