#!/bin/bash

CONFIG=CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.002
FILES=`find ~/scratch/hyperion/${CONFIG}/atm/hist/ -name '*h4.*' -print | sort`
for f in $FILES
do
  echo "Processing $f file..."
  ncl add-ptypes-6hrs.ncl 'infile="'${f}'"'
done
