#!/bin/bash

date

YEAR=${1}

#--------------------------------------------------------------------------------
CFSRRAWDIR=/glade/scratch/zarzycki/CFSR/${YEAR}/
OUTDIR=/glade/scratch/zarzycki/h1files/CFSR/${YEAR}/
#--------------------------------------------------------------------------------

mkdir -p $OUTDIR

mkdir -p $CFSRRAWDIR
cd $CFSRRAWDIR

# cp ~/rda/ds093.0/${YEAR}/ipvhnl.gdas.${YEAR}*.tar .
# cp ~/rda/ds093.0/${YEAR}/pgbhnl.gdas.${YEAR}*.tar .
# 
# for f in *.tar
# do
#   tar -xvf "$f"
# done
# rm *.tar

for f in ~/rda/ds093.0/${YEAR}/ipvhnl.gdas.${YEAR}*.tar
do
  tar -xvf "$f"
done
for f in ~/rda/ds093.0/${YEAR}/pgbhnl.gdas.${YEAR}*.tar .
do
  tar -xvf "$f"
done

cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/CFSR/
dates=`ls /glade/u/home/zarzycki/scratch/CFSR/${YEAR}/pgbhnl.gdas.*.grb2 | cut -c 54-63`
shopt -s nullglob
for f in $dates
do
  start=`date +%s`
  echo $f
  ncl generateTrackerFilesCFSR-lite.ncl 'YYYYMMDD="'$f'"' 'outDir="'$OUTDIR'"'
  end=`date +%s`
  echo "         "
  echo "-------   "$((end-start))" seconds"
  echo "         "
done

#!/bin/bash

YYYY=${YEAR}
CONFIG=CFSR
OUTFILEDIR=/glade/scratch/zarzycki/h1files/CFSR/${YYYY}/

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

date

rm -rf $CFSRRAWDIR/*.grb2
