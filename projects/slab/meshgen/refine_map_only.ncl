
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "plot_outline_fcn.ncl"   
; ================================================;
begin

wks  = gsn_open_wks("pdf","nhemi_30_x4_outline")       ; open a ps file
gsn_define_colormap(wks,"wh-bl-gr-ye-re") ; choose a colormap

res                        = True         ; mods desdired
res@gsnDraw=False
res@gsnFrame=False
res@mpLandFillColor        = "tan"
res@mpOceanFillColor       = "LightBlue"
res@mpInlandWaterFillColor = "Blue"

;res@mpMinLonF              = 10
;res@mpMaxLonF              = -10
res@mpCenterLonF           = 210     ; This is necessary to get the correct map

plot = gsn_csm_map_ce(wks,res)        ; draw global map
plot = plot_outline_fcn(wks,plot,"black",5.0)

txres               = True                            
txres@txFontHeightF = 0.018             ; Set the font height
txres@txBackgroundFillColor="White"
txres@txPerimOn=True
txres@txPerimColor="Black"

text1 = gsn_add_text(wks,plot,"0.25~S~o~N~",150,25,txres)
text1 = gsn_add_text(wks,plot,"0.5~S~o~N~",125,60,txres)
text1 = gsn_add_text(wks,plot,"1.0~S~o~N~",210,-40,txres)

draw(plot)
frame(wks)

end
