#!/bin/bash

date

YEAR=2005

#--------------------------------------------------------------------------------
CFSRRAWDIR=/glade/scratch/zarzycki/CFSR/${YEAR}/
OUTDIR=/glade/u/home/zarzycki/scratch/gen-nudge/
#--------------------------------------------------------------------------------

mkdir -p $OUTDIR

mkdir -p $CFSRRAWDIR
cd $CFSRRAWDIR

# for f in ~/rda/ds093.0/${YEAR}/ipvhnl.gdas.${YEAR}*.tar
# do
#   tar -xvf "$f"
# done

# for f in ~/rda/ds093.0/${YEAR}/pgbhnl.gdas.${YEAR}*.tar .
# do
#   tar -xvf "$f"
# done

dates=`ls ${CFSRRAWDIR}/pgbhnl.gdas.*.grb2 | cut -c 48-57`
shopt -s nullglob
for f in $dates
do
  start=`date +%s`
  echo $f
  YYYY=${f:0:4}
  MM=${f:4:2}
  DD=${f:6:2}
  HH=${f:8:2}
  SS=$(( 3600*HH ))
  printf -v SSSSS "%05d" $SS
  
  ## Begin betacast block
  BETACASTDIR=/glade/u/home/zarzycki/betacast/
  YYYYMMDDHH=${f}
  
  GRIDSTR=ne0natlanticref30x4
  BNDTOPO=/glade/u/home/zarzycki/work/unigridFiles/ne0np4natlanticref.ne30x4/topo/topo_ne0np4natlanticref.ne30x4_smooth.nc
  WGTNAME=/glade/work/zarzycki/maps/gfsmaps/map_gfs0.50_TO_natlantic_30_x4_patc.nc

  #GRIDSTR=ne0conus30x8
  #BNDTOPO=/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/se/ne30x8_conus_nc3000_Co060_Fi001_MulG_PF_nullRR_Nsw042_20190710.nc
  #WGTNAME=/glade/work/zarzycki/maps/gfsmaps//map_gfs-0.50_TO_conus_30_x8_patc.nc
  
  #GRIDSTR=ne30
  #BNDTOPO=/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/se/ne30np4_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171020.nc
  #WGTNAME=/glade/u/home/zarzycki/work/maps/gfsmaps/map_gfs0.50_TO_ne30np4_patc.nc
  
  INFILE=/glade/scratch/zarzycki/CFSR/2005/pgbhnl.gdas.${YYYYMMDDHH}.grb2
  OUTFILE=/glade/scratch/zarzycki/gen-nudge/ndg.CFSR.${GRIDSTR}.L32.cam2.i.$YYYY-$MM-$DD-$SSSSS.nc
  
  cd ${BETACASTDIR}/atm_to_cam/
  ncl -n atm_to_cam.ncl 'datasource="CFSR"' compress_file=True numlevels=32 YYYYMMDDHH=${YYYYMMDDHH} 'data_filename = "'${INFILE}'"' 'wgt_filename="'${WGTNAME}'"' 'model_topo_file="'${BNDTOPO}'"' 'adjust_config="a"' 'se_inic = "'${OUTFILE}'"'
  ##
  
  end=`date +%s`
  echo "         "
  echo "$YYYY $MM $DD $HH $SSSSS"
  echo "-------   "$((end-start))" seconds"
  echo "         "
done

date

#rm -rf $CFSRRAWDIR/*.grb2
