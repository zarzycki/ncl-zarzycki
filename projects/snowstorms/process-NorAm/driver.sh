#!/bin/bash

for YYYY in `seq 1958 2018`; do
  ncl NorAm-to-6hrly.ncl yyyy=$YYYY
done
