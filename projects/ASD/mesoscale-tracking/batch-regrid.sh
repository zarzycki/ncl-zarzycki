#!/bin/bash

YYYY=1984
GRID=mp15a-120a-US_t12.exp004  #mp15a-120a-US_t12.exp004, mp120a_g16.exp005

FILES=`ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.${GRID}/atm/hist/f.asd2017.*.cam.h4.${YYYY}-06*.nc /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.${GRID}/atm/hist/f.asd2017.*.cam.h4.${YYYY}-07*.nc /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.${GRID}/atm/hist/f.asd2017.*.cam.h4.${YYYY}-05*.nc`
shopt -s nullglob
#for f in /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005.cam.h4.1988-06*.nc
for f in $FILES
do
  echo $f
  ncl process-h4-data-RLL.ncl 'h4filename="'${f}'"'
done
