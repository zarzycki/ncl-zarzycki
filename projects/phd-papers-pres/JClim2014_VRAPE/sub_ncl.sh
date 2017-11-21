#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 23:55                    # wall clock limit
#BSUB -P P35201098               # account number

################################################################

##ncl mjo_clivar14.ncl
ncl wkSpaceTime_panel.ncl
##ncl regrid_file.ncl
##ncl kelvinfilter.ncl
##ncl hist_precip.ncl
##ncl wheelerkiladis.ncl 
