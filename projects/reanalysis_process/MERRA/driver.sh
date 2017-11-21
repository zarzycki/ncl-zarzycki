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

YEAR=1998
OUTDIR=/glade/scratch/zarzycki/MERRA
OUTPUTDIR=/glade/scratch/zarzycki/h1files/MERRA/${YEAR}
mkdir -p $OUTDIR
mkdir -p $OUTPUTDIR

for j in `seq 0 36`   # 0 36
do
  st=$(($j*10))
  en=$(($j*10+9))
  echo $st
  echo $en
  echo "-----"
  for i in `seq ${st} ${en}`
  do
  (  yyyy=`date -d "${YEAR}-01-01 $i days" +%Y`
    mm=`date -d "${YEAR}-01-01 $i days" +%m`
    dd=`date -d "${YEAR}-01-01 $i days" +%d`
    echo ${yyyy}${mm}${dd}
    cd ${OUTDIR}
    modlevs=MERRA200.prod.assim.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.hdf
    preslevs=MERRA200.prod.assim.inst6_3d_ana_Np.${yyyy}${mm}${dd}.hdf
    if [ ! -f ${modlevs} ]; then
      wget --quiet ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI6NVANA.5.2.0/${yyyy}/${mm}/${modlevs}
    fi
    if [ ! -f ${preslevs} ]; then
      wget --quiet ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI6NPANA.5.2.0/${yyyy}/${mm}/${preslevs}
    fi
    cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA
    ncl generateTrackerFilesMERRA.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"' 'outDir="'${OUTPUTDIR}'"' ) &
  done
  sleep 300
done

date

