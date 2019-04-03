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
U700 = presLevFile->U(:,{700},:,:)
V700 = presLevFile->V(:,{700},:,:)
U500 = presLevFile->U(:,{500},:,:)
V500 = presLevFile->V(:,{500},:,:)
U200 = presLevFile->U(:,{200},:,:)
V200 = presLevFile->V(:,{200},:,:)

T200 = presLevFile->T(:,{200},:,:)
T300 = presLevFile->T(:,{300},:,:)
T400 = presLevFile->T(:,{400},:,:)
T500 = presLevFile->T(:,{500},:,:)
T700 = presLevFile->T(:,{700},:,:)
T850 = presLevFile->T(:,{850},:,:)

Z1000= presLevFile->H(:,{1000},:,:)
Z850=  presLevFile->H(:,{850},:,:)
Z500 = presLevFile->H(:,{500},:,:)
Z400 = presLevFile->H(:,{400},:,:)
Z300 = presLevFile->H(:,{300},:,:)
Z200 = presLevFile->H(:,{200},:,:)

PSL  = presLevFile->SLP(:,:,:)
PS   = presLevFile->PS(:,:,:)

modllevs = modlLevFile->Height_EOSGRID

UBOT = modlLevFile->U(:,(dimsizes(modllevs)-1),:,:)
VBOT = modlLevFile->V(:,(dimsizes(modllevs)-1),:,:)
TBOT = modlLevFile->T(:,(dimsizes(modllevs)-1),:,:)

ZBOT = (287.0*TBOT/9.81)*log(PS/97662.)

; Poisson grid filling since MERRA on pressure levels are not filled in
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 1500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.6              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill(U850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(V850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(U700, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(V700, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(U500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(V500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(U200, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(V200, is_cyclic, guess, nscan, eps, relc, opt)

poisson_grid_fill(T200, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(T300, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(T400, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(T500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(T700, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(T850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z1000,is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z400, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z300, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z200, is_cyclic, guess, nscan, eps, relc, opt)

; we need to interpolate to 0.5deg by 0.5deg. this is only for longitude

if(interp_lon) then
  degRes = 0.5
  lonFloat = fspan(-180,180-degRes,toint(360/degRes))
  lon = todouble(lonFloat)
  copy_VarAtts(longitude,lon)
  lat = latitude ; we will keep lat and latitude the same
  U850_= linint2(longitude,latitude,U850,True,lon,lat,0)
  V850_= linint2(longitude,latitude,V850,True,lon,lat,0)
  U700_= linint2(longitude,latitude,U700,True,lon,lat,0)
  V700_= linint2(longitude,latitude,V700,True,lon,lat,0)
  U500_= linint2(longitude,latitude,U500,True,lon,lat,0)
  V500_= linint2(longitude,latitude,V500,True,lon,lat,0)
  U200_= linint2(longitude,latitude,U200,True,lon,lat,0)
  V200_= linint2(longitude,latitude,V200,True,lon,lat,0)
  UBOT_= linint2(longitude,latitude,UBOT,True,lon,lat,0)
  VBOT_= linint2(longitude,latitude,VBOT,True,lon,lat,0)
  PSL_ = linint2(longitude,latitude,PSL ,True,lon,lat,0)
  PS_ = linint2(longitude,latitude,PS ,True,lon,lat,0)
  T200_= linint2(longitude,latitude,T200,True,lon,lat,0)
  T300_= linint2(longitude,latitude,T300,True,lon,lat,0)
  T400_= linint2(longitude,latitude,T400,True,lon,lat,0)
  T500_= linint2(longitude,latitude,T500,True,lon,lat,0)
  T700_= linint2(longitude,latitude,T700,True,lon,lat,0)
  T850_= linint2(longitude,latitude,T850,True,lon,lat,0)
  ZBOT_=linint2(longitude,latitude,ZBOT,True,lon,lat,0)
  Z1000_=linint2(longitude,latitude,Z1000,True,lon,lat,0)
  Z850_= linint2(longitude,latitude,Z850,True,lon,lat,0)
  Z500_= linint2(longitude,latitude,Z500,True,lon,lat,0)
  Z400_= linint2(longitude,latitude,Z400,True,lon,lat,0)
  Z300_= linint2(longitude,latitude,Z300,True,lon,lat,0)
  Z200_= linint2(longitude,latitude,Z200,True,lon,lat,0)
else
  lat = latitude
  lon = longitude
  U850_= U850
  V850_= V850
  U700_= U700
  V700_= V700
  U500_= U500
  V500_= V500
  U200_= U200
  V200_= V200
  UBOT_= UBOT
  VBOT_= VBOT
  PSL_ = PSL
  PS_ = PS
  T200_= T200
  T300_= T300
  T400_= T400
  T500_= T500
  T700_= T700
  T850_= T850
  ZBOT_=ZBOT
  Z1000_=Z1000
  Z850_= Z850
  Z500_= Z500
  Z400_= Z400
  Z300_= Z300
  Z200_= Z200
end if

U850_!0    = "time"
U850_!1    = "lat"
U850_!2    = "lon"
U850_&time = time
U850_&lat  = lat
U850_&lon  = lon 
copy_VarMeta(U850_,V850_)
copy_VarMeta(U850_,U700_)
copy_VarMeta(U850_,V700_)
copy_VarMeta(U850_,U500_)
copy_VarMeta(U850_,V500_)
copy_VarMeta(U850_,U200_)
copy_VarMeta(U850_,V200_)
copy_VarMeta(U850_,UBOT_)
copy_VarMeta(U850_,VBOT_)

copy_VarMeta(U850_,PSL_)
copy_VarMeta(U850_,PS_)

copy_VarMeta(U850_,T200_)
copy_VarMeta(U850_,T300_)
copy_VarMeta(U850_,T400_)
copy_VarMeta(U850_,T500_)
copy_VarMeta(U850_,T700_)
copy_VarMeta(U850_,T850_)

copy_VarMeta(U850_,Z200_)
copy_VarMeta(U850_,Z300_)
copy_VarMeta(U850_,Z400_)
copy_VarMeta(U850_,Z500_)
copy_VarMeta(U850_,Z850_)
copy_VarMeta(U850_,Z1000_)
copy_VarMeta(U850_,ZBOT_)

print("Calculating Vorts")
VR850 = V850_
VR850 = uv2vrF(U850_,V850_)

VR500 = V500_
VR500 = uv2vrF(U500_,V500_)

VR200 = V200_
VR200 = uv2vrF(U200_,V200_)

latsign = lat
latsign = where(lat .lt. 0.0,-1.0,1.0)
printVarSummary(latsign)
printVarSummary(U850_)
latsign2d = tofloat(conform(U850_,latsign,1))

VR850 = VR850*latsign2d
VR500 = VR500*latsign2d
VR200 = VR200*latsign2d

; Smoothing
VR850SM = smth9_Wrap(VR850, 0.50, 0.50, True)
VR500SM = smth9_Wrap(VR500, 0.50, 0.50, True)
VR200SM = smth9_Wrap(VR200, 0.50, 0.50, True)
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 50             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( VR850SM, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VR500SM, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VR200SM, is_cyclic, guess, nscan, eps, relc, opt)

print("Smoothing vort")
; Regrid VR850, VR500, VR200 for Hodges tracker
latS =    -90
latN =   90
  lonW = -180
  lonE =    180
;lonW = 0
;lonE =    360

dlat =  1.875
dlon =  1.875
T63_nlat = toint((latN-latS)/dlat) + 1
T63_mlon = toint((lonE-lonW)/dlon)
T63_lat  = fspan(latS, latN, T63_nlat)
T63_lon  = fspan(lonW, lonE-dlon, T63_mlon)
T63_lat@units = "degrees_north"
T63_lon@units = "degrees_east"

dlat = 2.5
dlon = 2.5
T42_nlat = toint((latN-latS)/dlat) + 1
T42_mlon = toint((lonE-lonW)/dlon)
T42_lat  = fspan(latS, latN, T42_nlat)
T42_lon  = fspan(lonW, lonE-dlon, T42_mlon)
T42_lat@units = "degrees_north"
T42_lon@units = "degrees_east"

VR850_T42_nat  = area_hi2lores_Wrap (VR850&lon,VR850&lat,VR850,True,1,T42_lon,T42_lat,False)    
VR850_T63_nat  = area_hi2lores_Wrap (VR850&lon,VR850&lat,VR850,True,1,T63_lon,T63_lat,False)
VR500_T63_nat  = area_hi2lores_Wrap (VR500&lon,VR500&lat,VR500,True,1,T63_lon,T63_lat,False)
VR200_T63_nat  = area_hi2lores_Wrap (VR200&lon,VR200&lat,VR200,True,1,T63_lon,T63_lat,False)

VR850_T42 = linint2_Wrap(T42_lon,T42_lat,VR850_T42_nat,True,lon,lat,0)
VR850_T63 = linint2_Wrap(T63_lon,T63_lat,VR850_T63_nat,True,lon,lat,0)
VR500_T63 = linint2_Wrap(T63_lon,T63_lat,VR500_T63_nat,True,lon,lat,0)
VR200_T63 = linint2_Wrap(T63_lon,T63_lat,VR200_T63_nat,True,lon,lat,0)

copy_VarMeta(U850_,VR850_T42)
copy_VarMeta(U850_,VR850_T63)
copy_VarMeta(U850_,VR500_T63)
copy_VarMeta(U850_,VR200_T63)

print("Calculating DZs")
DZ200500_=Z200_
DZ200500_=Z200_-Z500_

DZ300500_=Z300_
DZ300500_=Z300_-Z500_

DZ400500_=Z400_
DZ400500_=Z400_-Z500_

DZ200400_=Z200_
DZ200400_=Z200_-Z400_

DZ300400_=Z300_
DZ300400_=Z300_-Z400_

DZ200850_=Z200_
DZ200850_=Z200_-Z850_

delete_VarAtts(U850_, -1)
U850_@long_name="850 hPa zonal wind"
U850_@units="m/s"
delete_VarAtts(U700_, -1)
U700_@long_name="700 hPa zonal wind"
U700_@units="m/s"
delete_VarAtts(U500_, -1)
U500_@long_name="500 hPa zonal wind"
U500_@units="m/s"
delete_VarAtts(U200_, -1)
U200_@long_name="200 hPa zonal wind"
U200_@units="m/s"
delete_VarAtts(UBOT_, -1)
UBOT_@long_name="Lowest model level zonal wind"
UBOT_@units="m/s"

delete_VarAtts(V850_, -1)
V850_@long_name="850 hPa meridional wind"
V850_@units="m/s"
delete_VarAtts(V700_, -1)
V700_@long_name="700 hPa meridional wind"
V700_@units="m/s"
delete_VarAtts(V500_, -1)
V500_@long_name="500 hPa meridional wind"
V500_@units="m/s"
delete_VarAtts(V200_, -1)
V200_@long_name="200 hPa meridional wind"
V200_@units="m/s"
delete_VarAtts(VBOT_, -1)
VBOT_@long_name="Lowest model level meridional wind"
VBOT_@units="m/s"

delete_VarAtts(T850_, -1)
T850_@long_name="850 hPa temperature"
T850_@units="K"
delete_VarAtts(T700_, -1)
T700_@long_name="700 hPa temperature"
T700_@units="K"
delete_VarAtts(T500_, -1)
T500_@long_name="500 hPa temperature"
T500_@units="K"
delete_VarAtts(T400_, -1)
T400_@long_name="400 hPa temperature"
T400_@units="K"
delete_VarAtts(T300_, -1)
T300_@long_name="300 hPa temperature"
T300_@units="K"
delete_VarAtts(T200_, -1)
T200_@long_name="200 hPa temperature"
T200_@units="K"

delete_VarAtts(PSL_, -1)
PSL_@long_name="Mean sea level pressure"
PSL_@units="Pa"
delete_VarAtts(PS_, -1)
PS_@long_name="Surface pressure"
PS_@units="Pa"

delete_VarAtts(Z850_, -1)
Z850_@long_name="850 hPa geopotential height"
Z850_@units="m"
delete_VarAtts(Z500_, -1)
Z500_@long_name="500 hPa geopotential height"
Z500_@units="m"
delete_VarAtts(Z400_, -1)
Z400_@long_name="400 hPa geopotential height"
Z400_@units="m"
delete_VarAtts(Z300_, -1)
Z300_@long_name="300 hPa geopotential height"
Z300_@units="m"
delete_VarAtts(Z200_, -1)
Z200_@long_name="200 hPa geopotential height"
Z200_@units="m"

delete_VarAtts(DZ200500_, -1)
DZ200500_@long_name="200-500 hPa geopotential thickness"
DZ200500_@units="m"
delete_VarAtts(DZ300500_, -1)
DZ300500_@long_name="300-500 hPa geopotential thickness"
DZ300500_@units="m"
delete_VarAtts(DZ400500_, -1)
DZ400500_@long_name="400-500 hPa geopotential thickness"
DZ400500_@units="m"
delete_VarAtts(DZ200400_, -1)
DZ200400_@long_name="200-400 hPa geopotential thickness"
DZ200400_@units="m"
delete_VarAtts(DZ300400_, -1)
DZ300400_@long_name="300-400 hPa geopotential thickness"
DZ300400_@units="m"
delete_VarAtts(DZ200850_, -1)
DZ200850_@long_name="200-850 hPa geopotential thickness"
DZ200850_@units="m"

delete_VarAtts(VR850, -1)
VR850@long_name="850 hPa relative vorticity"
VR850@units="1/s"
delete_VarAtts(VR500, -1)
VR500@long_name="500 hPa relative vorticity"
VR500@units="1/s"
delete_VarAtts(VR200, -1)
VR200@long_name="200 hPa relative vorticity"
VR200@units="1/s"

delete_VarAtts(VR850_T63, -1)
VR850_T63@long_name="850 hPa relative vorticity (T63 grid)"
VR850_T63@units="1/s"
delete_VarAtts(VR500_T63, -1)
VR500_T63@long_name="500 hPa relative vorticity (T63 grid)"
VR500_T63@units="1/s"
delete_VarAtts(VR200_T63, -1)
VR200_T63@long_name="200 hPa relative vorticity (T63 grid)"
VR200_T63@units="1/s"
delete_VarAtts(VR850_T42, -1)
VR850_T42@long_name="850 hPa relative vorticity (T42 grid)"
VR850_T42@units="1/s"

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
	ncdf->U700 = U700_         
	ncdf->V700 = V700_
	ncdf->U500 = U500_         
	ncdf->V500 = V500_
	ncdf->U200 = U200_         
	ncdf->V200 = V200_
	ncdf->UBOT = UBOT_         
	ncdf->VBOT = VBOT_
	ncdf->T200 = T200_ 
	ncdf->T300 = T300_  
	ncdf->T400 = T400_  
	ncdf->T500 = T500_     
	ncdf->T700 = T700_     
	ncdf->T850 = T850_   
	ncdf->PSL  = PSL_
	ncdf->PS  = PS_
	ncdf->Z200 = Z200_ 
	ncdf->Z300 = Z300_ 
	ncdf->Z400 = Z400_ 
	ncdf->Z500 = Z500_
	ncdf->Z850 = Z850_  
;	ncdf->Z1000= Z1000_
;	ncdf->ZBOT= ZBOT_
  ncdf->DZ200500 = DZ200500_
  ncdf->DZ300500 = DZ300500_
  ncdf->DZ400500 = DZ400500_
  ncdf->DZ200400 = DZ200400_
  ncdf->DZ300400 = DZ300400_
  ncdf->DZ200850 = DZ200850_
;	ncdf->VR850SM = VR850SM
	ncdf->VR850=VR850
;	ncdf->VR500SM = VR500SM
	ncdf->VR500=VR500
;	ncdf->VR200SM = VR200SM
	ncdf->VR200=VR200

	ncdf->VR850_T63 = VR850_T63
	ncdf->VR500_T63 = VR500_T63
	ncdf->VR200_T63 = VR200_T63
	ncdf->VR850_T42 = VR850_T42

end if

end
