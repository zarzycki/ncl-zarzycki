;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of NARR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;YYYYMMDD="2005082912"
write_output = True

; Get YYYYMMDDHH from the initdate string
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(YYYYMMDD, dtime_map)
yyyy=tst_dtime(0)
mm=tst_dtime(1)
dd=tst_dtime(2)
hh=tst_dtime(3)

if (hh .ne. "00" .and. hh .ne. "06" .and. hh .ne. "12" .and. hh .ne. "18") then
  print("non standard time")
  exit
end if

print("Processing: "+yyyy+" "+mm+" "+dd+" "+hh)

presLevDir = "/glade/u/home/zarzycki/scratch/NARR/"+yyyy+"/"
surfaceDir = "/glade/u/home/zarzycki/scratch/NARR/"+yyyy+"/"
sfcfluxDir = "/glade/u/home/zarzycki/scratch/NARR/"+yyyy+"/"

presLevFlName = "merged_AWIP32."+yyyy+mm+dd+hh+".3D.grb2"
surfaceFlName = "merged_AWIP32."+yyyy+mm+dd+hh+".RS.sfc.grb2"
sfcfluxFlName = "merged_AWIP32."+yyyy+mm+dd+hh+".RS.flx.grb2"

print("PRES LEVS:    "+presLevDir+"/"+presLevFlName)
print("SFC LEVS:    "+surfaceDir+"/"+surfaceFlName)

presLevFile = addfile(presLevDir+"/"+presLevFlName,"r")
surfaceFile = addfile(surfaceDir+"/"+surfaceFlName,"r")
sfcfluxFile = addfile(sfcfluxDir+"/"+sfcfluxFlName,"r")

newunits = "days since "+yyyy+"-"+mm+"-"+dd+" 00:00:00"
time = cd_inv_calendar(toint(yyyy),toint(mm),toint(dd),toint(hh),0,0,newunits, 0) 

lat2d  = presLevFile->gridlat_221
lon2d  = presLevFile->gridlon_221
n2ddims = dimsizes(lat2d)
n2dlat=n2ddims(0)
n2dlon=n2ddims(1)

lon2d  = where(lon2d.lt.0,lon2d+360.0,lon2d)
preslevs = presLevFile->lv_ISBL0

V_850 = presLevFile->V_GRD_221_ISBL({850.},:,:)
U_850 = presLevFile->U_GRD_221_ISBL({850.},:,:)
Z_300 = presLevFile->HGT_221_ISBL({300.},:,:)
Z_500 = presLevFile->HGT_221_ISBL({500.},:,:)
T_400 = presLevFile->TMP_221_ISBL({400.},:,:)

U_10 = sfcfluxFile->U_GRD_221_HTGL({10.},:,:)
V_10 = sfcfluxFile->V_GRD_221_HTGL({10.},:,:)
P_SL   = sfcfluxFile->PRMSL_221_MSL(:,:)
P_S   = surfaceFile->PRES_221_SFC(:,:)


; Add time dimension to raw NARR data
U850_ = new((/1,n2dlat,n2dlon/),"float")
U850_(0,:,:) = tofloat(U_850)
V850_ = new((/1,n2dlat,n2dlon/),"float")
V850_(0,:,:) = tofloat(V_850)
UBOT_ = new((/1,n2dlat,n2dlon/),"float")
UBOT_(0,:,:) = tofloat(U_10)
VBOT_ = new((/1,n2dlat,n2dlon/),"float")
VBOT_(0,:,:) = tofloat(V_10)
Z300_ = new((/1,n2dlat,n2dlon/),"float")
Z300_(0,:,:) = tofloat(Z_300)
Z500_ = new((/1,n2dlat,n2dlon/),"float")
Z500_(0,:,:) = tofloat(Z_500)
T400_ = new((/1,n2dlat,n2dlon/),"float")
T400_(0,:,:) = tofloat(T_400)
PSL_ = new((/1,n2dlat,n2dlon/),"float")
PSL_(0,:,:) = tofloat(P_SL)
PS_ = new((/1,n2dlat,n2dlon/),"float")
PS_(0,:,:) = tofloat(P_S)

; add metadata to one, copy rest
U850_!0    = "time"
U850_!1    = "gridx_221"
U850_!2    = "gridy_221"
U850_&time = time
copy_VarMeta(U850_,V850_)
copy_VarMeta(U850_,UBOT_)
copy_VarMeta(U850_,VBOT_)
copy_VarMeta(U850_,T400_)
copy_VarMeta(U850_,PSL_)
copy_VarMeta(U850_,PS_)
copy_VarMeta(U850_,Z300_)
copy_VarMeta(U850_,Z500_)

; add attributes
U850_@_FillValue=U_850@_FillValue
copy_VarAtts(U850_,V850_)
copy_VarAtts(U850_,UBOT_)
copy_VarAtts(U850_,VBOT_)
copy_VarAtts(U850_,T400_)
copy_VarAtts(U850_,PSL_)
copy_VarAtts(U850_,PS_)
copy_VarAtts(U850_,Z300_)
copy_VarAtts(U850_,Z500_)

U850_@long_name="850 hPa zonal wind"
U850_@units="m/s"
UBOT_@long_name="10m zonal wind"
UBOT_@units="m/s"
V850_@long_name="850 hPa meridional wind"
V850_@units="m/s"
VBOT_@long_name="10m meridional wind"
VBOT_@units="m/s"
T400_@long_name="400 hPa temperature"
T400_@units="K"
PSL_@long_name="Mean sea level pressure"
PSL_@units="Pa"
PS_@long_name="Surface pressure"
PS_@units="Pa"
Z500_@long_name="500 hPa geopotential height"
Z500_@units="m"
Z300_@long_name="300 hPa geopotential height"
Z300_@units="m"

; interpolate from curvilinear to rectilinear
minlat = 12.
maxlat = 65.
minlon = 215.
maxlon = 298.

lat = fspan(minlat,maxlat,toint((maxlat-minlat)*5+1))
lon = fspan(minlon,maxlon,toint((maxlon-minlon)*5+1))
lat@units="degrees_north"
lon@units="degrees_east"
lat!0="lat"
lon!0="lon"
lat&lat=lat
lon&lon=lon

Opt         = True
wgt_file="/glade/u/home/zarzycki/ncl/projects/reanalysis_process/NARR/map_NARR_to_0.25x0.25reg_patch.nc"
;wgt_file="/glade/u/home/zarzycki/scratch/map_nativeNARR_to_0.25x0.25reg_patch.nc"
v850  = ESMF_regrid_with_weights(V850_,wgt_file,Opt)
u850  = ESMF_regrid_with_weights(U850_,wgt_file,Opt)
z300  = ESMF_regrid_with_weights(Z300_,wgt_file,Opt)
z500  = ESMF_regrid_with_weights(Z500_,wgt_file,Opt)
t400  = ESMF_regrid_with_weights(T400_,wgt_file,Opt)
ubot  = ESMF_regrid_with_weights(UBOT_,wgt_file,Opt)
vbot  = ESMF_regrid_with_weights(VBOT_,wgt_file,Opt)
psl  = ESMF_regrid_with_weights(PSL_,wgt_file,Opt)
ps  = ESMF_regrid_with_weights(PS_,wgt_file,Opt)

  if(any(ismissing(v850))) then
    print("Your data contains some missing values. Beware.")
  end if

if (write_output) then
	outFileName = "NARR.h1."+yyyy+mm+dd+hh+".nc"
	system("/bin/rm -f "+outDir+"/"+outFileName)   ; remove any pre-existing file
	ncdf     = addfile(outDir+"/"+outFileName ,"c")  ; open output netCDF file
	print("Writing output file:  "+outDir+"/"+outFileName)

	; make time and UNLIMITED dimension      ; recommended  for most applications
	filedimdef(ncdf,"time",-1,True) 

	;ncdf->lat = lat
	;ncdf->lon = lon


       ncdf->V850  = v850                          ; 4D               
       ncdf->U850  = u850                          ; 4D               
       ncdf->Z300  = z300                          ; 4D               
       ncdf->Z500  = z500                          ; 4D               
       ncdf->T400  = t400                          ; 4D               
       ncdf->UBOT  = ubot                          ; 4D               
       ncdf->VBOT  = vbot                          ; 4D               
       ncdf->PSL   = psl                          ; 4D               
       ncdf->PS   = ps                         ; 4D      

/;
       ncdf->V850  = V850_                          ; 4D               
       ncdf->U850  = U850_                          ; 4D               
       ncdf->Z300  = Z300_                          ; 4D               
       ncdf->Z500  = Z500_                          ; 4D               
       ncdf->T400  = T400_                          ; 4D               
       ncdf->UBOT  = UBOT_                          ; 4D               
       ncdf->VBOT  = VBOT_                          ; 4D               
       ncdf->PSL   = PSL_                          ; 4D               
       ncdf->PS   = PS_                         ; 4D               
;/
end if

exit()


end
