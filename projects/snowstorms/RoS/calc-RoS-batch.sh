#!/bin/bash

declare -a ENSMEMS=("001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012" "013" "014" "015" "016" "017" "018" "019" "020" "021" "022" "023" "024" "025" "026" "027" "028" "029" "030" "031" "032" "033")
#declare -a ENSMEMS=("001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012" "013" "014" "015")
declare -a YEARS=("1990" "2026" "2071")
declare -a STORMS=("True" "False")

for xx in "${ENSMEMS[@]}"
do
  for yy in "${YEARS[@]}"
  do
    for zz in "${STORMS[@]}"
    do
      ncl plot-files.ncl 'STORMFILT="'${zz}'"' 'STYR="'${yy}'"' 'ENSMEM="'${xx}'"'
    done
  done
done
