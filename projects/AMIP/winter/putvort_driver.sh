#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J hpss_get
#BSUB -W 23:59                    # wall clock limit
#BSUB -P P05010048               # account number

################################################################
year=2002
files=`ls /glade/u/home/zarzycki/scratch/h1files/ne30/${year}/*h1*nc`
shopt -s nullglob
for f in $files
do
  echo $f
  ncl put_vort_in_h1_files.ncl 'filename="'$f'"'
done
