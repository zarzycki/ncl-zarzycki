#!/bin/bash

YEAR=2007

#--------------------------------------------------------------------------------
CFSRRAWDIR=/glade/scratch/zarzycki/CFSR/${YEAR}
echo $CFSRRAWDIR

mkdir -p $CFSRRAWDIR
cd $CFSRRAWDIR

cp /glade/p/rda/data/ds093.0/${YEAR}/ipvhnl.gdas.${YEAR}*.tar .
cp /glade/p/rda/data/ds093.0/${YEAR}/pgbhnl.gdas.${YEAR}*.tar .

for f in *.tar
do
  tar -xvf "$f"
done

rm *.tar

cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/CFSR/
dates=`ls /glade/u/home/zarzycki/scratch/CFSR/${YEAR}/pgbhnl.gdas.*.grb2 | cut -c 54-63`
shopt -s nullglob
for f in $dates
do
  echo $f
  ncl generateTrackerFilesCFSR.ncl 'YYYYMMDD="'$f'"'
done

rm -rf $CFSRRAWDIR/*.grb2
