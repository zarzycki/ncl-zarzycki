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

year=2000

for i in `seq 0 366`
do
    yyyy=`date -d "${year}-01-01 $i days" +%Y`
    mm=`date -d "${year}-01-01 $i days" +%m`
    dd=`date -d "${year}-01-01 $i days" +%d`
    echo ${yyyy}${mm}${dd}
    cd /glade/scratch/zarzycki/MERRA/
    modlevs=MERRA200.prod.assim.inst6_3d_ana_Nv.${yyyy}${mm}${dd}.hdf
    preslevs=MERRA200.prod.assim.inst6_3d_ana_Np.${yyyy}${mm}${dd}.hdf
    if [ ! -f ${modlevs} ]; then
      echo "Getting file"
      wget --quiet ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI6NVANA.5.2.0/${yyyy}/${mm}/${modlevs}
    fi
    if [ ! -f ${preslevs} ]; then
      echo "Getting file"
      wget --quiet ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI6NPANA.5.2.0/${yyyy}/${mm}/${preslevs}
    fi
    cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/MERRA
    ncl generateTrackerFilesMERRA.ncl 'YYYYMMDD="'${yyyy}${mm}${dd}'"'
done

date

