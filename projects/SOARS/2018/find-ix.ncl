;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
;========================================================

begin

TESTCIT=(/"MOBILE","MIAMI","HOUSTON","TAMPA","NEWORLEANS","NEWYORKCITY","BOSTON","CHARLESTON","JACKSONVILLE","HATTERAS","DC","SAVANNAH","CCHRISI","ATLANTA","TUSCALOOSA","THASSEE","CHARLOTTE"/)
TESTSTR=(/"KMOB","KMIA","KHOU","KTPA","KNEW","KNYC","KBOS","KCHS","KJAX","KHSE","KDCA","KSAV","KCRP","KATL","KTCL","KTLH","KCLT"/)
TESTLAT=(/ 30.6954, 25.7617, 29.7604, 27.9506, 29.9511, 40.7128, 42.3601, 32.7765, 30.3322, 35.2505, 38.9072, 32.0809, 27.8006, 33.7490, 33.2098, 30.4383, 35.2271/)
TESTLON=(/-88.0399,-80.1918,-95.3698,-82.4572,-90.0715,-74.0060,-71.0589,-79.9311,-81.6557,-75.5288,-77.0369,-81.0912,-97.3964,-84.3880,-87.5692,-84.2807,-80.8431/)

outputname="indices.csv"
system("rm "+outputname)
quote = inttochar(34)
delim = ","

filelist = systemfunc ("ls /glade/p/cesmdata/inputdata/atm/cam/topo/USGS-gtopo30_ne120np4_16xdel2-PFC-consistentSGH.nc") ; file paths

f1=addfile(filelist(0),"r")
lat=f1->lat
lon=f1->lon

do ii = 0,dimsizes(TESTLAT)-1
  gcdist = gc_latlon(TESTLAT(ii),TESTLON(ii),lat,lon,2,4)
  ix = minind(gcdist)
  print(ix+"")
  print(lat(ix)+"")
  print(lon(ix)+"")
  system("echo "+quote+ix+delim+TESTSTR(ii)+delim+TESTLAT(ii)+delim+TESTLON(ii)+delim+TESTCIT(ii)+     quote+" >> "+outputname)
end do

wks  = gsn_open_wks("png","station_map")              ; send graphics to PNG file

res                           = True              ; plot mods desired
res@mpOutlineOn               = True              ; turn on outline
res@mpFillOn                  = False             ; turn off map fill

res@mpMinLatF                 = 23                ; zoom in on map
res@mpMaxLatF                 = 43
res@mpMinLonF                 = -98.
res@mpMaxLonF                 = -66.

res@mpOutlineBoundarySets     = "geophysicalandusstates"; turn on states
res@mpDataBaseVersion         = "mediumres"             ; select database
res@mpDataSetName             = "Earth..2"

res@gsnDraw                   = False                  ; don't draw
res@gsnFrame                  = False                  ; don't advance frame

plot = gsn_csm_map_ce(wks,res)                         ; create map

gfx_labels = new(dimsizes(TESTSTR),graphic)
gfx_points = new(dimsizes(TESTSTR),graphic)

txres = True
txres@amJust = "TopLeft"
txres@txFontHeightF = 0.012             ; Set the font height
txres@txFontColor = "blue"

gsres               = True
gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
gsres@gsMarkerColor = "red"
gsres@gsMarkerThicknessF = 0.7

do ii = 0,dimsizes(TESTSTR)-1
  polylabel = TESTSTR(ii)
  polylon = TESTLON(ii)
  polylat = TESTLAT(ii)
  gfx_labels(ii) = gsn_add_text(wks,plot,polylabel,polylon+0.1,polylat-0.1,txres)
  gfx_points(ii) = gsn_add_polymarker(wks,plot,polylon,polylat,gsres)
end do


draw(plot)
frame(wks)

end


