#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J sub_ncl 
#BSUB -W 23:59                  # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

STARTYEAR=1219
ENDYEAR=1225

CONFIG=fixedSST
OUTDIR=/glade/scratch/zarzycki/nhemi_30_x4_OFFLINE/

path_to_tempest=/glade/p/work/zarzycki/tempestremap/
NCLDIR=/glade/u/home/zarzycki/ncl/projects/slab/sst-vs-cooling

mkdir -p $OUTDIR

for YEAR in $(eval echo {$STARTYEAR..$ENDYEAR})
do
  ################################################################
  cd $NCLDIR
  ncl integrate-sst-cooling.ncl 'whatConfig="'${CONFIG}'"' 'whatYear="'${YEAR}'"' 'outDir="'${OUTDIR}'"'
  ################################################################
  files=`ls ${OUTDIR}/offline_SSTA_${CONFIG}_${YEAR}*.nc | grep -v regrid.nc`
  shopt -s nullglob
  for f in $files
  do
    echo $f
    if [ ! -f ${f}_regrid.nc ]; then
      echo "Need to regrid"
      randStr=`date +%s%N`
      tmpFile=tmp.${randStr}.nc
      cd $path_to_tempest
      lon_st=95
      lon_en=355
      lat_st=0
      lat_en=60
      ./ApplyOfflineMap --map map_nhemi_30_x4_to_reg0.25RLL.nc --preserveall --in_data ${f} --out_data ${tmpFile} --fillvalue -999.
      ncl addLatLon.ncl lon_begin=${lon_st} lon_end=${lon_en} lat_begin=${lat_st} lat_end=${lat_en} 'filename="'${tmpFile}'"'
      ncl addTime.ncl 'filename="'${tmpFile}'"' 'timefile="'${f}'"'
      ncks -O --mk_rec_dmn time ${tmpFile} ${tmpFile}
      mv -v ${tmpFile} ${f}_regrid.nc
    fi
  done
  ################################################################
done

date 
