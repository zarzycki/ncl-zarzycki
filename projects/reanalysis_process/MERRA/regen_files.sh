#!/bin/bash

for i in `seq 0 364`
do
  yyyy=`date -d "2005-01-01 $i days" +%Y`
  mm=`date -d "2005-01-01 $i days" +%m`
  dd=`date -d "2005-01-01 $i days" +%d`
  echo ${yyyy}${mm}${dd}
  cd /glade/scratch/zarzycki/MERRA/
  modlevs=MERRA300.prod.assim.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.hdf
  preslevs=MERRA300.prod.assim.inst6_3d_ana_Np.${yyyy}${mm}${dd}.hdf
  if [ ! -f ${modlevs} ]; then
    wget ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI6NVANA.5.2.0/${yyyy}/${mm}/${modlevs}
  fi
  if [ ! -f ${preslevs} ]; then
    wget ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI6NPANA.5.2.0/${yyyy}/${mm}/${preslevs}
  fi
  cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA
  #if [ ! -f /glade/u/home/zarzycki/scratch/h1files/MERRA/MERRA.h1.${yyyy}${mm}${dd}.nc ]; then
    ncl generateTrackerFilesMERRA.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"'
  #fi
done
