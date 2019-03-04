#!/bin/bash

NCLDIR=/glade/u/home/zarzycki/ncl/projects/ASD/LLJ/

cd /glade/u/home/zarzycki/scratch/ASD/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16.exp212/atm/hist/

for f in *.h2.*nc
do
  echo "$f"
  ncl ${NCLDIR}/extract-plev-winds.ncl 'filename="'$f'"'
done
