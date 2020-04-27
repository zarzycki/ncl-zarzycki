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

JRABASEDIR=~/rda/ds628.0/
SYMDIR=/glade/u/home/${LOGNAME}/scratch/JRAsym/
OUTBASE=/glade/scratch/${LOGNAME}/h1files/JRA/
YYYY=${1}

### Symlink JRA files
mkdir -p ${SYMDIR}/${YYYY}
rm ${SYMDIR}/${YYYY}/*.grb2

declare -a anl_mdl_arr=("vgrd" "ugrd" "hgt" "spfh" "tmp")
for i in "${anl_mdl_arr[@]}"
do
  FILES=${JRABASEDIR}/anl_mdl/${YYYY}/anl_mdl.*_${i}.reg_tl319.*
  for f in $FILES
  do
    echo "Processing $f file..."
    a=$(basename $f)
    ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
  done
done

declare -a anl_surf_arr=("pres" "tmp")
for i in "${anl_surf_arr[@]}"
do
  FILES=${JRABASEDIR}/anl_surf/${YYYY}/anl_surf.*_${i}.reg_tl319.*
  for f in $FILES
  do
    echo "Processing $f file..."
    a=$(basename $f)
    ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
  done
done

gpyyyy=$YYYY
if (( gpyyyy > 2014 )); then
  gpyyyy=2014
fi

declare -a tl319_arr=("gp")
for i in "${tl319_arr[@]}"
do
  FILES=${JRABASEDIR}/tl319/${gpyyyy}/tl319.*_${i}.reg_tl319.*
  for f in $FILES
  do
    echo "Processing $f file..."
    a=$(basename $f)
    a=${a/${gpyyyy}/$YYYY}
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
ncl generateTrackerFilesJRA-lite.ncl 'YEAR="'${YYYY}'"' 'timeArrFile="'${arrayFileName}'"'

rm ${arrayFileName}





CONFIG=JRA
OUTFILEDIR=/glade/scratch/${LOGNAME}/h1files/JRA/${YYYY}/
### Generate time array file
arrayFileName=test_timesArray_${YYYY}.txt
rm ${arrayFileName}
start=$(date -u --date '1 jan '${YYYY}' 0:00' +%s)
stop=$(date -u --date '31 dec '${YYYY}' 0:00' +%s)

for t in $(seq ${start} 86400 ${stop})
do
  thisDate=`date -u --date @${t} +'%Y%m%d'`
  echo $thisDate >> ${arrayFileName}
done

mkdir ${OUTFILEDIR}/TMP
mv ${OUTFILEDIR}/*.nc ${OUTFILEDIR}/TMP

while read p; do
  echo $p
  ncrcat ${OUTFILEDIR}/TMP/${CONFIG}.h1.${p}*.nc ${OUTFILEDIR}/${CONFIG}.h1.${p}.nc
done < ${arrayFileName}

rm ${arrayFileName}
rm -rf ${OUTFILEDIR}/TMP/
