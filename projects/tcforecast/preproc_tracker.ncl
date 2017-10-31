;======================================================================
; ESMF_regrid_18.ncl
;======================================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

wcStrt     = systemfunc("date")

production = True
grid="tcforecast_60_x4"
flag="mod900tau"

;date="2012090800"
outputdir = "/glade/scratch/zarzycki/sewx_processed/"
outputfilename = grid+".cam."+date+"."+flag+".nc"
;outputfilename = grid+".cam."+date+".nc"

dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(date, dtime_map)

yearstr = tst_dtime(0)
monthstr = tst_dtime(1)
daystr = tst_dtime(2)
cyclestr = tst_dtime(3)
;pathtoruns = "/glade/u/home/zarzycki/scratch/MOVING/MOVINGFROMRUN/"
;pathtoruns = "/glade/u/home/zarzycki/scratch/TCFORECAST_2013/"

print(pathtoruns)

print("dtime_year  : " + yearstr)
print("dtime_month : " + monthstr)
print("dtime_day   : " + daystr)
print("dtime_hour  : " + cyclestr)

;========================
; get list of all files and open as "one big file"
;========================                             
all_files = systemfunc("ls "+ pathtoruns+"/"+yearstr+monthstr+daystr+cyclestr+"/"+grid+".cam.h0.*21600*.nc " \
                          +pathtoruns+"/"+yearstr+monthstr+daystr+cyclestr+"/"+grid+".cam.h0.*43200*.nc " \
                          +pathtoruns+"/"+yearstr+monthstr+daystr+cyclestr+"/"+grid+".cam.h0.*64800*.nc " \
                          +pathtoruns+"/"+yearstr+monthstr+daystr+cyclestr+"/"+grid+".cam.h0.*00000*.nc " \
                          )
     
print(all_files)
fall      = addfiles (all_files, "r")   ; note the "s" of addfile
  ;========================
  ; choose how files are combined and read in variable across files
  ;========================  
ListSetType (fall, "cat")             ; concatenate or "merge" (default)
;T    = fall[:]->T                     ; note syntax [:]


if (production)

;filein = addfile("/glade/scratch/zarzycki/fullh0.nc","r")
;system("rm /glade/scratch/zarzycki/trackerout.nc")
;system("cp /glade/scratch/zarzycki/tracker.nc /glade/scratch/zarzycki/trackerout.nc")
;fileout = addfile("/glade/scratch/zarzycki/trackerout.nc","r")

print("Getting data")
wcGetData = systemfunc("date")

u850 = fall[:]->U850
v850 = fall[:]->V850
u700 = fall[:]->U700
v700 = fall[:]->V700
u500 = fall[:]->U500
v500 = fall[:]->V500
z850 = fall[:]->Z850
z700 = fall[:]->Z700
mslp = fall[:]->PSL/100.
t300 = fall[:]->T300
t200 = fall[:]->T200

t300200 = t300
t300200 = (t300 + t200)/2.

zbot = fall[:]->ZBOT
ubot = fall[:]->UBOT
vbot = fall[:]->VBOT

u10 = ubot

wallClockElapseTime(wcGetData, "Getting data", 0)


ms_to_kts = 1.94384449
wind_factor = "log"
; Wind speed power relation
if (wind_factor .eq. "power") then
  z_10 = 10.
  z_r = 64.
  alpha = 0.11
  factor = (z_10/z_r)^alpha
  print("Using factor: "+factor)
else if (wind_factor .eq. "log") then
  ; Garret 1992 -- Wind profile formulation
  ; Wieringa 1993 -- roughness coefficient
  z_10 = 10.
  z_0 = 0.0002 ; roughness coeff
  u10 = u850 * (1 + log(z_10/zbot)/log(zbot/z_0))
  v10 = v850 * (1 + log(z_10/zbot)/log(zbot/z_0))
  ;print("Using factor: "+factor)
else if (wind_factor .eq. "none") then
  print("No correction used.")
else
  print("Incorrect wind correction type.")
  exit
end if
end if
end if

print("Doing vort calculations")
wcDoVort = systemfunc("date")
;printVarSummary(u850)

vr850 = u850
vr850 = uv2vrF(u850,v850)
vr700 = u700
vr700 = uv2vrF(u700,v700)

wallClockElapseTime(wcDoVort, "Vorticity done", 0)

print("Copying var coordinates")
copy_VarCoords(z850,mslp)
copy_VarCoords(z850,u10)
copy_VarCoords(z850,v10)

print("Writing file")
wcWriteData = systemfunc("date")

system("rm -f "+outputdir+outputfilename)   ; remove any pre-existing file
ncdf = addfile(outputdir+outputfilename ,"c")  ; open output netCDF file

    ; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

    ; output variables directly
ncdf->vort850  = vr850
ncdf->vort700 = vr700
ncdf->u850 = u850
ncdf->v850 = v850
ncdf->u700 = u700
ncdf->v700 = v700
ncdf->h850 = z850
ncdf->h700 = z700
ncdf->slp = mslp
ncdf->u_ref = u10
ncdf->v_ref = v10
ncdf->u500 = u500
ncdf->v500 = v500
ncdf->tm = t300

wallClockElapseTime(wcWriteData, "Writing output file", 0)

;data chparm   /'vort850','vort700'
;     &              ,'u850','v850','u700','v700'
;     &              ,'h850','h700','slp','u_ref','v_ref'
;     &              ,'u500','v500','tm'/

; 4D               
;ncdf->PS = PS                         ; 3D 

 ;      ORO!0    = "lat"                      ; assign named dimensions
 ;      ORO!1    = "lon"
 ;      
 ;      ORO&lat  = T&lat                      ; copy lat from T to ORO
  ;     ORO&lon  = T&lon 

 ;      ORO@long_name = "orography"           ; assign attributes 
 ;      ORO@units     = "m"
;
;       ncdf->TOPOGRAPHY = ORO

end if

wallClockElapseTime(wcStrt, "Total runtime", 0)

end

