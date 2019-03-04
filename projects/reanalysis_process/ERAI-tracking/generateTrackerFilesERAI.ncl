;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;dateListArr=(/"1992082700"/)

print("  "+dateListArr)
 
;SYMDIR="/glade/scratch/zarzycki/erai-ETC/"
;OUTDIR="/glade/scratch/zarzycki/erai-ETC/"

print("Getting raw JRA files...")
wcStrt     = systemfunc("date")

MLFILES = systemfunc ("ls "+SYMDIR+"/ei.oper.an.ml.*"+dateListArr+".grb2")
MLFILE  = addfiles (MLFILES, "r")   ; note the "s" of addfile
ListSetType (MLFILE, "cat")             ; concatenate or "merge" (default)
print("...done with model levels")

PLFILES = systemfunc ("ls "+SYMDIR+"/ei.oper.an.pl.*"+dateListArr+".grb2")
PLFILE  = addfiles (PLFILES, "r")   ; note the "s" of addfile
ListSetType (PLFILE, "cat")             ; concatenate or "merge" (default)
print("...done with pressure levels")

SFCFILES = systemfunc ("ls "+SYMDIR+"/ei.oper.an.sfc.*"+dateListArr+".grb2")
SFCFILE  = addfiles (SFCFILES, "r")   ; note the "s" of addfile
ListSetType (SFCFILE, "cat")             ; concatenate or "merge" (default)
print("...done with surface levels")

wallClockElapseTime(wcStrt, "Getting files", 0)

print("Getting coordinates and date arrays...")

sizeDims=dimsizes(PLFILE[:]->Z_GDS4_ISBL({300:1000},:,:))
nplev=sizeDims(0)
nmlev=60
nlat=sizeDims(1)
nlon=sizeDims(2)
lat=PLFILE[0]->g4_lat_1(::-1)
lon=PLFILE[0]->g4_lon_2
lev=PLFILE[0]->lv_ISBL0({300:1000})
lev_=tofloat(lev)
delete(lev)
lev=lev_
lev@units = "Pa"
lev@long_name = "Isobaric surface"

;year_time=PLFILE[:]->initial_time0_hours
;JRAunits=year_time@units
;delete(year_time)

thisDate=dateListArr
print("*********************************************************************")
print("Working on date: "+thisDate)
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(thisDate, dtime_map)
yyyy=tst_dtime(0)
mm=tst_dtime(1)
dd=tst_dtime(2)
hh=tst_dtime(3)

yyyymmddstr=yyyy+mm+dd

PSL=SFCFILE[:]->MSL_GDS4_SFC(::-1,:)
Z  =PLFILE[:]->Z_GDS4_ISBL({300:1000},::-1,:)
Z300=Z({300},:,:)
Z500=Z({500},:,:)
VORT850=PLFILE[:]->VO_GDS4_ISBL({850},::-1,:)
DIV850=PLFILE[:]->D_GDS4_ISBL({850},::-1,:)
VORTBOT=MLFILE[:]->VO_GDS4_HYBL(nmlev-1,::-1,:)
DIVBOT=MLFILE[:]->D_GDS4_HYBL(nmlev-1,::-1,:)

Z = Z/9.81
Z300 = Z300/9.81
Z500 = Z500/9.81
Z@units="m"
Z300@units="m"
Z500@units="m"

uvbot = vr2uvF_Wrap(VORTBOT)
uv850 = vr2uvF_Wrap(VORT850)

UBOT=uvbot(0,:,:)
VBOT=uvbot(1,:,:)
U850=uv850(0,:,:)
V850=uv850(1,:,:)



; Poisson grid filling since JRA on pressure levels are not filled in
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 1500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.6              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill(Z300, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z500, is_cyclic, guess, nscan, eps, relc, opt)


newunits = "days since 1979-10-01 00:00:00"
option=0
option@calendar="standard"
thisTime = cd_inv_calendar(toint(yyyy),toint(mm),toint(dd),toint(hh),0,0,newunits, option)

arrType="float"
UBOT_ = new((/1,nlat,nlon/),arrType)
UBOT_(0,:,:) = UBOT
VBOT_ = new((/1,nlat,nlon/),arrType)
VBOT_(0,:,:) = VBOT
U850_ = new((/1,nlat,nlon/),arrType)
U850_(0,:,:) = U850
V850_ = new((/1,nlat,nlon/),arrType)
V850_(0,:,:) = V850
PSL_ = new((/1,nlat,nlon/),arrType)
PSL_(0,:,:) = PSL
Z300_ = new((/1,nlat,nlon/),arrType)
Z300_(0,:,:) = Z300
Z500_ = new((/1,nlat,nlon/),arrType)
Z500_(0,:,:) = Z500

U850_!0    = "time"
U850_!1    = "lat"
U850_!2    = "lon"
U850_&time = thisTime
U850_&lat  = lat
U850_&lon  = lon

copy_VarCoords(U850_,V850_)
copy_VarCoords(U850_,UBOT_)
copy_VarCoords(U850_,VBOT_)
copy_VarCoords(U850_,Z300_)
copy_VarCoords(U850_,Z500_)
copy_VarCoords(U850_,PSL_)

printVarSummary(Z)
;Z&lv_ISBL0 = tofloat(Z&lv_ISBL0)
printVarSummary(Z)

Z_ = new((/1,nplev,nlat,nlon/),arrType)
Z_(0,:,:,:) = Z

Z_!0    = "time"
Z_!1    = "lev"
Z_!2    = "lat"
Z_!3    = "lon"

printVarSummary(Z_)
delete(Z_&lev)

Z_&time = thisTime
Z_&lev  = lev
Z_&lat  = lat
Z_&lon  = lon

yyyymmdd=toint(yyyymmddstr)
yyyymmdd!0="time"
yyyymmdd&time=thisTime
yyyymmdd@long_name = "current date (YYYYMMDD)"

print("Writing file...")
fileName=OUTDIR+"/ERAI.h1."+thisDate+".nc"
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

ncdf->UBOT = UBOT_
ncdf->VBOT = VBOT_
ncdf->U850 = U850_ 
ncdf->V850 = V850_    
ncdf->Z300 = Z300_
ncdf->Z500 = Z500_
ncdf->PSL = PSL_
ncdf->Z = Z_
ncdf->date = yyyymmdd

print("... done writing file")

exit


end

