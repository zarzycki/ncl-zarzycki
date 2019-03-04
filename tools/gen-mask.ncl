;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/snow-tracking/calc_RSI/shapefile_ncl/shapefile_mask_data.ncl"
;========================================================

begin

gridformask="/glade/u/home/zarzycki/scratch/cfsr-severe/CFSR-SEVERE/single-file/cfsr-2000.nc"
varname="PRECT"
maskFileName="testmask.nc"

do_lon_flip=True

f=addfile(gridformask,"r")
ivar=f->$varname$(0,:,:)
ivar=1.

lon=-(360.-ivar&lon)
ivar&lon=lon

printVarSummary(ivar)

shp_filename="./conus/cb_2017_us_nation_20m.shp"
opt = True 
;opt@shape_var = "NAME" 
;opt@shape_names = (/"Pennsylvania","New Jersey","Delaware","Maryland","Massachusetts","New York","Connecticut","Vermont","Maine","Rhode Island","New Hampshire","District of Columbia"/)
opt@DEBUG="True"
ivar_mask = shapefile_mask_data(ivar,shp_filename,opt)
print(ivar_mask&lon)


  lon=360.+ivar_mask&lon
  ivar_mask&lon=lon


; output file
MASK=ivar_mask
MASK=where(ismissing(ivar_mask),0.0,1.0)
system("/bin/rm -f "+maskFileName)   ; remove any pre-existing file
ncdf = addfile(maskFileName ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )
ncdf->MASK  = MASK



end
