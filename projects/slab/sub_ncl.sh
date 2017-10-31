#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 12:00                   # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

ncl getSSTs.ncl minWind=0.0 maxWind=999.9 latBox=0.25
ncl getSSTs.ncl minWind=0.0 maxWind=999.9 latBox=1.0
ncl getSSTs.ncl minWind=0.0 maxWind=999.9 latBox=3.6
ncl getSSTs.ncl minWind=0.0 maxWind=999.9 latBox=5.0
ncl getSSTs.ncl minWind=32.0 maxWind=999.9 latBox=1.0
 
date 
