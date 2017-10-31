load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************

pi=3.14159
g=9.81
nrows=50
z1 = asciiread("sounding-test5.txt",(/nrows,11/),"float")

P=z1(:,0)*100.     ;Pa
Z=z1(:,1)          ;m
Z=Z-Z(0)
T=z1(:,2)+273.15   ;K
TD=z1(:,3)+273.15
RH=z1(:,4)
QV=z1(:,5)/1000.
;udir=z1(:,6)*pi/180.          ; deg -> rad
udir=z1(:,6)         ; deg -> rad
uspd=z1(:,7)/1.94384  ; kts -> m/s
THETAA=z1(:,8)
THETAE=z1(:,9)
THETAV=z1(:,10)
HGT=Z(0)
PSFC=P(0)/100.

PIN=new((/nrows,1,1/),"float")
PIN(:,0,0)=P
TIN=new((/nrows,1,1/),"float")
TIN(:,0,0)=T
QVIN=new((/nrows,1,1/),"float")
QVIN(:,0,0)=QV
ZIN=new((/nrows,1,1/),"float")
ZIN(:,0,0)=Z

HGTIN=new((/1,1/),"float")
HGTIN=HGT
PSFCIN=new((/1,1/),"float")
PSFCIN=PSFC

; >> cinfo = wrf_cape_2d( PIN, TIN, QVIN, ZIN, HGTIN, PSFCIN, True )
; >> 
; >> ;print(cinfo)
; >> 
; >> ;MUCAPE=cinfo(0,0,0)
; >> ;CIN=cinfo(1,0,0)
; >> LCL=cinfo(2,0,0)
; >> LFC=cinfo(3,0,0)
; >> 
; >> ;NCL returns LFC/LCL AGL, so to convert to pressure we have to add sfc elevation back in...
; >> LFC=LFC+HGT
; >> LCL=LCL+HGT
; >> LFCix=closest_val(LFC,Z)
; >> LCLix=closest_val(LCL,Z)
; >> LFC=LFC-HGT
; >> LCL=LCL-HGT

LCLLFCvar=get_LCL_LFC_from_sounding(P,T,QV,Z,HGT,PSFC)
LCL=LCLLFCvar(0)
LFC=LCLLFCvar(1)
LCLix=toint(LCLLFCvar(2))
LFCix=toint(LCLLFCvar(3))

CAPEvar=get_3DCAPE_from_sounding(P,T,QV,Z,HGT,PSFC)
CAPE3D = CAPEvar(0,:)
CIN3D = CAPEvar(1,:)

; >> dinfo=wrf_cape_3d(PIN, TIN, QVIN, ZIN, HGTIN, PSFCIN, True)
; >> CAPE3D=dinfo(0,:,:,:)
; >> CIN3D=-dinfo(1,:,:,:)
; >> MUCAPE=max(CAPE3D)    ; max CAPE
; >> SBCAPE=CAPE3D(0,:,:)  ; surface CAPE
; >> MUCIN=CIN3D(maxind(CAPE3D(:,0,0)),:,:)   ; cin @ max CAPE
; >> SBCIN=CIN3D(0,:,:)    ; CIN @ surface

MUCAPE=max(CAPE3D)    ; max CAPE
SBCAPE=CAPE3D(0)  ; surface CAPE
MUCIN=CIN3D(maxind(CAPE3D))   ; cin @ max CAPE
SBCIN=CIN3D(0)    ; CIN @ surface


uuvv=calc_uv_from_sounding_mag_dir(udir,uspd)
uu = uuvv(0,:)
vv = uuvv(1,:)


;uu = -uspd*sin(udir)
;vv = -uspd*cos(udir)


; >> stormu=43./1.94384
; >> stormdir=221.
; >> stormalpha=360.0-(stormdir-180.-90.)
; >> stormuu=stormu*cos(stormalpha*pi/180.)
; >> stormvv=stormu*sin(stormalpha*pi/180.)
; >> ;print("Calced from Bunkers")
; >> ;print(stormuu+" "+stormvv)
; >> 
; >> ;print(uu+" "+vv)

; >> zint=fspan(0.0,6000.0,1000)
; >> uuint = linint1 (Z(0:35), uu(0:35), False, zint, 0)
; >> vvint = linint1 (Z(0:35), vv(0:35), False, zint, 0)
; >> ppint = linint1 (Z(0:35), P(0:35), False, zint, 0)
; >> 
; >> ;stormalphaint = linint1 (Z(0:35), alpha(0:35), False, zint, 0)
; >> ;stormuint = linint1 (Z(0:35), uspd(0:35), False, zint, 0)
; >> ;
; >> ;stormuu=avg(stormuint)*cos(avg(stormalphaint)*pi/180.)
; >> ;stormvv=avg(stormuint)*sin(avg(stormalphaint)*pi/180.)
; >> 
; >> 
; >> stormuu=sum(uuint*ppint/sum(ppint))
; >> stormvv=sum(vvint*ppint/sum(ppint))
; >> ;print("Calced from average")
; >> ;print(stormuu+" "+stormvv)
; >> tmpu=sqrt(stormuu^2+stormvv^2)
; >> tmpalpha=acos(stormuu/tmpu)*180./pi
; >> ;print("first pass")
; >> ;print(tmpalpha+" "+tmpu)
; >> 
; >> tmpalpha=tmpalpha-30.
; >> tmpu=tmpu*.75
; >> ;print("updated pass")
; >> ;print(tmpalpha+" "+tmpu)
; >> stormuu=tmpu*cos(tmpalpha*pi/180.)
; >> stormvv=tmpu*sin(tmpalpha*pi/180.)


stormmotionuv = calc_storm_motion_uv(Z,P,uu,vv,0.0,6000.0)
stormuu = stormmotionuv(0)
stormvv = stormmotionuv(1)


print("storm U/V: "+stormuu+" "+stormvv)
;print(CAPE3D+" "+CIN3D)

; Calc effective SRH
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
  do ii = inflow_ix,nrows-1
    if(CAPE3D(ii) .lt. 100. .and. CIN3D(ii) .lt. -250.) then
      inflow_top = Z(ii)
      break
    end if
  end do
  ;print(inflow_top+" "+inflow_bot)
  srheff = calc_srh(Z,uu,vv,inflow_bot,inflow_top,stormuu,stormvv)
end if

; calc fixed level SRH
srh3km = calc_srh(Z,uu,vv,0.,3000.,stormuu,stormvv)
srh1km = calc_srh(Z,uu,vv,0.,1000.,stormuu,stormvv)

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


print("-----------------------------------------------------------------------")
print("MUCAPE: "+MUCAPE+" J/kg")
print("MUCIN: "+MUCIN+" J/kg")
print("SBCAPE: "+SBCAPE+" J/kg")
print("LFC height: "+LFC+" m       pressure: "+P(LFCix))
print("LCL height: "+LCL+" m       pressure: "+P(LCLix))
print("srheff: "+srheff)
print("srh3km: "+srh3km)
print("srh1km: "+srh1km)
print("shear: "+shear+" m/s    "+(shear*1.9)+" kts")
print("SCP: "+SCP)
print("SIGTORFIX: "+SIGTORFIX)

end
