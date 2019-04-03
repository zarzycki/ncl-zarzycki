;========================================================
;
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;YYYYMMDD="20051231"
write_output = True
interp_lon = False
do_flip = True ; flip lon from -180-180 to 0-360

;ncl generateTrackerFilesMERRA.ncl 'YYYYMMDD="2005082800"'

; Get YYYYMMDDHH from the initdate string
dtime_map = (/4,2,2/)
tst_dtime = str_split_by_length(YYYYMMDD, dtime_map)
yyyy=tst_dtime(0)
mm=tst_dtime(1)
dd=tst_dtime(2)
print("Processing: "+yyyy+" "+mm+" "+dd)

presLevDir = "/glade/u/home/zarzycki/scratch/MERRA/"
modlLevDir = "/glade/u/home/zarzycki/scratch/MERRA/"
presLevFlName = "MERRA"+streamString+".prod.assim.inst6_3d_ana_Np."+yyyy+mm+dd+".hdf"
modlLevFlName = "MERRA"+streamString+".prod.assim.inst6_3d_ana_Nv."+yyyy+mm+dd+".hdf"
print("PRES LEVS:    "+presLevDir+"/"+presLevFlName)
print("MODL LEVS:    "+modlLevDir+"/"+modlLevFlName)

presLevFile = addfile(presLevDir+"/"+presLevFlName,"r")
modlLevFile = addfile(modlLevDir+"/"+modlLevFlName,"r")

timeOrig = presLevFile->TIME_EOSGRID
; Cleaning up time

utc_date = cd_calendar(timeOrig, 0)
year   = tointeger(utc_date(:,0))
month  = tointeger(utc_date(:,1))
day    = tointeger(utc_date(:,2))
hour   = tointeger(utc_date(:,3))
minute = tointeger(utc_date(:,4))
second = utc_date(:,5)
newunits = "days since "+yyyy+"-"+mm+"-"+dd+" 00:00:00"
time = cd_inv_calendar(year,month,day,hour,minute,second,newunits, 0) 
  
latitude  = presLevFile->YDim_EOSGRID
longitude = presLevFile->XDim_EOSGRID
preslevs = presLevFile->Height_EOSGRID

U850 = presLevFile->U(:,{850},:,:)
V850 = presLevFile->V(:,{850},:,:)

T400 = presLevFile->T(:,{400},:,:)

Z500 = presLevFile->H(:,{500},:,:)
Z300 = presLevFile->H(:,{300},:,:)

PSL  = presLevFile->SLP(:,:,:)
PS   = presLevFile->PS(:,:,:)

modllevs = modlLevFile->Height_EOSGRID

UBOT = modlLevFile->U(:,(dimsizes(modllevs)-1),:,:)
VBOT = modlLevFile->V(:,(dimsizes(modllevs)-1),:,:)
TBOT = modlLevFile->T(:,(dimsizes(modllevs)-1),:,:)


; Poisson grid filling since MERRA on pressure levels are not filled in
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 1500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.6              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill(U850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(V850, is_cyclic, guess, nscan, eps, relc, opt)


poisson_grid_fill(T400, is_cyclic, guess, nscan, eps, relc, opt)

poisson_grid_fill(Z500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z300, is_cyclic, guess, nscan, eps, relc, opt)

; we need to interpolate to 0.5deg by 0.5deg. this is only for longitude

if(interp_lon) then
  degRes = 0.5
  lonFloat = fspan(-180,180-degRes,toint(360/degRes))
  lon = todouble(lonFloat)
  copy_VarAtts(longitude,lon)
  lat = latitude ; we will keep lat and latitude the same
  U850_= linint2(longitude,latitude,U850,True,lon,lat,0)
  V850_= linint2(longitude,latitude,V850,True,lon,lat,0)
  UBOT_= linint2(longitude,latitude,UBOT,True,lon,lat,0)
  VBOT_= linint2(longitude,latitude,VBOT,True,lon,lat,0)
  PSL_ = linint2(longitude,latitude,PSL ,True,lon,lat,0)
  PS_ = linint2(longitude,latitude,PS ,True,lon,lat,0)
  T400_= linint2(longitude,latitude,T400,True,lon,lat,0)
  Z500_= linint2(longitude,latitude,Z500,True,lon,lat,0)
  Z300_= linint2(longitude,latitude,Z300,True,lon,lat,0)
else
  lat = latitude
  lon = longitude
  U850_= U850
  V850_= V850
  UBOT_= UBOT
  VBOT_= VBOT
  PSL_ = PSL
  PS_ = PS
  T400_= T400
  Z500_= Z500
  Z300_= Z300
end if

if (do_flip) then
  lon := lonFlip(lon)
  U850_ := lonFlip(U850_)
  V850_ := lonFlip(V850_)
  UBOT_ := lonFlip(UBOT_)
  VBOT_ := lonFlip(VBOT_)
  PSL_  := lonFlip(PSL_)
  PS_   := lonFlip(PS_)
  T400_ := lonFlip(T400_)
  Z500_ := lonFlip(Z500_)
  Z300_ := lonFlip(Z300_)
  lon := where(lon .lt. 0.0,lon+360.,lon)
end if

U850_!0    = "time"
U850_!1    = "lat"
U850_!2    = "lon"
U850_&time = time
U850_&lat  = lat
U850_&lon  = lon 
copy_VarMeta(U850_,V850_)
copy_VarMeta(U850_,UBOT_)
copy_VarMeta(U850_,VBOT_)

copy_VarMeta(U850_,PSL_)
copy_VarMeta(U850_,PS_)

copy_VarMeta(U850_,T400_)

copy_VarMeta(U850_,Z300_)
copy_VarMeta(U850_,Z500_)

delete_VarAtts(U850_, -1)
U850_@long_name="850 hPa zonal wind"
U850_@units="m/s"
delete_VarAtts(UBOT_, -1)
UBOT_@long_name="Lowest model level zonal wind"
UBOT_@units="m/s"

delete_VarAtts(V850_, -1)
V850_@long_name="850 hPa meridional wind"
V850_@units="m/s"
delete_VarAtts(VBOT_, -1)
VBOT_@long_name="Lowest model level meridional wind"
VBOT_@units="m/s"

delete_VarAtts(T400_, -1)
T400_@long_name="400 hPa temperature"
T400_@units="K"

delete_VarAtts(PSL_, -1)
PSL_@long_name="Mean sea level pressure"
PSL_@units="Pa"
delete_VarAtts(PS_, -1)
PS_@long_name="Surface pressure"
PS_@units="Pa"

delete_VarAtts(Z500_, -1)
Z500_@long_name="500 hPa geopotential height"
Z500_@units="m"
delete_VarAtts(Z300_, -1)
Z300_@long_name="300 hPa geopotential height"
Z300_@units="m"

if (write_output) then
	outFileName = "MERRA.h1."+yyyy+mm+dd+".nc"
	system("/bin/rm -f "+outDir+"/"+outFileName)   ; remove any pre-existing file
	ncdf     = addfile(outDir+"/"+outFileName ,"c")  ; open output netCDF file
	print("Writing output file:  "+outDir+"/"+outFileName)
	; make time and UNLIMITED dimension      ; recommended  for most applications
	filedimdef(ncdf,"time",-1,True) 

	;ncdf->lat = lat
	;ncdf->lon = lon

	ncdf->U850 = U850_         
	ncdf->V850 = V850_
	ncdf->UBOT = UBOT_         
	ncdf->VBOT = VBOT_
	ncdf->T400 = T400_  
	ncdf->PSL  = PSL_
	ncdf->PS  = PS_
	ncdf->Z300 = Z300_ 
	ncdf->Z500 = Z500_

end if

end
