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

;YYYY="1996"
;VAR="rof"   ; tprat or srweg
;SYMDIR="/glade/u/home/zarzycki/scratch/JRAsym/"+YYYY+"/"
;OUTDIR=SYMDIR

if (VAR .eq. "prmsl")
  FILES = systemfunc ("ls "+SYMDIR+"/fcst_surf.*"+VAR+".reg_tl319*.grb2")
else if (VAR .eq. "srweq" .or. VAR .eq. "tprat")
  FILES = systemfunc ("ls "+SYMDIR+"/fcst_phy2m.*"+VAR+".reg_tl319*.grb2")
else if (VAR .eq. "snwe")
  FILES = systemfunc ("ls "+SYMDIR+"/fcst_land.*"+VAR+".reg_tl319*.grb2")
else if (VAR .eq. "rof")
  FILES = systemfunc ("ls "+SYMDIR+"/fcst_phyland.*"+VAR+".reg_tl319*.grb2")
else if (VAR .eq. "tmp")
  FILES = systemfunc ("ls "+SYMDIR+"/anl_surf.*"+VAR+".reg_tl319*.grb2")
else
  print("bad var")
  exit
end if
end if
end if
end if
end if

FILE=addfiles(FILES, "r")   ; note the "s" of addfile
ListSetType(FILE, "cat")             ; concatenate or "merge" (default)
print("...done loading files")

print(FILE)

if (VAR .eq. "tprat") then
  PRECVAR="TPRAT_GDS4_SFC_ave3h"
  OUTVAR="PRECT"
else if (VAR .eq. "srweq") then
  PRECVAR="SRWEQ_GDS4_SFC_ave3h"
  OUTVAR="PRECSN"
else if (VAR .eq. "prmsl") then
  PRECVAR="PRMSL_GDS4_MSL"
  OUTVAR="PSL"
else if (VAR .eq. "snwe") then
  PRECVAR="SnWe_GDS4_SFC"
  OUTVAR="SWE"
else if (VAR .eq. "rof") then
  PRECVAR="ROF_GDS4_SFC_ave3h"
  OUTVAR="ROF"
else if (VAR .eq. "tmp") then
  PRECVAR="TMP_GDS4_HTGL"
  OUTVAR="T2M"
else
  print("incorrect VAR... exiting...")
  exit
end if
end if
end if
end if
end if
end if

sizeDims=dimsizes(FILE[:]->$PRECVAR$)
if (dimsizes(sizeDims) .eq. 4) then
  ntim=sizeDims(0)
  nfor=sizeDims(1)  ; number of forecasts (generally 2)
  nlat=sizeDims(2)
  nlon=sizeDims(3)
  lat=FILE[0]->g4_lat_2(::-1)
  lon=FILE[0]->g4_lon_3
else
  ntim=sizeDims(0)
  nfor=0
  nlat=sizeDims(1)
  nlon=sizeDims(2)
  lat=FILE[0]->g4_lat_1(::-1)
  lon=FILE[0]->g4_lon_2
end if

timeix = ispan(0,ntim-1,1)
if (VAR .eq. "snwe") then
  numrecspfile = ntim/4
  nfiles=dimsizes(FILES)
  print(nfiles)
  do ii = 0,nfiles-1
    badix=ii*numrecspfile
    timeix=where(timeix.eq.badix,timeix@_FillValue,timeix)
  end do
  goodix = ind(.not.ismissing(timeix))
  timeix := timeix(goodix)
end if

year_time=FILE[:]->initial_time0_hours(timeix)
JRAunits=year_time@units

if (dimsizes(sizeDims) .eq. 4) then
  PRECSN=FILE[:]->$PRECVAR$(timeix,:,::-1,:)
else
  PRECSN=FILE[:]->$PRECVAR$(timeix,::-1,:)
end if

ms_to_mmday=8.64e7

if (dimsizes(sizeDims) .eq. 4) then
  if (VAR .eq. "prmsl")
    PRECSN_SUM=PRECSN(:,1,:,:)
  else
    if (VAR .eq. "snwe")
      PRECSN_SUM = dim_avg_n_Wrap(PRECSN,1)
    else
      ; Convert from mm/day to m/s to match CAM data
      PRECSN=PRECSN/ms_to_mmday
      ; Sum the +3 and +6 forecast average for each cycle
      PRECSN_SUM = dim_sum_n_Wrap(PRECSN,1)
      PRECSN_SUM = PRECSN_SUM / 2.0
    end if
  end if
else
  PRECSN_SUM=PRECSN
end if

PRECSN_SUM!0="time"
PRECSN_SUM!1="lat"
PRECSN_SUM!2="lon"

time=PRECSN_SUM&time
time@calendar="standard"
printVarSummary(time)
PRECSN_SUM&time=time
printVarSummary(PRECSN_SUM)

print("Writing file...")
fileName=OUTDIR+"/JRA.h1."+YYYY+"."+OUTVAR+".nc"
system("mkdir -p "+OUTDIR)   ; remove any pre-existing file
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

ncdf->$OUTVAR$ = PRECSN_SUM      

exit





TFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_mdl.011_tmp.*.grb2")
TFILE      = addfiles (TFILES, "r")   ; note the "s" of addfile
ListSetType (TFILE, "cat")             ; concatenate or "merge" (default)
print("...done with T")

QFILES = systemfunc ("ls "+SYMDIR+"/"+YEAR+"/anl_mdl.051_spfh.*.grb2")
QFILE      = addfiles (QFILES, "r")   ; note the "s" of addfile
ListSetType (QFILE, "cat")             ; concatenate or "merge" (default)
print("...done with Q")

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
Q=QFILE[:]->SPFH_GDS4_HYBL({time},:,::-1,:)
Z=ZFILE[:]->HGT_GDS4_HYBL({time},:,::-1,:)
PHIS=PHISFILE[:]->GP_GDS4_SFC(::-1,:)
U=UFILE[:]->UGRD_GDS4_HYBL({time},:,::-1,:)
V=VFILE[:]->VGRD_GDS4_HYBL({time},:,::-1,:)
SFCT=SFCTFILE[:]->TMP_GDS4_HTGL({time},::-1,:)

UBOT = U(0,:,:)
VBOT = V(0,:,:)
ZBOT = Z(0,:,:)

U850 = rm_single_dims(vinth2p(U(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),850.0,PS(:,:),2,1000.,1,False))
U700 = rm_single_dims(vinth2p(U(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),700.0,PS(:,:),2,1000.,1,False))
U500 = rm_single_dims(vinth2p(U(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),500.0,PS(:,:),2,1000.,1,False))
U200 = rm_single_dims(vinth2p(U(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),200.0,PS(:,:),2,1000.,1,False))

V850 = rm_single_dims(vinth2p(V(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),850.0,PS(:,:),2,1000.,1,False))
V700 = rm_single_dims(vinth2p(V(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),700.0,PS(:,:),2,1000.,1,False))
V500 = rm_single_dims(vinth2p(V(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),500.0,PS(:,:),2,1000.,1,False))
V200 = rm_single_dims(vinth2p(V(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),200.0,PS(:,:),2,1000.,1,False))

T850 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),850.0,PS(:,:),2,1000.,1,False))
T700 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),700.0,PS(:,:),2,1000.,1,False))
T500 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),500.0,PS(:,:),2,1000.,1,False))
T400 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),400.0,PS(:,:),2,1000.,1,False))
T300 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),300.0,PS(:,:),2,1000.,1,False))
T200 = rm_single_dims(vinth2p(T(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),200.0,PS(:,:),2,1000.,1,False))

Z1000 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),1000.0,PS(:,:),2,1000.,1,False))
Z850 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),850.0,PS(:,:),2,1000.,1,False))
Z500 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),500.0,PS(:,:),2,1000.,1,False))
Z400 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),400.0,PS(:,:),2,1000.,1,False))
Z300 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),300.0,PS(:,:),2,1000.,1,False))
Z200 = rm_single_dims(vinth2p(Z(::-1,:,:),hyam(::-1)/100000.,hybm(::-1),200.0,PS(:,:),2,1000.,1,False))

; Poisson grid filling since JRA on pressure levels are not filled in
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

poisson_grid_fill(Z1000, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z400, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z300, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill(Z200, is_cyclic, guess, nscan, eps, relc, opt)

arrType="float"
UBOT_ = new((/1,nlat,nlon/),arrType)
UBOT_(0,:,:) = UBOT
VBOT_ = new((/1,nlat,nlon/),arrType)
VBOT_(0,:,:) = VBOT
ZBOT_ = new((/1,nlat,nlon/),arrType)
ZBOT_(0,:,:) = ZBOT

U850_ = new((/1,nlat,nlon/),arrType)
U850_(0,:,:) = U850
U700_ = new((/1,nlat,nlon/),arrType)
U700_(0,:,:) = U700
U500_ = new((/1,nlat,nlon/),arrType)
U500_(0,:,:) = U500
U200_ = new((/1,nlat,nlon/),arrType)
U200_(0,:,:) = U200

V850_ = new((/1,nlat,nlon/),arrType)
V850_(0,:,:) = V850
V700_ = new((/1,nlat,nlon/),arrType)
V700_(0,:,:) = V700
V500_ = new((/1,nlat,nlon/),arrType)
V500_(0,:,:) = V500
V200_ = new((/1,nlat,nlon/),arrType)
V200_(0,:,:) = V200

T850_ = new((/1,nlat,nlon/),arrType)
T850_(0,:,:) = T850
T700_ = new((/1,nlat,nlon/),arrType)
T700_(0,:,:) = T700
T500_ = new((/1,nlat,nlon/),arrType)
T500_(0,:,:) = T500
T400_ = new((/1,nlat,nlon/),arrType)
T400_(0,:,:) = T400
T300_ = new((/1,nlat,nlon/),arrType)
T300_(0,:,:) = T300
T200_ = new((/1,nlat,nlon/),arrType)
T200_(0,:,:) = T200

Z1000_ = new((/1,nlat,nlon/),arrType)
Z1000_(0,:,:) = Z1000
Z850_ = new((/1,nlat,nlon/),arrType)
Z850_(0,:,:) = Z850
Z500_ = new((/1,nlat,nlon/),arrType)
Z500_(0,:,:) = Z500
Z400_ = new((/1,nlat,nlon/),arrType)
Z400_(0,:,:) = Z400
Z300_ = new((/1,nlat,nlon/),arrType)
Z300_(0,:,:) = Z300
Z200_ = new((/1,nlat,nlon/),arrType)
Z200_(0,:,:) = Z200

PS_ = new((/1,nlat,nlon/),arrType)
PS_(0,:,:) = PS

print("Calculating Vorts")
VR850 = V850_
VR850 = uv2vrF(U850_,V850_)
VR500 = V500_
VR500 = uv2vrF(U500_,V500_)
VR200 = V200_
VR200 = uv2vrF(U200_,V200_)

latsign = lat
latsign = where(lat .lt. 0.0,-1.0,1.0)
;printVarSummary(latsign)
latsign2d = tofloat(conform(U850_,latsign,1))
VR850 = VR850*latsign2d
VR500 = VR500*latsign2d
VR200 = VR200*latsign2d

;P3D=T

;hyai3D=conform_dims((/nlev+1,nlat,nlon/),hyai,0)
;hybi3D=conform_dims((/nlev+1,nlat,nlon/),hybi,0)
;PS3D=conform_dims((/nlev+1,nlat,nlon/),PS,(/1,2/))

;presi=hyai3D+hybi3D*PS3D

;deltapresi=presi(0:59,:,:)-presi(1:60,:,:)

;P3D=exp((1/deltapresi)*(presi(0:59,:,:)*log(presi(0:59,:,:))-presi(1:60,:,:)*log(presi(1:60,:,:)))-1)
;P3D(59,:,:)=10.
; do j = 0,nlat-1
; print("Doing "+j+" of "+nlat)
; do k = 0,nlon-1
; ;print("Doing "+j+" "+k)
; presi=hyai+hybi*PS(j,k)
; do i = 1,60
;   deltapresi=presi(i-1)-presi(i)
;   presm(i-1)=exp((1/deltapresi)*(presi(i-1)*log(presi(i-1))-presi(i)*log(presi(i)))-1)
;   ;print(" "+deltapresi)
; end do
; presm(59)=10.
; P3D(:,j,k)=presm
; end do
; end do

;hyai3D=conform_dims(dimsizes(T),hyai,0)
;hybi3D=conform_dims(dimsizes(T),hybi,0)
;PS3D=conform_dims(dimsizes(T),PS,(/1,2/))

;P = PS
;P = hyai3D+hyai3D*(PS3D)

;R = Q
;R = Q/(1-Q)
;Tv = T
;Tv = T*(1-0.61*R)
;PSL = pslhyp(PS(:,:),Z(0,:,:),Tv(0,:,:))

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


;   alpha = rair*xlapse/gravit
;   do i=1,ncol
;      if ( abs(phis(i)/gravit) < 1.e-4_r8 )then
;         psl(i)=ps(i)
;      else
; 
;         Tstar=T(i,pver)*(1._r8+alpha*(ps(i)/pmid(i,pver)-1._r8)) ! pg 7 eq 5
; 
;         TT0=Tstar + xlapse*phis(i)/gravit                  ! pg 8 eq 13
; 
;         if ( Tstar<=290.5_r8 .and. TT0>290.5_r8 ) then           ! pg 8 eq 14.1
;            alph=rair/phis(i)*(290.5_r8-Tstar)
;         else if (Tstar>290.5_r8  .and. TT0>290.5_r8) then        ! pg 8 eq 14.2
;            alph=0._r8
;            Tstar= 0.5_r8 * (290.5_r8 + Tstar)
;         else
;            alph=alpha
;            if (Tstar<255._r8) then
;               Tstar= 0.5_r8 * (255._r8 + Tstar)                  ! pg 8 eq 14.3
;            endif
;         endif
; 
;         beta = phis(i)/(rair*Tstar)
;         psl(i)=ps(i)*exp( beta*(1._r8-alph*beta/2._r8+((alph*beta)**2)/3._r8))
;      end if
;   enddo
; 
;   return
; end subroutine cpslec
; ~                            




;PSL=PS*(1+alpha*PHIS(:,:)/Rd/SFCT(:,:))^(1/alpha)



;PSL=PS*(1-(0.0065*Z(0,:,:)/(Tv(0,:,:)+0.0065*Z(0,:,:))))^(-5.257)

;Rd=287.1
;PSL=PS*exp(Z(0,:,:)*9.81/(Rd*SFCT(:,:)))

;PSL = PS
;PSL = PS / exp(-Z(0,:,:)/(Tv(0,:,:)*29.263))




     
;************************************************
; calculate T on pressure levels
;************************************************
; note, the 7th argument is not used, and so is set to 1.
;************************************************


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

copy_VarMeta(U850_,VR850)
copy_VarMeta(U850_,VR500)
copy_VarMeta(U850_,VR200)

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

print("Smoothing vort")
; Regrid VR850, VR500, VR200 for Hodges tracker
latS =    -90
latN =   90
;  lonW = -180
;  lonE =    180
lonW = 0
lonE =    360

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

VR850_T42_nat  = area_hi2lores_Wrap(VR850&lon,VR850&lat,VR850,True,1,T42_lon,T42_lat,False)    
VR850_T63_nat  = area_hi2lores_Wrap(VR850&lon,VR850&lat,VR850,True,1,T63_lon,T63_lat,False)
VR500_T63_nat  = area_hi2lores_Wrap(VR500&lon,VR500&lat,VR500,True,1,T63_lon,T63_lat,False)
VR200_T63_nat  = area_hi2lores_Wrap(VR200&lon,VR200&lat,VR200,True,1,T63_lon,T63_lat,False)

VR850_T42 = linint2_Wrap(T42_lon,T42_lat,VR850_T42_nat,True,lon,lat,0)
VR850_T63 = linint2_Wrap(T63_lon,T63_lat,VR850_T63_nat,True,lon,lat,0)
VR500_T63 = linint2_Wrap(T63_lon,T63_lat,VR500_T63_nat,True,lon,lat,0)
VR200_T63 = linint2_Wrap(T63_lon,T63_lat,VR200_T63_nat,True,lon,lat,0)

copy_VarMeta(VR850,VR850_T42)
copy_VarMeta(VR850,VR850_T63)
copy_VarMeta(VR850,VR500_T63)
copy_VarMeta(VR850,VR200_T63)

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
;ncdf->Z1000= Z1000_
;ncdf->ZBOT= Z1000_
ncdf->DZ200500 = DZ200500_
ncdf->DZ300500 = DZ300500_
ncdf->DZ400500 = DZ400500_
ncdf->DZ200400 = DZ200400_
ncdf->DZ300400 = DZ300400_
ncdf->DZ200850 = DZ200850_
ncdf->VR850=VR850
ncdf->VR500=VR500
ncdf->VR200=VR200

ncdf->VR850_T63 = VR850_T63
ncdf->VR500_T63 = VR500_T63
ncdf->VR200_T63 = VR200_T63
ncdf->VR850_T42 = VR850_T42

print("... done writing file")

delete([/U850,V850,U700,V700,U500,V500,U200,V200,UBOT,VBOT,T200,T300,T400,T500,T700,T850,PSL,PS,Z200,Z300,Z400,Z500,Z1000,ZBOT/])
delete([/U850_,V850_,U700_,V700_,U500_,V500_,U200_,V200_,UBOT_,VBOT_,T200_,T300_,T400_,T500_,T700_,T850_,PSL_,PS_,Z200_,Z300_,Z400_,Z500_,Z1000_,ZBOT_/])
delete([/DZ200500_,DZ300500_,DZ400500_,DZ200400_,DZ300400_,DZ200850_/])
delete([/VR850,VR500,VR200/])
delete([/VR850_T63,VR500_T63,VR200_T63,VR850_T42/])
delete([/VR850_T42_nat,VR850_T63_nat,VR500_T63_nat,VR200_T63_nat/])
delete([/dlon,dlat,T63_nlat,T42_nlat,T63_mlon,T63_mlon/])
delete([/PHIS,T,Q,Z,U,V,SFCT/])
delete([/T0,TSTAR,alpha,beta/])

;list_vars()

end do

end

