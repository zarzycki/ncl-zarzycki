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

ncl bourgouin.ncl
