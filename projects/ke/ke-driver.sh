#!/bin/bash

CONFIG="hindcast_conus_30_x8_CAM5_L59"

RGDWGTS="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.25x0.25glob_patch.nc"
#RGDWGTS="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.25x0.25glob_patch.nc"
#RGDWGTS="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"
#RGDWGTS="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"

spectrumoutname="spectrum_"${CONFIG}".nc"
#FILES=/glade/u/home/zarzycki/acgd0005/CMZ/HINDCASTS/${CONFIG}/2017123100/*h0*

unset FILES
ii=0
for dir in /glade/u/home/zarzycki/acgd0005/CMZ/HINDCASTS/${CONFIG}/*; do
  arr=`ls -d $dir/*h0*.nc | tail -n 1`
  FILES[$i]=$arr
  ((i++))
done

for f in "${FILES[@]}"
do
  echo "Processing $f file..."
  ncl calc-ke-regglob.ncl 'anlfilename="'${f}'"' 'specfilename="'${spectrumoutname}'"' 'regrid_wgts="'${RGDWGTS}'"'
done
