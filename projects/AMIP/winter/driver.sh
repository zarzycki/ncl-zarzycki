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
#BSUB -P P35201098               # account number

################################################################

cd /glade/u/home/zarzycki/scratch/h2files/atl30x4/1993/
list=`ls atl_30_x4_refine_nochem.cam.h5*.nc`
cd /glade/u/home/zarzycki/ncl/projects/AMIP/winter
for f in ${list};
do
  string=$f
  echo $string
  read name model file date ext <<< ${string//[.: ]/ }
  read YYYY MM DD SSSSS <<< ${date//[-: ]/ }
  echo "YYYY=$YYYY, MM=$MM, DD=$DD"
  ncl -n printnewvars.ncl 'yearstr = "'$YYYY'"' 'monthstr = "'$MM'"' 'daystr = "'$DD'"'
done
