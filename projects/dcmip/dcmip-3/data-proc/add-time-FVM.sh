#!/bin/bash

# script to add time var from orig FVM data to new data from Christian (4/28/18)

FILES=/glade/u/home/zarzycki/scratch/FVM_DCMIP_163_DATA/*
ORIGDIR=/glade/p/vetssg/data/DCMIP_2016/fvm/publish/
for f in $FILES
do
  base=$(basename $f)
  echo $base
  ncks -A -v time /glade/p/vetssg/data/DCMIP_2016/fvm/publish/${base} $f
done
