load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "omega.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "bourgouin_fcn.ncl"
load "cobb_fcn.ncl"

begin

T_m = (/-25.,-15.,-5./)
T_m = T_m+273.15
omega_m = (/5.,8.,12./)
z_i = (/500,1000,1500,2000/)
rh_m = (/95.,95.,95./)

ratio = cobb_fcn(omega_m,T_m,rh_m,z_i)

print(ratio)

end
