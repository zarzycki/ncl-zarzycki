#!/bin/bash

CONFIG="hindcast_conus_30_x8_CAM5_L30"
spectrumoutname="spectrum_"${CONFIG}".nc"
FILES=/glade/u/home/zarzycki/acgd0005/CMZ/HINDCASTS/${CONFIG}/2017123100/*h0*
for f in $FILES
do
  echo "Processing $f file..."
  ncl calc-ke-regglob.ncl 'anlfilename="'${f}'"' 'specfilename="'${spectrumoutname}'"'
done

