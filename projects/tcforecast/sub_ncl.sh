#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 2                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # r filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 23:58                    # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

ncl errorStats.ncl

date 
