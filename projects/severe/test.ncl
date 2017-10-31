load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.NEW.ncl"

begin


nrows=50
z1 = asciiread("sounding-test5.txt",(/nrows,11/),"float")

P=z1(:,0)*100.        ;Pa
Z=z1(:,1)             ;m
T=z1(:,2)+273.15      ;K
QV=z1(:,5)/1000.      ;kg/kg
udir=z1(:,6)          ; deg
uspd=z1(:,7)/1.94384  ; kts -> m/s
HGT=Z(0)              ; station elevation
PSFC=P(0)/100.        ; station pressure (mb)

Z=Z-HGT

; get U and V components from sounding
uuvv=calc_uv_from_sounding_mag_dir(udir,uspd)
uu = uuvv(0,:)
vv = uuvv(1,:)
delete(uuvv)


;---------------------------------------------

SCP = get_severe_indices(P,T,QV,Z,uu,vv,HGT,PSFC)

print(SCP)

end
