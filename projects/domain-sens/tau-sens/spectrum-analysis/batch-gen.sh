#!/bin/bash

declare -a configs=("tau3600" "dtime1800" "dtime900" "tau900" "tau3600_lowdmpdz2" "dtime450tau1800")
VAR=VORT850_MASKI_F

## now loop through the above array
for ii in "${configs[@]}"
do
  CONFIG=$ii
  rm spectrum_${VAR}_${CONFIG}.nc
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1985-07-24"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1985-08-23"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1985-09-22"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1985-10-22"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1986-07-19"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1986-08-18"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1986-09-17"'
  ncl calc-ke-scalar.ncl 'UVARNAME="'${VAR}'"' 'anlconfig="'${CONFIG}'"' 'DATE="1986-10-17"'
done