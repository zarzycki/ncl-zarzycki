#!/bin/bash

vars=( "PRECZF" "CAPE" "FREQZM" "TGCLDCWP" "CLDLOW" "CLDHGH" "FREQCLR" "TMQ" )


for ii in "${vars[@]}"
do
  ncl -n compare-h0.ncl 'var="'${ii}'"'
done
