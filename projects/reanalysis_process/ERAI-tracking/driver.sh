#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 23:58                    # wall clock limit
#BSUB -P P54048000               # account number

################################################################

ERAIBASEDIR=/glade/collections/rda/data//ds627.0/
SYMDIR=/glade/u/home/zarzycki/scratch/ERAIsym/
OUTBASE=/glade/scratch/zarzycki/ERAI-ETC/
YYYY=2016

### Generate time array file
arrayFileName=timesArray_${YYYY}.txt
rm ${arrayFileName}
start=$(date -u --date '1 jan '${YYYY}' 0:00' +%s)
stop=$(date -u --date '31 dec '${YYYY}' 18:00' +%s)
for t in $(seq ${start} 21600 ${stop})
do
  thisDate=`date -u --date @${t} +'%Y%m%d%H'`
  echo $thisDate >> ${arrayFileName}
done

### Symlink ERAI files
mkdir -p ${SYMDIR}/${YYYY}
rm ${SYMDIR}/${YYYY}/*.grb2

#cp /glade/p/rda/data/ds627.0/ei.oper.an.pl/199208/ei.oper.an.pl.regn128sc.1992082700 .


declare -a anl_mdl_arr=("ml" "pl" "sfc")
for i in "${anl_mdl_arr[@]}"
do
  FILES=${ERAIBASEDIR}/ei.oper.an.${i}/${YYYY}*/ei.oper.an.*regn128sc*
  for f in $FILES
  do
    echo "Processing $f file..."
    a=$(basename $f)
    ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
  done
done

### Make output dir
mkdir -p ${OUTBASE}/${YYYY}

# doo NCL script
while read p; do
  f=${OUTBASE}/${YYYY}/ERAI.h1.${p}.nc
  ncl generateTrackerFilesERAI.ncl 'dateListArr="'${p}'"' 'SYMDIR="'${SYMDIR}'/'${YYYY}'"' 'OUTDIR="'${OUTBASE}'/'${YYYY}'"' 
done < ${arrayFileName}




