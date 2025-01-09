#!/bin/bash

# Check if file name is supplied
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <netcdf-file>"
  exit 1
fi

# Check if ncdump is installed
if ! [ -x "$(command -v ncdump)" ]; then
  echo 'Error: ncdump is not installed.' >&2
  exit 1
fi

# Declare an associative array to hold variable names and their ranks
declare -A var_rank

# Populate the array with variable names and ranks
while read -r line; do
  var_name=$(echo "$line" | awk '{print $2}' | awk -F '(' '{print $1}')
  rank=$(echo "$line" | awk -F '(' '{print $2}' | awk -F ')' '{print $1}' | awk -F ',' '{print NF}')
  var_rank["$var_name"]=$rank
done < <(ncdump -h "$1" | grep '^\s*float\|double')
#done < <(ncdump -h "$1" | grep '^\s*float\|double\|int\|char')

# Loop through the array and print variable names and their ranks
for var in "${!var_rank[@]}"; do
  echo "Variable: $var, Rank: ${var_rank[$var]}"
  if [ "${var_rank[$var]}" -eq 2 ]; then
    ncl diff-rad.ncl 'varstr="'$var'"'
  fi
done

