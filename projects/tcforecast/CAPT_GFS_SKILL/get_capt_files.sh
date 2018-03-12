#!/bin/bash

CAPTCONFIG=tratl_cam5.3_ne30_rneale
hsidir=/OLSON/csm/${CAPTCONFIG}/atm/hist/
gladedir=/glade/scratch/zarzycki/capt/${CAPTCONFIG}/

mkdir -p $gladedir
cd $gladedir

hsi cget ${hsidir}/*.nc
