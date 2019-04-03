#!/bin/bash

date

YEAR=$1
OUTDIR=/glade/scratch/zarzycki/MERRA/
OUTPUTDIR=/glade/scratch/zarzycki/h1files/MERRA/${YEAR}
mkdir -p $OUTDIR
mkdir -p $OUTPUTDIR

#for j in `seq 0 36`   # 0 36
for j in `seq 0 365`   # 0 36
do
  #st=$(($j*10))
  #en=$(($j*10+9))
  st=$j
  en=$j
  echo $st
  echo $en
  echo "-----"
  for i in `seq ${st} ${en}`
  do
    yyyy=`date -d "${YEAR}-01-01 $i days" +%Y`
    mm=`date -d "${YEAR}-01-01 $i days" +%m`
    dd=`date -d "${YEAR}-01-01 $i days" +%d`
    echo ${yyyy}${mm}${dd}

    # CHECK IF OUTPUT FILE EXISTS
	  FILETOTEST=${OUTPUTDIR}"/MERRA.h1.${yyyy}${mm}${dd}.nc"
    if [ ! -f ${FILETOTEST} ]; then
      echo "FILE ${FILETOTEST} DOES NOT EXIST, CREATING..."
      cd ${OUTDIR}
      ## Check which filename exist
      declare -a arr=("400" "300" "200" "100" "401" "301" "201" "101" " ")
      URLSTART="https://goldsmr3.gesdisc.eosdis.nasa.gov/data/MERRA/MAI6NVANA.5.2.0/${yyyy}/${mm}/"
      ## now loop through the above array
      for STREAMSTR in "${arr[@]}"
      do
        FILENAME="MERRA${STREAMSTR}.prod.assim.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.hdf"
        url=${URLSTART}${FILENAME}

        if wget --spider ${url} 2>/dev/null; then
          break
        fi
      done

      modlevs=MERRA${STREAMSTR}.prod.assim.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.hdf
      preslevs=MERRA${STREAMSTR}.prod.assim.inst6_3d_ana_Np.${yyyy}${mm}${dd}.hdf

      echo $modlevs

       if [ ! -f ${modlevs} ]; then
         wget --quiet --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies --content-disposition https://goldsmr3.gesdisc.eosdis.nasa.gov/data/MERRA/MAI6NVANA.5.2.0/${yyyy}/${mm}/${modlevs}
       fi
       if [ ! -f ${preslevs} ]; then
         wget --quiet --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies --content-disposition https://goldsmr3.gesdisc.eosdis.nasa.gov/data/MERRA/MAI6NPANA.5.2.0/${yyyy}/${mm}/${preslevs}
       fi
      cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA
      ncl generateTrackerFilesMERRA-lite.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"' 'outDir="'${OUTPUTDIR}'"' 'streamString="'${STREAMSTR}'"'
      rm ${OUTDIR}/${modlevs}
      rm ${OUTDIR}/${preslevs}
    else
      echo "FILE ${FILETOTEST} EXISTS, SKIPPING..."
    fi
  done
done

date

