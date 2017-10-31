#!/bin/bash

## This script is designed to spawn NUMYEARS instances of some script
## which is initiated for a given year


scriptname=driver.sh

for DATA_YEAR in {2000..2009}
do
  echo "Sedding ${DATA_YEAR}"
  sed -i "s?^YEAR.*?YEAR=${DATA_YEAR}?" ${scriptname}
  qsub ${scriptname}
done
