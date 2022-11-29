#!/bin/bash

module load ncl

NCLDIR=/glade/u/home/zarzycki/ncl/projects/domain-sens/tau-sens/data-process

WGTFILE=/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_0.25x0.25_NATL.nc
CONFIG=${1}

cd /glade/u/home/zarzycki/scratch/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.${CONFIG}/atm/hist/

# Clean up old file
rm *.cam.h3.*regrid*

FILES=`find -name "*.h3.????-[01][7890]-*.nc" | grep -v 1984 | grep -v 1994 | grep -v 2007 | grep -v 2008 | grep -v 2009 | sort -n`
for f in $FILES
do
  NEWFILE=`basename $f`_regrid.nc
  echo $f ${NEWFILE}
  
  # Added 1/6/22 --> if file is compressed, need to uncompress for NCL to handle appropriately...
  nccopy -k nc3 $f tmp.nc
  mv tmp.nc $f

  # Extract relevant vars
  ncremap -v PSL,PRECL,PRECC,PRECT,TMQ,U850,V850,OMEGA500 -i $f -o ${NEWFILE} -m $WGTFILE
 
  # From 3 to 6-hourly
  ncks -O -d time,,,2 ${NEWFILE} ${NEWFILE}

  # Calculate vorticity
  ncl ${NCLDIR}/process-vort.ncl 'infile="'${NEWFILE}'"'

  # Calculate vorticity
  ncl ${NCLDIR}/traj-filter.ncl 'infile="'${NEWFILE}'"' 'thisConfig="'${CONFIG}'"'
done
