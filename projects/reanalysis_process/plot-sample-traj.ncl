;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "../radial_plots/radialAvg.ncl"
load "~/ncl/functions/psminsolver.ncl"
;========================================================
begin

sample_lat=(/19.,19.,19.,20.,20.,21.,23.,26.,30./)
sample_lon=(/278.,276.,274.,272.,270.,268.,267.,267.,268./)

wks  = gsn_open_wks("pdf","traj-sample-map")    ; send graphics to PNG file

res=True
res@gsnDraw=False
res@gsnFrame=False

res@mpMinLatF=17.
res@mpMaxLatF=32.

res@mpMinLonF=262.
res@mpMaxLonF=280.

plot = gsn_csm_map_ce(wks,res)        ; draw global map

dum_out=new(20,"graphic")
dum_in=new(20,"graphic")
pmres=True
pmres@gsMarkerIndex = 16
do i = 0,dimsizes(sample_lat)-1
  pmres@gsMarkerSizeF = .02
  pmres@gsMarkerColor = "Black"
  dum_out(i) = gsn_add_polymarker(wks, plot, sample_lon(i), sample_lat(i), pmres)
  pmres@gsMarkerSizeF = .014
  pmres@gsMarkerColor = "Red"
  if (i.eq.4) then
    pmres@gsMarkerColor = "White"
  end if
  dum_in(i)  = gsn_add_polymarker(wks, plot, sample_lon(i), sample_lat(i), pmres)
end do

draw(plot)
frame(wks)

end

