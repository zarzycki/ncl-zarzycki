#!/bin/bash

module load ncl

WGTFILE=/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_1.0x1.0_GLOB.nc
CONFIG=$1

cd /glade/u/home/zarzycki/scratch/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.${CONFIG}/atm/hist/

for aa in *.h0.*.tar
do
  echo "Untarring $aa"
  tar -xvf $aa
done

FILES=`find -name "*????-[01][890].nc" | grep -v 1984- | grep -v 1994- | sort -n`
for f in $FILES
do
  echo $f `basename $f`_regrid.nc
  rm `basename $f`_regrid.nc
  ncremap -i $f -o `basename $f`_regrid.nc -m $WGTFILE
done

echo "Averaging regridded h0 files"
ncra CHEY.VR28.NATL.REF.CAM5.4CLM5.0.${CONFIG}.cam.h0.????-??.nc_regrid.nc CHEY.VR28.NATL.REF.CAM5.4CLM5.0.${CONFIG}.cam.h0.AVG.nc_regrid.nc

#cd /glade/u/home/zarzycki/ncl/projects/domain-sens/tau-sens/data-process/
#ncl CAM5_BAM_var_GPI_chi_comps_h0.ncl 'OUTSTRING="'${CONFIG}'"'

#cd ~/scratch/
#ncra GPI_${CONFIG}.nc GPI_${CONFIG}.nc_AVG.nc
#mv GPI_${CONFIG}.nc_AVG.nc /glade/u/home/zarzycki/ncl/projects/domain-sens/tau-sens/MPI_GPI/
