load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;theVar = "Z500"
out_type="pdf"
;1001 and 1004
diff  =  addfile("/glade/u/home/zarzycki/scratch/slab_fv_01/run/diff.nc","r")
;1001 and 1003
diff2 =  addfile("/glade/u/home/zarzycki/scratch/slab_fv_01/run/diff2.nc","r")
;1001 and 1005
diff3 =  addfile("/glade/u/home/zarzycki/scratch/slab_fv_01/run/diff3.nc","r")
;1004 and 1005
diff4 =  addfile("/glade/u/home/zarzycki/scratch/slab_fv_01/run/diff4.nc","r")
;1003 and 1005
diff5 =  addfile("/glade/u/home/zarzycki/scratch/slab_fv_01/run/diff5.nc","r")

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
VAR2 = abs(diff2->$theVar$)
VAR3 = abs(diff3->$theVar$)
VAR4 = abs(diff4->$theVar$)
VAR5 = abs(diff5->$theVar$)
VARavg = new((/5,dimsizes(time)/),"double")

VARavg(0,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(VAR,1),1)
VARavg(1,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(VAR2,1),1)
VARavg(2,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(VAR3,1),1)
VARavg(3,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(VAR4,1),1)
VARavg(4,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(VAR5,1),1)

wks   = gsn_open_wks (out_type,"pdf/ensError_"+theVar)                ; open workstation
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
delete(VAR2)
delete(VAR3)
delete(VAR4)
delete(VAR5)
delete(VARavg)

end if
end do

end
