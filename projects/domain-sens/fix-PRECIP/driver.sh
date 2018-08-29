#!/bin/bash

CONFIG=CORI.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900.003
FILES=`find ~/scratch/hyperion/${CONFIG}/atm/hist/ -name '*h4.*' -print | sort`
for f in $FILES
do
  echo "Processing $f file..."
  ncl add-ptypes-6hrs.ncl 'infile="'${f}'"'
done
