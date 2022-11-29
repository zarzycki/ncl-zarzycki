begin

fili = systemfunc("ls /glade/u/home/zarzycki/scratch/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900/atm/hist/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.cam.h3.1986*_regrid.nc")
fall = addfiles (fili, "r")

   
var1="PRECT"
var2=var1+"_MASKI"

v1=fall[:]->$var1$
v2=fall[:]->$var2$

v1_avg = dim_avg_n_Wrap(v1,0)
v2_avg = dim_avg_n_Wrap(v2,0)

MinLatF             = 5.
MaxLatF             = 35.
MinLonF             = -90.
MaxLonF             = -15.

rad = 4.0*atan(1.0)/180.0
v1_amean = wgt_areaave_Wrap(v1_avg, cos(rad*v1_avg&lat), 1.0, 0)
v2_amean = wgt_areaave_Wrap(v2_avg, cos(rad*v2_avg&lat), 1.0, 0)

print("full avg: "+v1_amean*8.64e+7)
print("mask avg: "+v2_amean*8.64e+7)

;************************************************
; create plots
;************************************************
wks = gsn_open_wks("x11","panel")              ; open a png file
plot = new(2,graphic)                          ; create a plot array

res                     = True
res@gsnDraw             = False
res@gsnFrame            = False
res@mpFillOn            = False            ; no need   
 
res@cnFillOn            = True             ; color fill plot
res@cnFillPalette       = "WhiteBlueGreenYellowRed"
res@cnLinesOn           = False
res@cnLineLabelsOn      = False
res@cnInfoLabelOn       = False
res@lbLabelBarOn        = False            ; turn off individual label bars

res@mpMinLatF             = MinLatF
res@mpMaxLatF             = MaxLatF
res@mpMinLonF             = MinLonF
res@mpMaxLonF             = MaxLonF
res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2
res@gsnAddCyclic = False

res@gsnLeftString=""
res@gsnRightString=""

plot(0) = gsn_csm_contour_map(wks,v1_avg,res) 
plot(1) = gsn_csm_contour_map(wks,v2_avg,res) 

gsn_panel(wks,plot,(/2,1/),False)             ; now draw as one plot
end