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

declare -a anl_mdl_arr=("spfh" "tmp")
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

declare -a anl_surf_arr=("pres")
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
