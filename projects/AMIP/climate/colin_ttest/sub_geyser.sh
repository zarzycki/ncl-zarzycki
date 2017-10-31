#!/bin/bash

##=======================================================================
#BSUB -a poe          # use LSF openmp elim
#BSUB -N              # send email at job finish
#BSUB -n 2            # number of processors
#BSUB -o ncl.%J       # output filename
#BSUB -e ncl.%J       # error filename
#BSUB -q geyser       # queue
#BSUB -J ncl_track    # job name
#BSUB -W 23:59        # wall clock limit
#BSUB -P P54048000     # account number

################################################################

ncl -n plot_diff_uni_ref.ncl
