#!/bin/bash

date

YEAR=${1}
CONFIG=CFSR

#--------------------------------------------------------------------------------
CFSRRAWDIR=/glade/scratch/zarzycki/CFSR/${YEAR}/
OUTDIR=/glade/scratch/zarzycki/h1files/CFSR/${YEAR}/
#--------------------------------------------------------------------------------

mkdir -p $OUTDIR
mkdir -p $CFSRRAWDIR

### Generate time array file
arrayFileName=timesArray_${YEAR}.txt
rm ${arrayFileName}
start=$(date -u --date '1 jan '${YEAR}' 0:00' +%s)
stop=$(date -u --date '31 dec '${YEAR}' 0:00' +%s)

for t in $(seq ${start} 86400 ${stop})
do
  thisDate=`date -u --date @${t} +'%Y%m%d'`
  echo $thisDate >> ${arrayFileName}
done

declare -a HOURS=("00" "06" "12" "18")
while read DATE; do
  echo "TOTAL DATE: $DATE"
  TARFILEDIR=~/rda/ds094.0/${YEAR}/
  TARFILENAME=cdas1.${DATE}.pgrbh.tar
  if [ -e "${TARFILEDIR}/${TARFILENAME}" ]; then
    cd $CFSRRAWDIR
    tar -xvf ${TARFILEDIR}/${TARFILENAME}
    #tar -xvf ${TARFILENAME}
    #rm ${TARFILENAME}

    cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/CFSR/
    ## now loop through the above array
    for ii in "${HOURS[@]}"
    do
      YYYYMMDD=${DATE}${ii}
      ncl generateTrackerFilesCFS-lite.ncl 'YYYYMMDD="'${YYYYMMDD}'"' 'outDir="'$OUTDIR'"'
      #wait
    done
    cd $OUTDIR
    ncrcat ${CONFIG}.h1.${DATE}*.nc ${CONFIG}.h1.${DATE}.nc
    rm ${CONFIG}.h1.${DATE}00.nc
    rm ${CONFIG}.h1.${DATE}06.nc
    rm ${CONFIG}.h1.${DATE}12.nc
    rm ${CONFIG}.h1.${DATE}18.nc    
    cd $CFSRRAWDIR
    rm *.grib2
  fi
done <${arrayFileName}

date

#rm -rf $CFSRRAWDIR/*.grb2
