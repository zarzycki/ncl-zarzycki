#!/bin/bash

STYR=1980
ENYR=1993

for DATA_YEAR in `seq ${STYR} ${ENYR}`
do
  ncl tc_only_precip.ncl yyyy=${DATA_YEAR}
done
