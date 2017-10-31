load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;theVar = "Z500"
out_type="pdf"
;1001 and 1004
diff  =  addfile("/glade/u/home/zarzycki/scratch/nhemi_30_x4/run/diff.nc","r")
;1001 and 1003

;---Get all variables on the SE file
var_in   = getfilevarnames( diff )
nvar_in  = dimsizes(var_in)
print(var_in)

lat = diff->lat
lon = diff->lon
lev = diff->lev
time = diff->time

hyai = diff->hyai
hybi = diff->hyai
hyam = diff->hyam
hybm = diff->hybm
P0   = diff->P0

do nv=0,nvar_in-1

theVar = var_in(nv)
rank_in = dimsizes(getfilevardimsizes(diff,theVar))

if (rank_in.eq.3) then
print("Doing var: "+theVar)
VAR  = abs(diff ->$theVar$)
VARavg = new((/1,dimsizes(time)/),"double")

VARavg(0,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(VAR,1),1)

wks   = gsn_open_wks (out_type,"pdf/nhemi_ensError_"+theVar)                ; open workstation
res                  = True                     ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False
res@tiMainString     = theVar          ; add title
res@xyLineColors = (/"red","blue","green","orange","purple"/)
res@xyLineThicknesses = (/4.0,4.0,4.0,4.0,4.0/)
plot  = gsn_csm_xy (wks,time,VARavg,res)
lnid = gsn_add_polyline(wks,plot,(/30,30/),(/0.,9999./),False)

draw(plot)
frame(wks)

delete(res)
delete(VAR)
delete(VARavg)

end if
end do

end
