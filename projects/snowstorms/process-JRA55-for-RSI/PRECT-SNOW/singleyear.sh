#!/bin/bash

JRABASEDIR=/gpfs/fs1/collections/rda/data/ds628.0/
SYMDIR=/glade/u/home/zarzycki/scratch/JRAsym/
OUTBASE=/glade/scratch/zarzycki/j1files/JRA/

YYYY=$1
echo $YYYY

#if [ ! -f ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PRECT.nc ]; then

  echo ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PRECT.nc" does not exist"

  ### Symlink JRA files
  mkdir -p ${SYMDIR}/${YYYY}

  #declare -a prect_arr=("tmp")
  declare -a prect_arr=("rof" "srweq" "tprat" "snwe" "tmp")
  for i in "${prect_arr[@]}"
  do
    if [ "${i}" == "snwe" ]; then
      FILES=${JRABASEDIR}/fcst_land/${YYYY}/*_${i}.reg_tl319.*
    elif [ "${i}" == "rof" ]; then
      FILES=${JRABASEDIR}/fcst_phyland/${YYYY}/*_${i}.reg_tl319.*
    elif [ "${i}" == "tmp" ]; then
      FILES=${JRABASEDIR}/anl_surf/${YYYY}/*_${i}.reg_tl319.*
    else
      FILES=${JRABASEDIR}/fcst_surf/${YYYY}/*_${i}.reg_tl319.*
    fi
    
    for f in $FILES
    do
      echo "Processing $f file..."
      a=$(basename $f)
      rm ${SYMDIR}/${YYYY}/${a}.grb2
      ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
    done
  done

  ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="srweq"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="tprat"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="rof"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="snwe"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="tmp"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'

#fi