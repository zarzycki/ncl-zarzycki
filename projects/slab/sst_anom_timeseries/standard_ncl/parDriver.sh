#!/bin/bash

### 1189 SLAB
### 1162 SLAB2
### 496 --> 08_7.05_900
### 451 --> 08_2.35_900
### 519 --> 05_4.7_900
### 502 --> 10_4.7_900
### 498 --> 10_11.75_900
### 458 --> SLAB3

# to find:
#-bash-4.1$ grep -r start cat_traj_slab_10_4.7_900.txt | wc -l
#502

TOTLINES=458
LINEPERFILE=15
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
