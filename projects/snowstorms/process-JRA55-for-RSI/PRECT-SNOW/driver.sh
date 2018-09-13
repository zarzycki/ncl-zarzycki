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

JRABASEDIR=/gpfs/fs1/collections/rda/data/ds628.0/
SYMDIR=/glade/u/home/zarzycki/scratch/JRAsym/
OUTBASE=/glade/scratch/zarzycki/h1files/JRA/

for YYYY in `seq 1959 1959`; do

  if [ ! -f ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PRECT.nc ]; then

    echo ${OUTBASE}/${YYYY}/JRA.h1.${YYYY}.PRECT.nc" does not exist"

    ### Symlink JRA files
    mkdir -p ${SYMDIR}/${YYYY}
#    rm ${SYMDIR}/${YYYY}/*.grb2

    declare -a prect_arr=("srweq" "tprat")
    for i in "${prect_arr[@]}"
    do
      if [ "${i}" == "prmsl" ]; then
        FILES=${JRABASEDIR}/fcst_surf/${YYYY}/*_${i}.reg_tl319.*
      else
        FILES=${JRABASEDIR}/fcst_phy2m/${YYYY}/*_${i}.reg_tl319.*
      fi
      for f in $FILES
      do
        echo "Processing $f file..."
        a=$(basename $f)
        rm ${SYMDIR}/${YYYY}/${a}.grb2
        ln -s ${f} ${SYMDIR}/${YYYY}/${a}.grb2
      done
    done

    ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="srweq"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'
    ncl generateTrackerFilesJRA.ncl 'YYYY="'${YYYY}'"' 'VAR="tprat"' 'SYMDIR="'${SYMDIR}/${YYYY}'"' 'OUTDIR="'${OUTBASE}/${YYYY}'"'

  fi

done
