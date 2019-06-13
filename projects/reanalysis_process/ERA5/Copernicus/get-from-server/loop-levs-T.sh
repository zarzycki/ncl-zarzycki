#!/bin/bash

## declare an array variable
declare -a vars=("temperature")
declare -a levs=("400")

STYR=1987
ENYR=2009

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
