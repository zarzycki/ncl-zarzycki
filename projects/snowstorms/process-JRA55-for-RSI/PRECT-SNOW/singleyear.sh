#!/bin/bash

JRABASEDIR=~/rda/ds628.0/
SYMDIR=/glade/derecho/scratch/zarzycki/JRAsym/
OUTBASE=/glade/derecho/scratch/zarzycki/j1files/JRA/

YYYY=$1
echo $YYYY

#if [ ! -f ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PRECT.nc ]; then

  #echo ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PRECT.nc" does not exist"

  ### Symlink JRA files
  mkdir -p ${SYMDIR}/${YYYY}

  declare -a prect_arr=("ugrd" "vgrd" "spfh" "rh")
  #declare -a prect_arr=("dswrf")
  #declare -a prect_arr=("dlwrf" "ulwrf" "dswrf" "uswrf" "lhtfl", "shtfl")
  #declare -a prect_arr=("rof" "srweq" "tprat" "snwe" "tmp" "pwat")
  for i in "${prect_arr[@]}"
  do
    if [ "${i}" == "snwe" ]; then
      FILES=${JRABASEDIR}/anl_land/${YYYY}/*_${i}.reg_tl319.*
    elif [ "${i}" == "rof" ]; then
      FILES=${JRABASEDIR}/fcst_phyland/${YYYY}/*_${i}.reg_tl319.*
    elif [ "${i}" == "tmp" ] || [ "${i}" == "ugrd" ] || [ "${i}" == "vgrd" ] || [ "${i}" == "rh" ] || [ "${i}" == "spfh" ] ; then
      FILES=${JRABASEDIR}/anl_surf/${YYYY}/*_${i}.reg_tl319.*
    elif [ "${i}" == "pwat" ]; then
      FILES=${JRABASEDIR}/anl_column/${YYYY}/*_${i}.reg_tl319.*
    else
      FILES=${JRABASEDIR}/fcst_phy2m/${YYYY}/*_${i}.reg_tl319.*
    fi

    for f in $FILES
    do
      echo "Processing $f file..."
      a=$(basename $f)
      rm ${SYMDIR}/${YYYY}/${a}.grb2
      ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
    done

    ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="'${i}'"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'

  done

  #ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="pwat"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  #ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="snwe"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  #ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="srweq"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  #ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="tprat"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  #ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="rof"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
  #ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="tmp"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'

#fi


#./fcst_phy2m/1961/fcst_phy2m.121_lhtfl.reg_tl319.1961010100_1961033121
#./fcst_phy2m/1966/fcst_phy2m.122_shtfl.reg_tl319.1966010100_1966033121
#fcst_phy2m.204_dswrf.reg_tl319.1986010100_1986033121
#fcst_phy2m.205_dlwrf.reg_tl319.1986010100_1986033121
#fcst_phy2m.211_uswrf.reg_tl319.1986010100_1986033121
#fcst_phy2m.212_ulwrf.reg_tl319.1986010100_1986033121
