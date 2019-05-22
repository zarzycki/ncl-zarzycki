#!/bin/bash

TMPFILE=_tmp.nc
## declare an array variable
declare -a years=`seq 2002 2002`
declare -a vars=("U850" "V850" "UBOT" "VBOT" "Z300" "Z500" "PSL" "T400")
declare -a months=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12")

## now loop through the above array
for ii in ${years}
do
  for jj in "${months[@]}"
  do
    for zz in "${vars[@]}"
    do
      ncrcat ERA5.${zz}.${ii}${jj}*.nc CAT.ERA5.${zz}.${ii}${jj}.nc
      ncatted -O -a time,,d,, CAT.ERA5.${zz}.${ii}${jj}.nc 
      ncks -A CAT.ERA5.${zz}.${ii}${jj}.nc ${TMPFILE}
      ncatted -O -a history,global,d,, -a history_of_appended_files,global,d,, ${TMPFILE} ${TMPFILE}
    done
    mv ${TMPFILE} ALL.ERA5.${ii}${jj}.nc
  done

  ### Generate time array file
  YYYY=${ii}
  arrayFileName=timesArray_${YYYY}.txt
  rm ${arrayFileName}
  start=$(date -u --date '1 jan '${YYYY}' 00:00' +%s)
  stop=$(date -u --date '31 dec '${YYYY}' 00:00' +%s)

  for t in $(seq ${start} 86400 ${stop})
  do
    thisDate=`date -u --date @${t} +'%Y%m%d'`
    echo $thisDate >> ${arrayFileName}
  done

  STMONTH="99"
  while IFS= read -r var
  do
    echo "$var"
    # Get month
    THISMONTH=`echo ${var:4:2}`
    echo $STMONTH $THISMONTH
    if [ "$THISMONTH" != "$STMONTH" ] ; then
      echo "SWITCHING MONTHS"
      STMONTH=$THISMONTH
      STIX=0
      ENIX=3
    fi
    ncks -O -d time,$STIX,$ENIX ALL.ERA5.${YYYY}${THISMONTH}.nc ERA5.h1.${var}.nc
    STIX=$((STIX+4))
    ENIX=$((ENIX+4))
  done < ${arrayFileName}

  mkdir -p ~/scratch/h1files/ERA5/$YYYY/
  mv ERA5.h1.${YYYY}*nc ~/scratch/h1files/ERA5/$YYYY/

done
