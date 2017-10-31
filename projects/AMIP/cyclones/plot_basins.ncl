;========================================================
; Reads in a trajectory data file and calculates hurricane days
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "calc_area.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================
begin

;---------------User settings----------------------------

maskspacing = 2
tcMask = mask_tc(0,-999,-999,maskspacing,360)

; Lump all non EPAC ATL basins into one
tcMask = where(tcMask.gt.2.5, 3, tcMask)
; Get rid of all mask values that aren't a mask (<0.5)
tcMask = where(tcMask.lt.0.5, tcMask@_FillValue, tcMask)

;**************************************************
; create plot
;**************************************************

wks = gsn_open_wks("pdf","tc_mask_basins")

; White is background
; Black is map outline/labels
colors = (/"white","black","red","yellow","darkgreen"/)
gsn_define_colormap(wks, colors) 

res                      = True
res@gsnMaximize          = True
res@gsnFrame = False
res@gsnDraw = False
res@cnFillOn             = True              ; turn on color
res@cnLinesOn            = False             ; turn off contour lines
res@cnLineLabelsOn       = False

res@gsnAddCyclic = False
res@cnFillMode       = "RasterFill"
res@lbLabelBarOn = False

plot = gsn_csm_contour_map(wks,tcMask,res)

txres = True
amres=True
txres@txBackgroundFillColor = "White"
txres@txPerimOn = "True"
;txres@txFont                = "times-bold"
txres@txFontHeightF = 0.013

; Plot textboxes
; If you add :C: carriage return, it is left-justified by default
; NCL help forums say you need to add spaces by "guessing/checking"
; to center these text boxes

txid1 = gsn_create_text(wks, "Rest of Globe:C:     (GLOB)", txres)
amres@amParallelPosF   = 0.45    ; This is the left edge of the plot.
amres@amOrthogonalPosF = 0.0    ; This is the bottom edge of the plot.
amres@amJust           = "CenterRight"
annoid1 = gsn_add_annotation(plot, txid1, amres)

txid2 = gsn_create_text(wks, " North:C:Atlantic:C:(NATL)", txres)
amres@amParallelPosF   = -0.05    ; This is the left edge of the plot.
amres@amOrthogonalPosF = -0.13    ; This is the bottom edge of the plot.
amres@amJust           = "CenterRight"
annoid2 = gsn_add_annotation(plot, txid2, amres)

txid3 = gsn_create_text(wks, "  East:C: Pacific:C:(EPAC)", txres)
amres@amParallelPosF   = -0.295    ; This is the left edge of the plot.
amres@amOrthogonalPosF = -0.11    ; This is the bottom edge of the plot.
amres@amJust           = "CenterRight"
annoid3 = gsn_add_annotation(plot, txid3, amres)

txid3 = gsn_create_text(wks, "Rest of Globe:C:    (GLOB)", txres)
amres@amParallelPosF   = -0.43    ; This is the left edge of the plot.
amres@amOrthogonalPosF = 0.15    ; This is the bottom edge of the plot.
amres@amJust           = "CenterLeft"
annoid3 = gsn_add_annotation(plot, txid3, amres)

draw(plot)
frame(wks) 

end