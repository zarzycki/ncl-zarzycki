#!/bin/bash

#config="x005"
config=$1
MERGEDOUT=CAM_${config}.nc

for i in $(seq 2010 2018); do ncl allcam.ncl in_yyyy=${i} 'cmzconfig="'${config}'"'; done
#for i in $(seq 2010 2010); do ncl allcam.ncl in_yyyy=${i} 'cmzconfig="'${config}'"'; done
#for i in $(seq 2018 2018); do ncl allcam.ncl in_yyyy=${i} 'cmzconfig="'${config}'"'; done

ncea -O ${config}_20*.nc ${MERGEDOUT}

rm ${config}_20*.nc

### Process new vars

ncl add-sums.ncl 'fname="'${MERGEDOUT}'"'

mkdir -p fin
mv ${MERGEDOUT} fin
