undef ( "calc_srh" )
function calc_srh( \
  z[*]           : numeric, \
  ua[*]           : numeric, \
  va[*]           : numeric, \
  zbot            : numeric, \
  ztop            : numeric, \
  ustorm          : numeric, \
  vstorm          : numeric \
)
local NW,ur,vr,ii,omegax,omegay,um,vm,H,ixbot,ixtop,h3km

begin

NW = dimsizes(z)

; Determine storm relative velocity at each level
ur = new(NW,"float")
vr = new(NW,"float")
do ii = 0,NW-1
  ur(ii) = ua(ii)-ustorm
  vr(ii) = va(ii)-vstorm
end do

; Calculate horizontal vorticity in each layer
omegax = new(NW,"float")
omegay = new(NW,"float")
do ii = 1,NW-1
  omegax(ii) = -(va(ii)-va(ii-1)) / (z(ii)-z(ii-1))
  omegay(ii) =  (ua(ii)-ua(ii-1)) / (z(ii)-z(ii-1))
end do

; Calculate storm-relative velocity in each layer
um = new(NW,"float")
vm = new(NW,"float")
do ii = 1,NW-1
  um(ii) = 0.5*(ur(ii) + ur(ii-1))
  vm(ii) = 0.5*(vr(ii) + vr(ii-1))
end do

; Calculate storm-relative helicity in each layer
H = new(NW,"float")
do ii = 1,NW-1
  H(ii) = um(ii)*omegax(ii)+vm(ii)*omegay(ii)
end do

; Find 3km index
ixbot=closest_val(zbot,z)
if (ixbot .lt. 1) then
  ixbot=1
end if
ixtop=closest_val(ztop,z)

; Calculate storm-relative helicity 0-3km
h3km = 0.0
do ii = ixbot,ixtop-1
  h3km = h3km + H(ii)*(z(ii)-z(ii-1))
end do

return(h3km)

end



undef ( "calc_shear" )
; This function calculates wind shear between two levels given U and V wind components
; INPUTS:
;   z = 1-D array of heights [m] oriented from bottom - top
;   uu = 1-D array of u winds [m/s] oriented as Z
;   vv = 1-D array of v winds [m/s] oriented as Z
;   zbot = single value, bottom of shear layer [m]
;   ztop = single value, top of shear layer [m]
function calc_shear( \
  z[*]           : numeric, \
  uu[*]           : numeric, \
  vv[*]           : numeric, \
  zbot            : numeric, \
  ztop            : numeric \
)
local sheartopix,shearbotix,ushear,vshear,shear

begin

; check to make sure dimsizes of z and u/v arrays are same -- if not, exit since sub-indexing
; might be incorrect
if (dimsizes(uu) .ne. dimsizes(z) .or. dimsizes(vv) .ne. dimsizes(z)) then
  print("calc_shear: FATAL: dimsizes of Z and U/V arrays inconsistent, exiting...")
  exit
end if

; find shear top index
sheartopix=closest_val(ztop,z)
shearbotix=closest_val(zbot,z)
; calc u/v shear independently, then shear mag
ushear = uu(sheartopix) - uu(shearbotix)
vshear = vv(sheartopix) - vv(shearbotix)
shear = sqrt(ushear^2 + vshear^2)

return(shear)

end







undef ( "get_column_pz" )
function get_column_pz( \
  hyam[*]           : numeric, \
  hybm[*]           : numeric, \
  tv[*]             : numeric, \
  zsfc              : numeric, \
  psfc              : numeric, \
  p0                : numeric \
)
local nlev,p,g,rdair,rdag,zh,ii,tvbar,returnvar

begin

nlev=dimsizes(hyam)

; calculate p at all levels
p = new(nlev,"float")
p = tofloat(hyam)*tofloat(p0) + tofloat(hybm)*tofloat(psfc)

g = 9.80665
rdair = 287.04
rdag = rdair/g

zh = new(nlev,"float")

do ii = 0,nlev-1
  if (ii .eq. 0) then ; surface
    tvbar = tv(ii)
    zh(ii) = zsfc + rdag*tvbar*log(psfc/p(ii))
  else
    tvbar = (tv(ii)*log(p(ii)) + tv(ii-1)*log(p(ii-1))) / log(p(ii)*p(ii-1))
    zh(ii) = zh(ii-1) + rdag*tvbar*log(p(ii-1)/p(ii))
  end if
end do

returnvar = new((/2,nlev/),"float")
returnvar(0,:) = p
returnvar(1,:) = zh

return(returnvar)


end









undef ( "calc_storm_motion_uv" )
; This function calculates wind shear between two levels given U and V wind components
; INPUTS:
;   z = 1-D array of heights [m] oriented from bottom - top
;   uu = 1-D array of u winds [m/s] oriented as Z
;   vv = 1-D array of v winds [m/s] oriented as Z
;   zbot = single value, bottom of shear layer [m]
;   ztop = single value, top of shear layer [m]
function calc_storm_motion_uv( \
  Z[*]            : numeric, \
  P[*]            : numeric, \
  uu[*]           : numeric, \
  vv[*]           : numeric, \
  zbot            : numeric, \
  ztop            : numeric \
)
local pi,zint,uuint,vvint,ppint,stormuu,stormvv, \
   tmpu,tmpalpha,stormmotionuv

begin

pi = 3.14159

zint=fspan(zbot,ztop,1000)
uuint = linint1 (Z, uu, False, zint, 0)
vvint = linint1 (Z, vv, False, zint, 0)
ppint = linint1 (Z, P,  False, zint, 0)

; Get pressure weighted uu and vv
stormuu=sum(uuint*ppint/sum(ppint))
stormvv=sum(vvint*ppint/sum(ppint))

; Back out u mag and then angle
tmpu=sqrt(stormuu^2+stormvv^2)
tmpalpha=acos(stormuu/tmpu)*180./pi

; angle is 30 deg to right
tmpalpha=tmpalpha-30.

; reduce wind by 75%
tmpu=tmpu*.75

; recalc storm-relative uu/vv wind from mag/angle
stormuu=tmpu*cos(tmpalpha*pi/180.)
stormvv=tmpu*sin(tmpalpha*pi/180.)

stormmotionuv = new(2,"float")
stormmotionuv(0) = stormuu
stormmotionuv(1) = stormvv

return(stormmotionuv)

end




undef ( "calc_uv_from_sounding_mag_dir" )
; This function calculates U and V wind components from udir/uspd from a radiosonde report
; (generally procured through UWyo
; INPUTS:
;   udir = 1-D array of wind dir [deg] oriented from bottom - top
;   uspd = 1-D array of wind mag [m/s] oriented from bottom - top
function calc_uv_from_sounding_mag_dir( \
  udir[*]            : numeric, \
  uspd[*]            : numeric \
)
local pi,alpha,uu,vv,sizeuu,returnuv

begin

pi=3.14159
alpha = 360.0-(udir-180.-90.)
uu = uspd*cos(alpha*pi/180.)
vv = uspd*sin(alpha*pi/180.)
sizeuu=dimsizes(uu)
returnuv=new((/2,sizeuu/),"float")
returnuv(0,:)=uu(:)
returnuv(1,:)=vv(:)

return(returnuv)

end



undef ( "get_LCL_LFC_from_sounding" )
; This function calculates U and V wind components from udir/uspd from a radiosonde report
; (generally procured through UWyo
; INPUTS:
;   udir = 1-D array of wind dir [deg] oriented from bottom - top
;   uspd = 1-D array of wind mag [m/s] oriented from bottom - top
function get_LCL_LFC_from_sounding( \
  p[*]           : numeric, \
  t[*]           : numeric, \
  q[*]           : numeric, \
  z[*]           : numeric, \
  elev           : numeric, \
  psfc           : numeric \
)
local nrows,PIN,TIN,QVIN,ZIN,HGTIN,PSFCIN,cinfo,LCL,LFC,LFCix,LCLix,returnvar

begin

nrows = dimsizes(z)

PIN=new((/nrows,1,1/),"float")
PIN(:,0,0)=p
TIN=new((/nrows,1,1/),"float")
TIN(:,0,0)=t
QVIN=new((/nrows,1,1/),"float")
QVIN(:,0,0)=q
ZIN=new((/nrows,1,1/),"float")
ZIN(:,0,0)=z
HGTIN=new((/1,1/),"float")
HGTIN=elev
PSFCIN=new((/1,1/),"float")
PSFCIN=psfc

cinfo = wrf_cape_2d( PIN, TIN, QVIN, ZIN, HGTIN, PSFCIN, True )

LCL=cinfo(2,0,0)
LFC=cinfo(3,0,0)

;NCL returns LFC/LCL AGL, so to convert to pressure we have to add sfc elevation back in...
LFC=LFC+elev
LCL=LCL+elev
LFCix=closest_val(LFC,z)
LCLix=closest_val(LCL,z)
LFC=LFC-elev
LCL=LCL-elev

returnvar=new(4,"float")
returnvar(0) = LCL
returnvar(1) = LFC
returnvar(2) = LCLix
returnvar(3) = LFCix

return(returnvar)

end






undef ( "get_3DCAPE_from_sounding" )
; This function calculates U and V wind components from udir/uspd from a radiosonde report
; (generally procured through UWyo
; INPUTS:
;   udir = 1-D array of wind dir [deg] oriented from bottom - top
;   uspd = 1-D array of wind mag [m/s] oriented from bottom - top
function get_3DCAPE_from_sounding( \
  p[*]           : numeric, \
  t[*]           : numeric, \
  q[*]           : numeric, \
  z[*]           : numeric, \
  elev           : numeric, \
  psfc           : numeric \
)
local nrows,PIN,TIN,QVIN,ZIN,HGTIN,PSFCIN,dinfo,CAPE3D,CIN3D,returnCAPE

begin

nrows = dimsizes(z)

PIN=new((/nrows,1,1/),"float")
PIN(:,0,0)=p
TIN=new((/nrows,1,1/),"float")
TIN(:,0,0)=t
QVIN=new((/nrows,1,1/),"float")
QVIN(:,0,0)=q
ZIN=new((/nrows,1,1/),"float")
ZIN(:,0,0)=z
HGTIN=new((/1,1/),"float")
HGTIN=elev
PSFCIN=new((/1,1/),"float")
PSFCIN=psfc

dinfo=wrf_cape_3d(PIN, TIN, QVIN, ZIN, HGTIN, PSFCIN, True)
CAPE3D=dinfo(0,:,:,:)
CIN3D=-dinfo(1,:,:,:)

returnCAPE=new((/2,nrows/),"float")
returnCAPE(0,:) = CAPE3D(:,0,0)
returnCAPE(1,:) = CIN3D(:,0,0)

return(returnCAPE)

end






undef ( "get_severe_indices" )
; This function calculates U and V wind components from udir/uspd from a radiosonde report
; (generally procured through UWyo
; INPUTS:
;   udir = 1-D array of wind dir [deg] oriented from bottom - top
;   uspd = 1-D array of wind mag [m/s] oriented from bottom - top
function get_severe_indices( \
  P[*]           : numeric, \
  T[*]           : numeric, \
  QV[*]           : numeric, \
  Z[*]           : numeric, \
  uu[*]           : numeric, \
  vv[*]           : numeric, \
  HGT           : numeric, \
  PSFC           : numeric \
)
local nrows,LCLLFCvar,LCL,LFC,LCLix,LFCix,CAPEvar,CAPE3D,CIN3D,MUCAPE,SBCAPE, \
      MUCIN,SBCIN,stormmotionuv,stormuu,stormvv,inflow_ix,inflow_bot,srheff, \
      ii,srh3km,srh1km,shear,TERM1,TERM2,TERM3,TERM4,SCP,SIGTORFIX,returnvar

begin

nrows = dimsizes(Z)

; get LCL, LFC, and every-level CAPE/CIN from sounding
LCLLFCvar=get_LCL_LFC_from_sounding(P,T,QV,Z,HGT,PSFC)
LCL=LCLLFCvar(0)
LFC=LCLLFCvar(1)
LCLix=toint(LCLLFCvar(2))
LFCix=toint(LCLLFCvar(3))
delete(LCLLFCvar)
CAPEvar=get_3DCAPE_from_sounding(P,T,QV,Z,HGT,PSFC)
CAPE3D = CAPEvar(0,:)
CIN3D = CAPEvar(1,:)
delete(CAPEvar)

; calculate MUCAPE, SBCAPE, MUCIN, SBCIN
MUCAPE=max(CAPE3D)    ; max CAPE
SBCAPE=CAPE3D(0)  ; surface CAPE
MUCIN=CIN3D(maxind(CAPE3D))   ; cin @ max CAPE
SBCIN=CIN3D(0)    ; CIN @ surface

MUCAPE = where(ismissing(MUCAPE),0.,MUCAPE)
SBCAPE = where(ismissing(SBCAPE),0.,SBCAPE)
MUCIN  = where(ismissing(MUCIN) ,0.,MUCIN )
SBCIN  = where(ismissing(SBCIN) ,0.,SBCIN )




; get storm motion U and V
stormmotionuv = calc_storm_motion_uv(Z,P,uu,vv,0.0,6000.0)
stormuu = stormmotionuv(0)
stormvv = stormmotionuv(1)
delete(stormmotionuv)

; Calc effective SRH
inflow_ix=-1
inflow_bot=0.0
if(all(ismissing(CIN3D))) .or. all(ismissing(CAPE3D) .or. (max(CAPE3D) .lt. 100.) .or. (max(CIN3D) .lt. -250.))
  ;print("cannot find!")
  srheff=0.0
else
  CAPE3D=where(ismissing(CAPE3D),0.,CAPE3D)
  CIN3D=where(ismissing(CIN3D),-260.,CIN3D)
  do ii = 0,nrows-1
    if(CAPE3D(ii) .ge. 100. .and. CIN3D(ii) .ge. -250.) then
      inflow_bot = Z(ii)
      inflow_ix = ii
      break
    end if
  end do
  if (inflow_ix .eq. -1) then
    srheff=0.0
    break
  else
    do ii = inflow_ix,nrows-1
      if(CAPE3D(ii) .lt. 100. .and. CIN3D(ii) .lt. -250.) then
        inflow_top = Z(ii)
        break
      end if
    end do
    ;print(inflow_top+" "+inflow_bot)
    srheff = calc_srh(Z,uu,vv,inflow_bot,inflow_top,stormuu,stormvv)
  end if
end if

; calc fixed level SRH
srh3km = calc_srh(Z,uu,vv,0.,3000.,stormuu,stormvv)
srh1km = calc_srh(Z,uu,vv,0.,1000.,stormuu,stormvv)

; Calc 0-6km shear
shear = calc_shear(Z,uu,vv,0.0,6000.0)

;SCP = (muCAPE / 1000 J/kg) * (EBWD / 10 m/s) * (ESRH / 50 m2/s2)
;where ESRH = storm-relative helicity for the effective inflow layer using an assumed supercell motion
;and the EBWD = effective bulk wind difference over the lower half of the storm depth (effective inflow base to EL height).
;The EBWD term is capped at a value of 1.5 (e.g., EBWD > 30 m/s is set to 30 m/s), and this same term is set to zero when EBWD < 10 m/s.
TERM1 = (MUCAPE / 1000.)
TERM2 = (shear / 20.)
if (TERM2 .lt. 0.5) then
  TERM2 = 0.0
else if (TERM2 .gt. 1.5) then
  TERM2 = 1.5
else
end if
end if
TERM3 = (srheff / 50.)
SCP = TERM1 * TERM2 * TERM3

;Sig Tor (fixed) = (sbCAPE / 1500 J/kg) * (0-1 km SRH / 150 m2/s2) * (EBWD / 12 m/s) * ((2000 - mlLCL) / 1000)
;where "ml" denotes the lowest 100 mb mean parcel, ESRH = the effective storm-relative helicity, 
;EBWD = the effective bulk wind difference over the lower half of the storm depth (effective inflow base to EL height). 
;The EBWD term is capped at a value of 1.5 as in the Supercell Composite Parameter, though the minumum value is raised to 12 m/s.
;The mlLCL term is set to 1 for mlLCL heights < 1000 m AGL, and the mlCINH is set to 1 for mlCINH values > -50 J/kg.
;SIGTORFIX = (SBCAPE / 1500.) * (srh1km / 150.) * (totshear / 12.) * ((2000. - LCL) / 1000.)
TERM1 = (SBCAPE / 1500.)
TERM2 = (srh1km / 150.)
TERM3 = (shear / 12.)
TERM4 = ((2000. - LCL) / 1000.)
if (TERM3 .gt. 1.5) then
  TERM3 = 1.5
end if
if (TERM4 .gt. 1.0) then
  TERM4 = 1.0
end if
SIGTORFIX = TERM1 * TERM2 * TERM3 * TERM4

;SHIP = [(MUCAPE j/kg) * (Mixing Ratio of MU PARCEL g/kg) * (700-500mb LAPSE RATE c/km) * (-500mb TEMP C) * (0-6km Shear m/s) ] / 42,000,000



;print("-----------------------------------------------------------------------")
;print("MUCAPE: "+MUCAPE+" J/kg")
;print("MUCIN: "+MUCIN+" J/kg")
;print("SBCAPE: "+SBCAPE+" J/kg")
;print("LFC height: "+LFC+" m       pressure: "+P(LFCix))
;print("LCL height: "+LCL+" m       pressure: "+P(LCLix))
;print("srheff: "+srheff)
;print("srh3km: "+srh3km)
;print("srh1km: "+srh1km)
;print("shear: "+shear+" m/s    "+(shear*1.9)+" kts")
;print("SCP: "+SCP)
;print("SIGTORFIX: "+SIGTORFIX)

returnvar=new(11,"float")
returnvar(0)=SCP
returnvar(1)=SIGTORFIX
returnvar(2)=shear
returnvar(3)=srh1km
returnvar(4)=srh3km
returnvar(5)=srheff
returnvar(6)=MUCAPE
returnvar(7)=SBCAPE
returnvar(8)=MUCIN
returnvar(9)=LFC
returnvar(10)=LCL

return(returnvar)

end

