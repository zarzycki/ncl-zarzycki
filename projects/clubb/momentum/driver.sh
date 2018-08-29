#!/bin/bash

declare -a CONFIGS=("RCE.QPC5.ne0np4tcfplane.ne15x8.exp001.001" "RCE.QPC5.ne0np4tcfplane.ne15x8.exp001.002" "RCE.QPC5.ne0np4tcfplane.ne15x8.exp001.003")
declare -a DAYS=("08" "09" "10" "11")

## now loop through the above array
for ii in "${CONFIGS[@]}"
do
  for zz in "${DAYS[@]}"
  do
    ncl kepert-repro.ncl 'config="'${ii}'"' 'dayofsim="'${zz}'"'
  done
done
