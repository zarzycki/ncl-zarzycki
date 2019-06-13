;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;YEAR=2010
grav=9.80665

; START WITH PSL
f_PSL = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".mean_sea_level_pressure.grib","r")

PSL = f_PSL->MSL_GDS0_SFC(:,::-1,:)
time = f_PSL->initial_time0_hours
time@calendar="gregorian"
lat = f_PSL->g0_lat_1(::-1)
lon = f_PSL->g0_lon_2

lat = fspan(-90.,90.,dimsizes(lat))
lon = fspan(0.,359.75,dimsizes(lon))

ndays = toint(dimsizes(time)/4)

lat!0="lat"
lat&lat=lat
lon!0="lon"
lon&lon=lon

PSL!0="time"
PSL!1="lat"
PSL!2="lon"
PSL&time=time
PSL&lat=lat
PSL&lon=lon

; OTHER FILES

f_Z300 = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".geopotential.300.grib","r")
Z300 = f_Z300->Z_GDS0_ISBL(:,::-1,:)
Z300 = Z300/grav
copy_VarCoords(PSL,Z300)

f_Z500 = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".geopotential.500.grib","r")
Z500 = f_Z500->Z_GDS0_ISBL(:,::-1,:)
Z500 = Z500/grav
copy_VarCoords(PSL,Z500)

f_T400 = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".temperature.400.grib","r")
T400 = f_T400->T_GDS0_ISBL(:,::-1,:)
copy_VarCoords(PSL,T400)

f_U850 = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".u_component_of_wind.850.grib","r")
U850 = f_U850->U_GDS0_ISBL(:,::-1,:)
copy_VarCoords(PSL,U850)

f_V850 = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".v_component_of_wind.850.grib","r")
V850 = f_V850->V_GDS0_ISBL(:,::-1,:)
copy_VarCoords(PSL,V850)

f_UBOT = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".10m_u_component_of_wind.grib","r")
UBOT = f_UBOT->10U_GDS0_SFC(:,::-1,:)
copy_VarCoords(PSL,UBOT)

f_VBOT = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".10m_v_component_of_wind.grib","r")
VBOT = f_VBOT->10V_GDS0_SFC(:,::-1,:)
copy_VarCoords(PSL,VBOT)

f_PS = addfile("/glade/u/home/zarzycki/scratch/ERA5/out."+YEAR+".surface_pressure.grib","r")
PS = f_PS->SP_GDS0_SFC(:,::-1,:)
copy_VarCoords(PSL,PS)

write_output=True
if (write_output) then
  outDir = "/glade/scratch/zarzycki/h1files/ERA5/"+YEAR+"/"
  system("mkdir -p "+outDir)   ; make dir if it doesn't exist

  do ii = 0,ndays-1
    STIX = ii*4
    ENIX = STIX+3
    yyyymmddhh=tostring(cd_calendar(time(STIX),-2))
    print(yyyymmddhh+" "+STIX+" "+ENIX)
    
    outFileName = "ERA5.h1."+yyyymmddhh+".nc"
    system("/bin/rm -f "+outDir+"/"+outFileName)   ; remove any pre-existing file
    ncdf     = addfile(outDir+"/"+outFileName ,"c")  ; open output netCDF file
    print("Writing output file:  "+outDir+"/"+outFileName)

    ; make time and UNLIMITED dimension      ; recommended  for most applications
    filedimdef(ncdf,"time",-1,True)

    ncdf->lat = lat
    ncdf->lon = lon

    ncdf->PSL  = PSL(STIX:ENIX,:,:)
    ncdf->PS  = PS(STIX:ENIX,:,:)
    ncdf->Z300 = Z300(STIX:ENIX,:,:)
    ncdf->Z500 = Z500(STIX:ENIX,:,:)
    ncdf->T400 = T400(STIX:ENIX,:,:)
    ncdf->U850 = U850(STIX:ENIX,:,:)
    ncdf->V850 = V850(STIX:ENIX,:,:)
    ncdf->UBOT = UBOT(STIX:ENIX,:,:)
    ncdf->VBOT = VBOT(STIX:ENIX,:,:)
  end do
  
end if

exit()

end
