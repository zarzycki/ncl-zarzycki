#!/bin/bash

TOTLINES=1162
LINEPERFILE=30
let NUMLOOP=($TOTLINES+$LINEPERFILE-1)/$LINEPERFILE; echo $NUMLOOP

for i in $(seq 1 $NUMLOOP)
do
  START=$(( (i-1)*LINEPERFILE ))
  END=$(( (i*LINEPERFILE)-1 ))
  if [ "$i" -eq "$NUMLOOP" ] ; then
    END=$(( TOTLINES-1 ))
  fi
  echo $START $END
  sed -i "s?^START.*?START=${START}?" sub_ncl.sh
  sed -i "s?^END.*?END=${END}?" sub_ncl.sh
  bsub < sub_ncl.sh
  sleep 2
done
