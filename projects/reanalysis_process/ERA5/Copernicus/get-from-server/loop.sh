#!/bin/bash

## declare an array variable
#declare -a vars=("mean_sea_level_pressure" "10m_u_component_of_wind" "10m_v_component_of_wind")
declare -a vars=("surface_pressure")
#declare -a vars=("mean_sea_level_pressure")
#declare -a vars=("10m_u_component_of_wind")
#declare -a vars=("10m_v_component_of_wind")

STYR=1950
ENYR=1950

## now loop through the above array
for ii in "${vars[@]}"
do
  for jj in $(seq $STYR $ENYR);
  do
    python get.py "${jj}" "${ii}"
  done
done
