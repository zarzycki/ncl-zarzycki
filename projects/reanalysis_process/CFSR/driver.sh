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

YEAR=2002

OUTPUTDIR=/glade/scratch/zarzycki/h1files/CFSR/${YEAR}
CFSRRAWDIR=/glade/scratch/zarzycki/CFSR/${YEAR}

echo $CFSRRAWDIR

mkdir -p $CFSRRAWDIR
cd $CFSRRAWDIR

cp /glade/p/rda/data/ds093.0/${YEAR}/ipvhnl.gdas.${YEAR}*.tar .
cp /glade/p/rda/data/ds093.0/${YEAR}/pgbhnl.gdas.${YEAR}*.tar .

for f in *.tar
do
  tar -xvf "$f"
done

rm *.tar

cd /glade/u/home/zarzycki/ncl/projects/reanalysis_process/CFSR/
mkdir -p ${OUTPUTDIR}

dates=`ls /glade/u/home/zarzycki/scratch/CFSR/${YEAR}/pgbhnl.gdas.*.grb2 | cut -c 54-63`
shopt -s nullglob
for f in $dates
do
  echo $f
  ncl generateTrackerFilesCFSR.ncl 'YYYYMMDD="'$f'"' 'outDir="'${OUTPUTDIR}'"'
done

rm -rf $CFSRRAWDIR/*.grb2
