#!/bin/bash

#  for DATA_YEAR in $(eval echo {$STARTYEAR..$ENDYEAR})
#  do
#    for DATA_MONTH in 01 02 03 04 05 06 07 08 09 10 11 12
#    do
      for DATA_DAY in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
      do

      wget ftp://goldsmr3.sci.gsfc.nasa.gov/data/s4pa/MERRA/MAI3CPASM.5.2.0/2005/08/MERRA300.prod.assim.inst3_3d_asm_Cp.200508${DATA_DAY}.hdf

      ncl_convert2nc MERRA300.prod.assim.inst3_3d_asm_Cp.200508${DATA_DAY}.hdf
      
      rm MERRA300.prod.assim.inst3_3d_asm_Cp.200508${DATA_DAY}.hdf
      
      mv MERRA300.prod.assim.inst3_3d_asm_Cp.200508${DATA_DAY}.nc MERRAfile.nc
      
      ncl process_MERRA.ncl

      rm MERRAfile.nc
      
      done

#    done

#  done
