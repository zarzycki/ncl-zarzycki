#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 8:00                    # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

#ncl se_native_internalinterp.ncl 
#ncl gen_SE_to_latlon_wgts.ncl 
 
date 
