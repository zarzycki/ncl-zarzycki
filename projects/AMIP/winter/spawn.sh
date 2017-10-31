#!/bin/bash

## This script is designed to spawn NUMYEARS instances of some script
## which is initiated for a given year

thisdir=$PWD
scriptdir=$PWD
scriptname=putvort_driver.sh

for DATA_YEAR in {1982..2002}
do
  echo "Sedding ${DATA_YEAR}"
  sed -i "s?^year.*?year=${DATA_YEAR}?" ${scriptdir}/${scriptname}
  
  cd ${scriptdir}
  bsub < ${scriptname}
  cd $thisdir
      
done
