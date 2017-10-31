;----------------------------------------------------------------------
; This example uses ESMF regridding software to regrid from an
; unstructured SE grid to a CAM finite volume grid (96 x 144).
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

theVar="BURDENBC"

                          
files1 = systemfunc ("ls /glade/u/home/zarzycki/scratch/BC-tianye/BC_ne16_CAM5_climo/atm/hist/BC_ne16_CAM5_climo.cam.h0.0004-*.nc_regrid.nc")
f1 = addfiles (files1, "r")
ListSetType (f1, "cat")

files2 = systemfunc ("ls /glade/u/home/zarzycki/scratch/BC-tianye/BC_ne30_CAM5_climo/atm/hist/BC_ne30_CAM5_climo.cam.h0.0004-*.nc_regrid.nc")
f2 = addfiles (files2, "r")
ListSetType (f2, "cat")

files3 = systemfunc ("ls /glade/u/home/zarzycki/scratch/BC-tianye/BC_north30x2_CAM5_climo/atm/hist/BC_north30x2_CAM5_climo.cam.h0.0004-*.nc_regrid.nc")
f3 = addfiles (files3, "r")
ListSetType (f3, "cat")

;f1=addfile("/glade/u/home/zarzycki/scratch/BC-tianye/BC_ne16_CAM5_climo/atm/hist/BC_ne16_CAM5_climo.cam.h0.0005-05.nc_regrid.nc","r")
;f2=addfile("/glade/u/home/zarzycki/scratch/BC-tianye/BC_ne30_CAM5_climo/atm/hist/BC_ne30_CAM5_climo.cam.h0.0005-05.nc_regrid.nc","r")

var1=f1[:]->$theVar$
var2=f2[:]->$theVar$
var3=f3[:]->$theVar$
gw1=f1[0]->gw
gw2=f2[0]->gw
gw3=f3[0]->gw

avgarr = new((/3,12/),"float")
;avgarr(0,:)=wgt_areaave(dim_sum_n_Wrap(var1,1),gw1,1.,0)
;avgarr(1,:)=wgt_areaave(dim_sum_n_Wrap(var2,1),gw2,1.,0)
;avgarr(2,:)=wgt_areaave(dim_sum_n_Wrap(var3,1),gw3,1.,0)
avgarr(0,:)=wgt_areaave(var1,gw1,1.,0)
avgarr(1,:)=wgt_areaave(var2,gw2,1.,0)
avgarr(2,:)=wgt_areaave(var3,gw3,1.,0)

r_earth=6371000
pi=3.14159
area_earth = 4*pi*r_earth^2
print(area_earth)

avgarr=avgarr*area_earth
avgarr=avgarr/1000000000   ; kg to Tg
;Reddy 2007 -- 0.07 Tg
;Park et al 2005 -- 0.11 +/- 0.03 Tg
;Q. Wang (HIPPO) et al 2014 -- 0.077 Tg
;avgarr=avgarr*100          ; Tg to Tg*100 to compare to Reddy et al 2007

print(dim_avg_n_Wrap(avgarr,1))

wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file
res                  = True                     ; plot mods desired
res@tiMainString  = "BC"
res@tiXAxisString = "Month"       ; Put label on X axis
res@tiYAxisString = "Burden (Tg)"       ; Put label on X axis
plot  = gsn_csm_xy (wks,ispan(1,12,1),avgarr,res) ; create plot

end