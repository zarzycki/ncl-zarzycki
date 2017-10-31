load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.ncl"
begin

pi = 3.14159
z = (/0.,1.,2.,3.,4.,5.,6./)*1000.
udir = (/110.,150.,180.,190.,250.,270.,310./)
uspd = (/6.,10.,15.,17.,25.,30.,40./)

alpha = 360.0-(udir-180.-90.)
uu = uspd*cos(alpha*pi/180.)
vv = uspd*sin(alpha*pi/180.)

stormu=12.
stormdir=225.
stormalpha=360.0-(stormdir-180.-90.)

stormuu=stormu*cos(stormalpha*pi/180.)
stormvv=stormu*sin(stormalpha*pi/180.)

srh = calc_srh(z,z,uu,vv,7,0.0,0.0,stormuu,stormvv)

print(srh)

end
