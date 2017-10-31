#!/bin/csh -f
# file: precip_dc.csh

#====================== variables set by user =======================================
setenv fincl h3
setenv case_desc $CASENAME

# hourly output over the entire globe, or regional like 0e_to_360e_45s_to_45n
#setenv coverage regional

#======================== end of modification =======================================

# TRIMM DJF:
setenv file_obs_DJF $VARDATA/hourly/TRIMM/TRIMM_DJF_v3.nc

# TRIMM JJA
setenv file_obs_JJA $VARDATA/hourly/TRIMM/TRIMM_JJA_v3.nc

cd $DIRPATH_DIURNAL

if( $firstyr_diurnal == $lastyr_diurnal ) then
setenv filename $WKDIR/$CASENAME.cam2.$fincl.{$firstyr_diurnal}.PRECT.nc
else
setenv filename $WKDIR/$CASENAME.cam2.$fincl.{$firstyr_diurnal}_to_{$lastyr_diurnal}.PRECT.nc
endif
echo $filename 

set year = $firstyr_diurnal
while( $year <= $lastyr_diurnal )
if( $year < 10 ) then
 set year_indicator = '000'$year
else if ( $year < 100 ) then
 set year_indicator = '00'$year
else if ( $year < 1000 ) then
 set year_indicator = '0'$year
else
 set year_indicator = $year
endif
if( $year == $firstyr_diurnal ) then
ls -l *h3.{$year_indicator}* | awk '{print $9}' > $WKDIR/files.diurnal.txt
else
ls -l *h3.{$year_indicator}* | awk '{print $9}' >> $WKDIR/files.diurnal.txt
endif
@ year = $year + 1
end


if( -e $filename) then
echo "file alreay processed"
else
set files = `cat $WKDIR/files.diurnal.txt`
ncrcat -v lat,lon,date,PRECT $files $filename
endif

if(! -d {$variab_dir}/hourly/$CASENAME) then
 mkdir  -p {$variab_dir}/hourly/$CASENAME
endif
cd {$variab_dir}/hourly/$CASENAME

setenv plot_dir {$variab_dir}/hourly/$CASENAME

#$NCL < $VARCODE/prect_hist_diurnal.ncl
#$NCL < $VARCODE/dc_v2.ncl
$NCL < /glade/u/home/zarzycki/ncl/projects/AMIP/climate/dc_phase.ncl

set img = png

foreach file ($WKDIR/VDIAG_{$CASENAME}/hourly/$CASENAME/*.ps)
 set file1 = $file:t
 convert $file $WKDIR/VDIAG_{$CASENAME}/hourly/$CASENAME/$file1:r.$img
end

if ( ! $?CLEAN ) set CLEAN = 1
#if ( $CLEAN ) rm -f {$WKDIR}/VDIAG_{$CASENAME}/hourly/$CASENAME/*.ps
#if ( $CLEAN ) rm -f $WKDIR/files.diurnal.txt


if(! -d {$variab_dir}/hourly/obs) then
 mkdir -p {$variab_dir}/hourly/obs
endif

cp $VARDATA/hourly/TRIMM/plots/*.png $WKDIR/VDIAG_{$CASENAME}/hourly/obs/.

cp $VARCODE/html/variab.html {$WKDIR}/VDIAG_{$CASENAME}
cp $VARCODE/html/diag_logo.gif {$WKDIR}/VDIAG_{$CASENAME}
cp $VARCODE/html/hourly/diurnal.html $WKDIR/VDIAG_{$CASENAME}/hourly/tmp.html
cat $WKDIR/VDIAG_{$CASENAME}/hourly/tmp.html  | sed -e s/xxx/$img/g | \
 sed -e s/casename/{$CASENAME}/g > $WKDIR/VDIAG_{$CASENAME}/hourly/diurnal.html
rm $WKDIR/VDIAG_{$CASENAME}/hourly/tmp.html
