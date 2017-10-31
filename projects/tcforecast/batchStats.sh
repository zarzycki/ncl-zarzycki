#!/bin/bash

##=============================================================
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

declare -a plotArr=("all_ts" "cam_highres" "all_hurr" "cam_sst" "cam_resolution" "cam_clubb" "cam_sens")
declare -a metricArr=("TK_ERR" "WIND_ERR" "WIND_BIAS" "TK_ALL" "WIND_ALL" "MSLP_ERR")
for j in "${plotArr[@]}"
do
for i in "${metricArr[@]}"
do
  ncl errorStats.ncl 'metric="'${i}'"' 'whatPlot="'${j}'"'
done
done
