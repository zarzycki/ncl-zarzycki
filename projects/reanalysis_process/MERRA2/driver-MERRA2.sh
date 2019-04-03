#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                # queue
#BSUB -J h1_process
#BSUB -W 12:00                    # wall clock limit
#BSUB -P P35201098               # account number

################################################################

date

YEAR=${1}
OUTDIR=/glade/scratch/zarzycki/MERRA2
OUTPUTDIR=/glade/scratch/zarzycki/h1files/MERRA2/${YEAR}
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
	  FILETOTEST=${OUTPUTDIR}"/MERRA2.h1.${yyyy}${mm}${dd}.nc"
    if [ ! -f ${FILETOTEST} ]; then
      echo "FILE ${FILETOTEST} DOES NOT EXIST, CREATING..."
      cd ${OUTDIR}
      ## Check which filename exist
      declare -a arr=("400" "300" "200" "100" "401" "301" "201" "101" " ")
      URLSTART="https://goldsmr5.gesdisc.eosdis.nasa.gov/data/MERRA2/M2I6NVANA.5.12.4/${yyyy}/${mm}/"
      ## now loop through the above array
      for STREAMSTR in "${arr[@]}"
      do
        FILENAME="MERRA2_${STREAMSTR}.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.nc4"
        url=${URLSTART}${FILENAME}
        if wget --spider ${url} 2>/dev/null; then
          break
        fi
      done

      modlevs=MERRA2_${STREAMSTR}.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.nc4
      preslevs=MERRA2_${STREAMSTR}.inst6_3d_ana_Np.${yyyy}${mm}${dd}.nc4

      echo $modlevs

       if [ ! -f ${modlevs} ]; then
         wget --quiet --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies --content-disposition https://goldsmr5.gesdisc.eosdis.nasa.gov/data/MERRA2/M2I6NVANA.5.12.4/${yyyy}/${mm}/${modlevs}
       fi
       if [ ! -f ${preslevs} ]; then
         wget --quiet --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies --content-disposition https://goldsmr5.gesdisc.eosdis.nasa.gov/data/MERRA2/M2I6NPANA.5.12.4/${yyyy}/${mm}/${preslevs}
       fi
      cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA2
      ncl generateTrackerFilesMERRA2-lite.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"' 'outDir="'${OUTPUTDIR}'"' 'streamString="'${STREAMSTR}'"'
      rm ${OUTDIR}/${modlevs}
      rm ${OUTDIR}/${preslevs}
    else
      echo "FILE ${FILETOTEST} EXISTS, SKIPPING..."
    fi
  done
done

date

