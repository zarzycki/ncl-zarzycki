#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 23:00                   # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

basins=(NATL EPAC WPAC)
#configs=(slab)
configs=(slab slab2)

# Loop over items in outflds
for basin in ${basins[*]}
do
  for cfg in ${configs[*]}
  do
    ncl sst_anom_timeseries.ncl 'basin="'$basin'"' 'config="'$cfg'"'
  done
done

 
date 
