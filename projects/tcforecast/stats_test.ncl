;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

a = new(10,"float",-999)
a = (/1,2,3,4,5,6,7,8,9,10/)
;a(3) = a@_FillValue

opt = True
opt@PrintStat = True
statb = stat_dispersion(a, opt )

print("stdev = "+stddev(a))
print("variance = "+variance(a))

end

;========================================================
