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

JRABASEDIR="/glade/p/rda/data/ds628.0/"
SYMDIR="/glade/u/home/zarzycki/scratch/JRAsym/"
;YEAR=2006
OUTDIR="/glade/scratch/zarzycki/h1files/JRA/"+YEAR+"/"

; Get times =====================================================

dateListArr = asciiread(timeArrFile,-1,"string")

; Get JRA hybrid coeffs =========================================
filename = "JRA_hycoef.csv"
lines = asciiread(filename,-1,"string")
delim = ","

hyai  = tofloat(str_get_field(lines,1,delim))
hybi  = tofloat(str_get_field(lines,2,delim))
hyam = (hyai(1:60)+hyai(0:59))/2  
hybm = (hybi(1:60)+hybi(0:59))/2  

presm=hyam+hybm*100000.
;print(presm)
;================================================================

print("Getting raw JRA files...")
wcStrt     = systemfunc("date")

TFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_mdl.011_tmp.*.grb2")
TFILE      = addfiles (TFILES, "r")   ; note the "s" of addfile
ListSetType (TFILE, "cat")             ; concatenate or "merge" (default)
print("...done with T")

ZFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_mdl.007_hgt.*.grb2")
ZFILE      = addfiles (ZFILES, "r")   ; note the "s" of addfile
ListSetType (ZFILE, "cat")             ; concatenate or "merge" (default)
print("...done with Z")

UFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_mdl.033_ugrd.*.grb2")
UFILE      = addfiles (UFILES, "r")   ; note the "s" of addfile
ListSetType (UFILE, "cat")             ; concatenate or "merge" (default)
print("...done with U")

VFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_mdl.034_vgrd.*.grb2")
VFILE      = addfiles (VFILES, "r")   ; note the "s" of addfile
ListSetType (VFILE, "cat")             ; concatenate or "merge" (default)
print("...done with V")

PSFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_surf.001_pres.*.grb2")
PSFILE      = addfiles (PSFILES, "r")   ; note the "s" of addfile
ListSetType (PSFILE, "cat")             ; concatenate or "merge" (default)
print("...done with PS")

PHISFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/tl319.006_gp.*.grb2")
PHISFILE      = addfiles (PHISFILES, "r")   ; note the "s" of addfile
ListSetType (PHISFILE, "cat")             ; concatenate or "merge" (default)
print("...done with PHIS")

SFCTFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_surf.011_tmp.*.grb2")
SFCTFILE      = addfiles (SFCTFILES, "r")   ; note the "s" of addfile
ListSetType (SFCTFILE, "cat")             ; concatenate or "merge" (default)
print("...done with SFCT (surface temp)")

wallClockElapseTime(wcStrt, "Getting files", 0)

print("Getting coordinates and date arrays...")

sizeDims=dimsizes(TFILE[:]->TMP_GDS4_HYBL(0,:,:,:))
nlev=sizeDims(0)
nlat=sizeDims(1)
nlon=sizeDims(2)
lat=TFILE[0]->g4_lat_2(::-1)
lon=TFILE[0]->g4_lon_3
hyblvl=TFILE[0]->lv_HYBL1

year_time=PSFILE[:]->initial_time0_hours
JRAunits=year_time@units
delete(year_time)

;dateListArr=(/"2005010100","2005010106","2005010112","2005010118","2005010200"/)

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

time   = cd_inv_calendar(tointeger(yyyy),tointeger(mm),tointeger(dd),tointeger(hh),0,0,JRAunits,0)

PS=PSFILE[:]->PRES_GDS4_SFC({time},::-1,:)
T=TFILE[:]->TMP_GDS4_HYBL({time},:,::-1,:)
Z=ZFILE[:]->HGT_GDS4_HYBL({time},:,::-1,:)
PHIS=PHISFILE[:]->GP_GDS4_SFC(::-1,:)
U=UFILE[:]->UGRD_GDS4_HYBL({time},:,::-1,:)
V=VFILE[:]->VGRD_GDS4_HYBL({time},:,::-1,:)
SFCT=SFCTFILE[:]->TMP_GDS4_HTGL({time},::-1,:)

UBOT = U(0,:,:)
VBOT = V(0,:,:)
ZBOT = Z(0,:,:)

U850 = rm_single_dims(vinth2p(U(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),850.0,PS(:,:),2,1000.,1,False))

V850 = rm_single_dims(vinth2p(V(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),850.0,PS(:,:),2,1000.,1,False))

T400 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),400.0,PS(:,:),2,1000.,1,False))

Z500 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),500.0,PS(:,:),2,1000.,1,False))
Z300 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),300.0,PS(:,:),2,1000.,1,False))

; Poisson grid filling since JRA on pressure levels are not filled in
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

arrType="float"
UBOT_ = new((/1,nlat,nlon/),arrType)
UBOT_(0,:,:) = UBOT
VBOT_ = new((/1,nlat,nlon/),arrType)
VBOT_(0,:,:) = VBOT

U850_ = new((/1,nlat,nlon/),arrType)
U850_(0,:,:) = U850

V850_ = new((/1,nlat,nlon/),arrType)
V850_(0,:,:) = V850

T400_ = new((/1,nlat,nlon/),arrType)
T400_(0,:,:) = T400

Z500_ = new((/1,nlat,nlon/),arrType)
Z500_(0,:,:) = Z500
Z300_ = new((/1,nlat,nlon/),arrType)
Z300_(0,:,:) = Z300

PS_ = new((/1,nlat,nlon/),arrType)
PS_(0,:,:) = PS


; ============ SLP correction ===================================================
Rd=287.1
g=9.81
xlapse=0.0065

alpha=SFCT(:,:)
alpha=xlapse*Rd/g
TSTAR=SFCT(:,:)
T0=SFCT(:,:)
T0=TSTAR+(xlapse*PHIS(:,:)/g)

alpha = where(TSTAR.le.290.5 .and. T0.gt.290.5,Rd/PHIS(:,:)*(290.5-TSTAR),alpha)
alpha = where(TSTAR.gt.290.5 .and. T0.gt.290.5,0.0,alpha)
TSTAR = where(TSTAR.gt.290.5 .and. T0.gt.290.5,0.5*(290.5+TSTAR),TSTAR)
TSTAR = where(TSTAR.lt.255.0,0.5*(255.0+TSTAR),TSTAR)
beta=PHIS/Rd/TSTAR

PSL=PS*exp(beta*(1-alpha*beta/2+((alpha*beta)^2/3)))

; ============ SLP correction ===================================================

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

print("Writing file...")
fileName=OUTDIR+"/JRA.h1."+thisDate+".nc"
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

ncdf->T400 = T400_  

ncdf->PSL  = PSL_
ncdf->PS  = PS_
ncdf->Z300 = Z300_ 
ncdf->Z500 = Z500_ 

print("... done writing file")

delete([/U850,V850,UBOT,VBOT,T400,PSL,PS,Z300,Z500/])
delete([/U850_,V850_,UBOT_,VBOT_,T400_,PSL_,PS_,Z300_,Z500_/])
delete([/PHIS,T,Z,U,V,SFCT/])
delete([/T0,TSTAR,alpha,beta/])

;list_vars()

end do

end

