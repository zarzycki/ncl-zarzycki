;======================================================================
; ESMF_regrid_18.ncl
;======================================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;filename="tcforecast_60_x4.cam.h0.2013-08-07-10800.nc"

mapping_dir = "/glade/u/home/zarzycki/work/maps/tcforecast_60_x4"
mapping_filename = "map_tcforecast_60_x4_TO_721x1440_patc.131123.nc"
mapping_file = mapping_dir+"/"+mapping_filename

strs = str_split_csv(filename,".",0)

grid=strs(0,0)
cam=strs(0,1)
filetype=strs(0,2)
date=strs(0,3)
extension=strs(0,4)

datestrs = str_split_csv(date,"-",0)

year=datestrs(0,0)
month=datestrs(0,1)
day=datestrs(0,2)
second=datestrs(0,3)

print("Doing file from date: "+year+month+day+"-"+second)

h2filename = grid+"."+cam+".h2."+year+"-"+month+"-"+day+"-"+second+"."+extension
h0filename = grid+"."+cam+".h0."+year+"-"+month+"-"+day+"-"+second+"."+extension
;wheredir = "/glade/scratch/zarzycki/sewx/test/"

h2file = addfile(wheredir+"/"+h2filename,"r")
h0file = addfile(wheredir+"/"+h0filename,"w")

print("Getting 3-D fields")
; These fields are in HOMME ncol structure
T=h2file->T
lev=h2file->lev

print("Interpolating 3-D fields to single level")
T400int = int2p_n_Wrap(lev,T,(/ 400. /),2,1)
T400SE = T400int(:,0,:)
delete(T400int)

print("Getting 1-D field")
; Get coordinates and a sample value in case we need them
time=h0file->time
lat=h0file->lat
lon=h0file->lon
U850=h0file->U850

print("Doing interpolation from SE->reg grid")
Opt         = True
T400  = ESMF_regrid_with_weights(T400SE,mapping_file,Opt)

print("Doing cleaning for missing values")
; Some values are missing using ESMF regridding for some reason so we'll
; fill them with a Poisson fill
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill(T400,is_cyclic, guess, nscan, eps, relc, opt)

print("Copying var coords (to be safe)")
copy_VarCoords(U850,T400)

print("Writing to file")
h0file->T400=T400

end

