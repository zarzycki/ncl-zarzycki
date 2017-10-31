load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin 
   
u10 = fspan(0.0,80.0,160)               
nprof=2      
logwgt=new((/nprof,dimsizes(u10)/),"float")

uref=30.0
alpha=0.5

logwgt(0,:) = 1.0/(1.0 + exp(-alpha*(u10-uref)))

alpha=0.2
k_ref=0.9

logwgt(1,:) = (u10*k_ref/uref)*1.0/(1.0 + exp(-alpha*(u10-uref)))

;************************************************
; plotting parameters
;************************************************
wks   = gsn_open_wks ("pdf","slab_wgt_fcns")                ; open workstation

res                  = True                     ; plot mods desired
res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses = (/10.0,10.0/)               ; make 2nd lines thicker
res@xyLineColors      = (/"blue","red"/)          ; change line color
res@xyDashPatterns = (/0,0/)  

;res@tiMainString     = "Basic XY plot"          ; add title
res@tiXAxisString     = "u~B~10~N~ (m s~S~-1~N~)"
res@tiYAxisString     = "X~B~cool~N~"

res@lgPerimFill            = "SolidFill"      ; Fill legend box w/white
res@lgPerimFillColor       = "white"          ; so it masks XY curves
res@xyExplicitLegendLabels = (/"SLAB1","SLAB2"/)
res@lgItemOrder  = (/ 1,0 /)   ; Reorder the legends
res@pmLegendOrthogonalPosF = -0.45            ; Move legend inside plot
res@pmLegendParallelPosF   =  0.8             ; Move legend to right
res@pmLegendWidthF         = 0.15             ; Change width and height
res@pmLegendHeightF        = 0.12
res@pmLegendDisplayMode    = "Always"    ; Turn legend back on
res@lgLabelFontHeightF = 0.023

plot  = gsn_csm_xy (wks,u10,logwgt,res) ; create plot

plres = True
plres@gsLineDashPattern  = 2
plres@tfPolyDrawOrder = "PreDraw"
dum = gsn_add_polyline(wks, plot, (/0.0,80.0/), (/1.0,1.0/), plres)

vrdum=new(10,"graphic")
text=new(10,"graphic")
vrplres = True
vrplres@tfPolyDrawOrder = "PreDraw"
vrplres@gsLineDashPattern  = 1
;TD
vrdum(0) = gsn_add_polyline(wks, plot, (/17.0,17.0/), (/0.0,10.0/), vrplres)
;TS
vrdum(1) = gsn_add_polyline(wks, plot, (/32.0,32.0/), (/0.0,10.0/), vrplres)
;C1
vrdum(2) = gsn_add_polyline(wks, plot, (/42.0,42.0/), (/0.0,10.0/), vrplres)
;C2
vrdum(3) = gsn_add_polyline(wks, plot, (/49.0,49.0/), (/0.0,10.0/), vrplres)
;C3
vrdum(4) = gsn_add_polyline(wks, plot, (/58.0,58.0/), (/0.0,10.0/), vrplres)
;C4
vrdum(5) = gsn_add_polyline(wks, plot, (/70.0,70.0/), (/0.0,10.0/), vrplres)

 txres               = True   
 txres@tfPolyDrawOrder = "PreDraw"                         
 txres@txFontHeightF = 0.023             ; Set the font height
 txVertHeight=1.5
 text(0) = gsn_add_text(wks,plot,"TD",8.5,txVertHeight,txres)
 text(1) = gsn_add_text(wks,plot,"TS",24.5,txVertHeight,txres)
 text(2) = gsn_add_text(wks,plot,"C1",37.0,txVertHeight,txres)
 text(3) = gsn_add_text(wks,plot,"C2",45.5,txVertHeight,txres)
 text(4) = gsn_add_text(wks,plot,"C3",53.5,txVertHeight,txres)
 text(5) = gsn_add_text(wks,plot,"C4",64.0,txVertHeight,txres)
 text(6) = gsn_add_text(wks,plot,"C5",75.0,txVertHeight,txres)



draw(plot)
frame(wks)

end
