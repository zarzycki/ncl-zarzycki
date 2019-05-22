#!/bin/bash

declare -a ENSMEMS=("001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012" "013" "014" "015" "016" "017" "018" "019" "020" "021" "022" "023" "024" "025" "026" "027" "028" "029" "030" "031" "032" "033" "034" "035")
declare -a YEARS=("1990" "2026" "2071")

for xx in "${ENSMEMS[@]}"
do
  for yy in "${YEARS[@]}"
  do
    ncl get-timeseries.ncl 'STYR="'${yy}'"' 'ENSMEM="'${xx}'"'
  done
done
