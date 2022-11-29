#!/bin/bash

#config="x005"
config=$1

for i in $(seq 2010 2018); do ncl bincam_sfc.ncl in_yyyy=${i} 'cmzconfig="'${config}'"'; done

ncea -O ${config}_20*.nc CAM_${config}.nc

rm ${config}_20*.nc 