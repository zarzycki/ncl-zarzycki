#!/bin/bash

## declare an array variable
declare -a vars=("u_component_of_wind" "v_component_of_wind")
declare -a levs=("850")

STYR=2016
ENYR=2019

## now loop through the above array
for ii in "${vars[@]}";
do
  for jj in $(seq $STYR $ENYR);
  do
    for kk in "${levs[@]}";
    do
      python get-levs.py "${jj}" "${ii}" "${kk}"
    done
  done
done
