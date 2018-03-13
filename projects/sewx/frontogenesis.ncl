;========================================================
;
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/home/zarzycki/ncl-zarzycki/functions/fronto.ncl"
;========================================================


begin

f = addfile("/home/zarzycki/data/gfs.t00z.pgrb2.0p25.f024.grb2","r")

lev=70000.
U = f->UGRD_P0_L100_GLL0({lev},::-1,:)
V = f->VGRD_P0_L100_GLL0({lev},::-1,:)
T = f->TMP_P0_L100_GLL0({lev},::-1,:)
SLP = f->PRMSL_P0_L101_GLL0(::-1,:)

SLP = SLP/100.

THETA = T
THETA = T * (100000./lev)^(2/7)

F = fronto(THETA,U,V,U&lat_0,U&lon_0,8,0)

;************************************************
wks = gsn_open_wks("png","proj")          ; send graphics to PNG file

res                   = True

;res@mpMinLatF             = 35
;res@mpMaxLatF             = 50
;res@mpMinLonF             = 273
;res@mpMaxLonF             = 298

res@mpMinLatF             = 20
res@mpMaxLatF             = 55
res@mpMinLonF             = 230
res@mpMaxLonF             = 350

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 1.			; set the minimum contour level
res@cnMaxLevelValF  = 12.			; set the maximum contour level
res@cnLevelSpacingF = 1.			; set the interval between contours

;res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
;res@cnMinLevelValF  = 900.			; set the minimum contour level
;res@cnMaxLevelValF  = 1040.			; set the maximum contour level
;res@cnLevelSpacingF = 4.			; set the interval between contours

contour = gsn_csm_contour_map(wks,F,res)  ; create the plot

end