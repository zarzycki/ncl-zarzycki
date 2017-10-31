#!/bin/bash

cd ~/scratch/_TCFORECAST/2012_00Z/
dates=`ls -d 2012*`
cd /glade/u/home/zarzycki/ncl/projects/tcforecast/
for i in $dates; do
  ncl -n Z500skill.ncl YYYYMMDDHH=${i}
done
