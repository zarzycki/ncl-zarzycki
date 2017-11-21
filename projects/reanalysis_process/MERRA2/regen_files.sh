#!/bin/bash

YEAR=2001
OUTDIR=/glade/scratch/zarzycki/MERRA2
OUTPUTDIR=/glade/scratch/zarzycki/h1files/MERRA2/${YEAR}

for i in `seq 0 364`
do
  yyyy=`date -d "${YEAR}-01-01 $i days" +%Y`
  mm=`date -d "${YEAR}-01-01 $i days" +%m`
  dd=`date -d "${YEAR}-01-01 $i days" +%d`
  echo ${yyyy}${mm}${dd}

  # Check if file exists in output dir.
  if [ ! -f ${OUTPUTDIR}/MERRA2.h1.${yyyy}${mm}${dd}.nc ]; then
    echo "Need to regen this file..."

    # If the file doesn't exist, we will first go back to re-download MERRA files if necessary...
    cd ${OUTDIR}
    modlevs=MERRA2_300.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.nc4
    preslevs=MERRA2_300.inst6_3d_ana_Np.${yyyy}${mm}${dd}.nc4
    if [ ! -f ${modlevs} ]; then
      echo "Redownloading model levels..."
      wget ftp://goldsmr5.gesdisc.eosdis.nasa.gov/data/s4pa/MERRA2/M2I6NVANA.5.12.4/${yyyy}/${mm}/${modlevs}
    fi
    if [ ! -f ${preslevs} ]; then
      echo "Redownloading pressure levels..."
      wget ftp://goldsmr5.gesdisc.eosdis.nasa.gov/data/s4pa/MERRA2/M2I6NPANA.5.12.4/${yyyy}/${mm}/${preslevs}
    fi

    # After file checking/downloading as been done, we regenerate this file
    echo "Regen via NCL..."
    cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA2
    ncl generateTrackerFilesMERRA.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"' 'outDir="'${OUTPUTDIR}'"'

  fi
done
