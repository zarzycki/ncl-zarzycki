#!/bin/bash

### USAGE
# nohup ./process_h6.sh

path_to_tempest=/glade/p/work/zarzycki/tempestremap/
OUTDIR=/glade/scratch/zarzycki/
files=`ls ${OUTDIR}/offline_SSTA_fixedSST_1201*.nc`
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
    mv ${f}_tmp.nc ${f} 
    ./ApplyOfflineMap --map map_nhemi_30_x4_to_reg0.25RLL.nc --preserveall --in_data ${f} --out_data ${tmpFile} --fillvalue -999.
    ncrename -v lat,latitude ${tmpFile}
    ncrename -v lon,longitude ${tmpFile}
    ncl addLatLon.ncl lon_begin=${lon_st} lon_end=${lon_en} lat_begin=${lat_st} lat_end=${lat_en} 'filename="'${tmpFile}'"'
    ncl addTime.ncl 'filename="'${tmpFile}'"' 'timefile="'${f}'"'
    ncks -O --mk_rec_dmn time ${tmpFile} ${tmpFile}
    mv -v ${tmpFile} ${f}_regrid.nc
  fi
done

# files=`ls ${filesdir}/nhemi_30_x4*cam*${hstring}*_regrid.nc`
# shopt -s nullglob
# for f in $files
# do
#   echo $f
#   ncl /glade/u/home/zarzycki/ncl/projects/slab/cooling_component.ncl 'h6filename="'${f}'"'
# done
