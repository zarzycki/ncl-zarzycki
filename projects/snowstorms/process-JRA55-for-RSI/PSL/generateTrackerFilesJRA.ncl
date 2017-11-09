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

arrType="float"

; Get times =====================================================

dateListArr = asciiread(timeArrFile,-1,"string")

print("Getting raw JRA files...")
wcStrt     = systemfunc("date")

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

sizeDims=dimsizes(SFCTFILE[:]->TMP_GDS4_HTGL(0,:,:))
nlat=sizeDims(0)
nlon=sizeDims(1)
lat=SFCTFILE[0]->g4_lat_1(::-1)
lon=SFCTFILE[0]->g4_lon_2

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
PHIS=PHISFILE[:]->GP_GDS4_SFC(::-1,:)
SFCT=SFCTFILE[:]->TMP_GDS4_HTGL({time},::-1,:)

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

PSL_!0    = "time"
PSL_!1    = "lat"
PSL_!2    = "lon"
PSL_&time = thisTime
PSL_&lat  = lat
PSL_&lon  = lon 

delete_VarAtts(PSL_, -1)
PSL_@long_name="Mean sea level pressure"
PSL_@units="Pa"

print("Writing file...")
fileName=OUTDIR+"/tmp.JRA.h1."+thisDate+".nc"
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

ncdf->PSL  = PSL_

print("... done writing file")

delete([/PSL/])
delete([/PSL_/])
delete([/PHIS,SFCT/])
delete([/T0,TSTAR,alpha,beta/])

end do

end

