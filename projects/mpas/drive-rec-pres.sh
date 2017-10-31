#!/bin/bash

CONFIG=mp120a_g16
DIR=/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.${CONFIG}/atm/hist/
HISTFILES=`ls ${DIR}/*h2*1979*.nc | grep -v PRES`

shopt -s nullglob
for HISTFILE in ${HISTFILES}
do
  if [ ! -f ${HISTFILE}.PRES.nc ]; then
    echo $HISTFILE
    #ncl recover-pressure.ncl 'histfilename="'${HISTFILE}'"'
  fi
done



#HISTFILE="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.cam.h2.1979-01-01-00000.nc"



date 
