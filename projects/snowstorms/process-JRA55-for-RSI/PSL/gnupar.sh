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

for YYYY in `seq 1975 1975`; do

JRABASEDIR=/gpfs/fs1/collections/rda/data/ds628.0//
SYMDIR=/glade/u/home/zarzycki/scratch/JRAsym/
OUTBASE=/glade/scratch/zarzycki/h1files/JRA/
#YYYY=1994

### Symlink JRA files
mkdir -p ${SYMDIR}/${YYYY}
#rm ${SYMDIR}/${YYYY}/*.grb2

declare -a anl_surf_arr=("pres" "tmp")
for i in "${anl_surf_arr[@]}"
do
  FILES=${JRABASEDIR}/anl_surf/${YYYY}/anl_surf.*_${i}.reg_tl319.*
  for f in $FILES
  do
    echo "Processing $f file..."
    a=$(basename $f)
    rm ${SYMDIR}/${YYYY}/${a}.grb2
    ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
  done
done

declare -a tl319_arr=("gp")
for i in "${tl319_arr[@]}"
do
  if [ ${YYYY} -gt 2014 ]; then
    FILES=${JRABASEDIR}/tl319/2014/tl319.*_${i}.reg_tl319.*
  else
    FILES=${JRABASEDIR}/tl319/${YYYY}/tl319.*_${i}.reg_tl319.*
  fi
  for f in $FILES
  do
    echo "Processing $f file..."
    a=$(basename $f)
    rm ${SYMDIR}/${YYYY}/${a}.grb2
    ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
  done
done

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

### Make output dir
mkdir -p ${OUTBASE}/${YYYY}

### Do NCL script
ncl generateTrackerFilesJRA.ncl 'YEAR="'${YYYY}'"' 'timeArrFile="'${arrayFileName}'"'

ncrcat -O ${OUTBASE}/${YYYY}/tmp.JRA*${YYYY}*nc ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PSL.nc
rm ${OUTBASE}/${YYYY}/tmp.JRA*${YYYY}*nc

rm ${arrayFileName}

done
