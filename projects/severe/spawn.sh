#!/bin/bash

## This script is designed to spawn NUMYEARS instances of some script
## which is initiated for a given year

#1991-03-02-00000.nc
#1991-04-01-00000.nc
#1991-05-01-00000.nc
#1991-05-31-00000.nc
#1991-06-30-00000.nc
#1991-07-30-00000.nc
#1991-08-29-00000.nc
#1991-09-28-00000.nc

#declare -a arr=("1991-03-02-00000.nc" "1991-04-01-00000.nc" "1991-05-01-00000.nc" "1991-05-31-00000.nc" "1991-06-30-00000.nc" "1991-07-30-00000.nc" "1991-08-29-00000.nc" "1991-09-28-00000.nc")

#camconfig="ne30_g16.exp212"
camconfig="mp120a_g16.exp214"
#camconfig="ne0conus30x8_t12.exp211"
#camconfig="mp15a-120a-US_t12.exp213"
arr=(/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.${camconfig}/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.${camconfig}.cam.h2.*nc)

## now loop through the above array
for i in "${arr[@]}"
do
   if [[ ${i} != *"PRES"* ]]; then
     #echo "$i"
     tmp="$(cut -d'|' -f2 <<<" ${i/.h2./|} ")"
     ii="${tmp%%.*}"
     echo $ii
     sed -i "s?^thedate.*?thedate=\"${ii}\"?" chey-batch.sh
     sed -i "s?^camconfig.*?camconfig=\"${camconfig}\"?" chey-batch.sh
     qsub chey-batch.sh
     sleep 1
   fi
done
