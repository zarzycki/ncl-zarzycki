begin

;YEAR=2005
timeArrFile="test_timesArray_"+YEAR+".txt"
OUTDIR="/glade/scratch/zarzycki/h1files/CR20/"+YEAR+"/"

; Get times =====================================================

dateListArr = asciiread(timeArrFile,-1,"string")
print(dateListArr)

;================================================================

print("Getting raw 20CRV3 files...")
wcStrt     = systemfunc("date")

ZFILE = addfile("~/scratch/h1files/20CR/hgt."+YEAR+".nc", "r")
print("...done with Z")

TFILE = addfile("~/scratch/h1files/20CR/air."+YEAR+".nc", "r")
print("...done with T")

UFILE = addfile("~/scratch/h1files/20CR/uwnd."+YEAR+".nc", "r")
print("...done with U")

VFILE = addfile("~/scratch/h1files/20CR/vwnd."+YEAR+".nc", "r")
print("...done with V")

U10FILE = addfile("~/scratch/h1files/20CR/uwnd.10m."+YEAR+".nc", "r")
print("...done with U10")

V10FILE = addfile("~/scratch/h1files/20CR/vwnd.10m."+YEAR+".nc", "r")
print("...done with V10")

PSFILE = addfile("~/scratch/h1files/20CR/prmsl."+YEAR+".nc", "r")
print("...done with PS")

wallClockElapseTime(wcStrt, "Getting files", 0)

print("Getting coordinates and date arrays...")

sizeDims=dimsizes(ZFILE->hgt(0,:,:,:))
nlev=sizeDims(0)
nlat=sizeDims(1)
nlon=sizeDims(2)
lat=ZFILE->lat
lon=ZFILE->lon

year_time=ZFILE->time
CRunits=year_time@units

FULLPSL = PSFILE->prmsl(:,:,:)
FULLV850 = VFILE->vwnd(:,{850},:,:)
FULLU850 = UFILE->uwnd(:,{850},:,:)
FULLVBOT = V10FILE->vwnd(:,:,:)
FULLUBOT = U10FILE->uwnd(:,:,:)
FULLZ300 = ZFILE->hgt(:,{300},:,:)
FULLZ500 = ZFILE->hgt(:,{500},:,:)
FULLT400 = TFILE->air(:,{400},:,:)

print("Entering loop...")
do z = 0,dimsizes(dateListArr)-1

thisDate=dateListArr(z)
print("*********************************************************************")
print("Working on date: "+thisDate)
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(thisDate, dtime_map)
yyyy=tst_dtime(0)
mm=tst_dtime(1)
dd=tst_dtime(2)
hh=tst_dtime(3)

time   = cd_inv_calendar(tointeger(yyyy),tointeger(mm),tointeger(dd),tointeger(hh),0,0,CRunits,0)

PSL  = FULLPSL({time},:,:)
V850 = FULLV850({time},:,:)
U850 = FULLU850({time},:,:)
VBOT = FULLVBOT({time},:,:)
UBOT = FULLUBOT({time},:,:)
Z300 = FULLZ300({time},:,:)
Z500 = FULLZ500({time},:,:)
T400 = FULLT400({time},:,:)

; Poisson grid filling since JRA on pressure levels are not filled in
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 1500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.6              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill(U850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(V850, is_cyclic, guess, nscan, eps, relc, opt)

poisson_grid_fill(Z500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z300, is_cyclic, guess, nscan, eps, relc, opt)

arrType="float"
UBOT_ = new((/1,nlat,nlon/),arrType)
UBOT_(0,:,:) = UBOT
VBOT_ = new((/1,nlat,nlon/),arrType)
VBOT_(0,:,:) = VBOT

U850_ = new((/1,nlat,nlon/),arrType)
U850_(0,:,:) = U850


V850_ = new((/1,nlat,nlon/),arrType)
V850_(0,:,:) = V850



Z500_ = new((/1,nlat,nlon/),arrType)
Z500_(0,:,:) = Z500
Z300_ = new((/1,nlat,nlon/),arrType)
Z300_(0,:,:) = Z300

T400_ = new((/1,nlat,nlon/),arrType)
T400_(0,:,:) = T400

PSL_ = new((/1,nlat,nlon/),arrType)
PSL_(0,:,:) = PSL



newunits = "days since "+yyyy+"-"+mm+"-"+dd+" 00:00:00"
thisTime = cd_inv_calendar(toint(yyyy),toint(mm),toint(dd),toint(hh),0,0,newunits, 0) 

U850_!0    = "time"
U850_!1    = "lat"
U850_!2    = "lon"
U850_&time = thisTime
U850_&lat  = lat
U850_&lon  = lon 





copy_VarMeta(U850_,V850_)
copy_VarMeta(U850_,UBOT_)
copy_VarMeta(U850_,VBOT_)

copy_VarMeta(U850_,PSL_)


copy_VarMeta(U850_,Z300_)
copy_VarMeta(U850_,Z500_)

copy_VarMeta(U850_,T400_)


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

delete_VarAtts(PSL_, -1)
PSL_@long_name="Mean sea level pressure"
PSL_@units="Pa"

delete_VarAtts(Z500_, -1)
Z500_@long_name="500 hPa geopotential height"
Z500_@units="m"
delete_VarAtts(Z300_, -1)
Z300_@long_name="300 hPa geopotential height"
Z300_@units="m"
delete_VarAtts(T400, -1)
T400_@long_name="400 hPa temperature"
T400_@units="K"


print("Writing file...")
fileName=OUTDIR+"/CR20.h1."+thisDate+".nc"
system("/bin/rm -f "+fileName)   ; remove any pre-existing file
ncdf = addfile(fileName ,"c")  ; open output netCDF file
print("Writing output file:  "+fileName)

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(ncdf,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================

ncdf->U850 = U850_         
ncdf->V850 = V850_
ncdf->UBOT = UBOT_         
ncdf->VBOT = VBOT_

ncdf->PSL  = PSL_

ncdf->Z300 = Z300_ 
ncdf->Z500 = Z500_ 

ncdf->T400 = T400_ 


print("... done writing file")

;list_vars()

end do

end

