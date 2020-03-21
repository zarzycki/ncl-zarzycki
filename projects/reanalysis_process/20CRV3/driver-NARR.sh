#!/bin/bash -l

date

YEAR=${1}

#--------------------------------------------------------------------------------
NARRRAWDIR=/glade/scratch/zarzycki/NARR/${YEAR}/
OUTDIR=/glade/scratch/zarzycki/h1files/NARR/${YEAR}/
#--------------------------------------------------------------------------------

mkdir -p $OUTDIR

mkdir -p $NARRRAWDIR
cd $NARRRAWDIR

for f in ~/rda/ds608.0/3HRLY/${YEAR}/NARR3D_${YEAR}*.tar
do
  tar -xvf "$f"
done
for f in ~/rda/ds608.0/3HRLY/${YEAR}/NARRflx_${YEAR}*.tar
do
  tar -xvf "$f"
done
for f in ~/rda/ds608.0/3HRLY/${YEAR}/NARRsfc_${YEAR}*.tar
do
  tar -xvf "$f"
done

# # Append grb2 extension to everything
for f in * ; do 
  mv "$f" "$f.grb2"
done

cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/NARR/
dates=`ls -1 /glade/u/home/zarzycki/scratch/NARR/${YEAR}/merged_AWIP32.*.3D.grb2 | cut -c 56-65`
shopt -s nullglob
for f in $dates
do
  ncl generateTrackerFilesNARR-esmf.ncl 'YYYYMMDD="'$f'"' 'outDir="'$OUTDIR'"'
done

YYYY=${YEAR}
CONFIG=NARR
OUTFILEDIR=/glade/scratch/zarzycki/h1files/NARR/${YYYY}/

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

rm -rf $NARRRAWDIR/*.grb2
