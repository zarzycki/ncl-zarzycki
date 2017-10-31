;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
;========================================================
begin

; User settings!
basin = "global" ; Valid values: atlantic, wpac, (anything else for global)
factor = 0.81 ; correction for model winds
cutwind = 0 ; 0 for all, 17 for TS+, 33 for cat1+, 49 for cat3+

traj_cleanfile = "/glade/u/home/zarzycki/scratch/camsetracking/uniq_lines2.txt"

traj_ncols = numAsciiCol(traj_cleanfile)
; Given the # of columns, we can use readAsciiTable to read this file.
traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows

print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
      " columns of data.")

;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks("x11","pdf/trajs_AMIP")            ; open a ps file
  
res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = 239
res@mpOceanFillColor = 10
res@mpGreatCircleLinesOn = True
 
if (basin .eq. "atlantic")  
  res@mpMinLatF             = 5
  res@mpMaxLatF             = 45
  res@mpMinLonF             = 260
  res@mpMaxLonF             = 355
end if
if (basin .eq. "wpac")  
  res@mpMinLatF             = 5
  res@mpMaxLatF             = 45
  res@mpMinLonF             = 115
  res@mpMaxLonF             = 180
end if
  
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new(traj_nrows,graphic)

do i = 0,traj_nrows-1

lineres@gsLineThicknessF = 8.0

if (.not.ismissing(traj_data(i,2)))

;  polyres@gsMarkerSizeF = 2.0           ; select size to avoid streaking
  if (traj_data(i,2) .lt. 17*(1/factor))
  polyres@gsMarkerColor = (/"blue"/)   ; choose color
  lineres@gsLineColor = (/"blue"/)
  lineres@gsLineThicknessF = 1.8
  else if (traj_data(i,2) .ge. 17*(1/factor) .and. traj_data(i,2) .lt. 33*(1/factor))
  polyres@gsMarkerColor = (/"green"/)   ; choose color
    lineres@gsLineColor = (/"green"/)
    lineres@gsLineThicknessF = 1.9
  else if (traj_data(i,2) .ge. 33*(1/factor) .and. traj_data(i,2) .lt. 43*(1/factor))
  polyres@gsMarkerColor = (/"yellow"/)   ; choose color
    lineres@gsLineColor = (/"yellow"/)
      lineres@gsLineThicknessF = 2.0
  else if (traj_data(i,2) .ge. 43*(1/factor) .and. traj_data(i,2) .lt. 49*(1/factor))
  polyres@gsMarkerColor = (/"orange"/)   ; choose color
    lineres@gsLineColor = (/"orange"/)
      lineres@gsLineThicknessF = 2.25
  else if (traj_data(i,2) .ge. 49*(1/factor) .and. traj_data(i,2) .lt. 58*(1/factor))
  polyres@gsMarkerColor = (/"darkorange3"/)   ; choose color
    lineres@gsLineColor = (/"darkorange3"/)
      lineres@gsLineThicknessF = 2.5
  else
  polyres@gsMarkerColor = (/"red"/)   ; choose color
    lineres@gsLineColor = (/"red"/)
      lineres@gsLineThicknessF = 2.75
  end if
  end if
  end if
  end if
  end if
  
 txres               = True                            
 txres@txFontHeightF = 0.01             ; Set the font height
  
  if (i .ne. 0) then
  if (gc_latlon(traj_data(i,1),traj_data(i,0),traj_data(i-1,1),traj_data(i-1,0),2,4) .lt. 400) then
    if(traj_data(i,2) .ge. cutwind*(1/factor)) then
      ;dum(i) = gsn_add_polyline(wks,map,(/traj_data(i,0),traj_data(i-1,0)/),(/traj_data(i,1),traj_data(i-1,1)/),lineres)
      ;if (mod(i,4) .eq. 0) then
      ;  str = sprintf("%4.0f",traj_data(i,4))+sprintf("%2.0f",traj_data(i,5))+sprintf("%2.0f",traj_data(i,6))
      ;  gsn_text(wks,map,str,traj_data(i,0),traj_data(i,1),txres)
      ;end if
    end if
  end if
  end if
  
  dum(i) = gsn_add_polymarker(wks,map,traj_data(i,0),traj_data(i,1),polyres)
  
end if

end do

;map = plot_outline_fcn(wks,map,"white",2.0)

;******************
; Plot a legend   *
;******************

lgres                    = True

lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.13       ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.13       ; was 0.08        ; height of legend (NDC)
; lgres@lgBottomMarginF    = 0.17     ; was 0.25

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

;lgres@lgOrientation = "Horizontal"

; lgres@lgBoxMajorExtentF  = 0.4
lgres@lgBoxMinorExtentF  = 0.2	; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

; lgres@lgBoxBackground    = "PaleTurquoise3"

lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
lgres@lgMonoMarkerIndex     = False
lgres@lgMonoLineThickness   = False
lgres@lgMonoMarkerThickness = False
lgres@lgMonoMarkerSize      = False

lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.07
lgres@lgLabelFontAspectF      = 1.5
lgres@lgLabelConstantSpacingF = 0.0

lgres@lgItemCount        = 6
lgres@lgLineDashSegLenF  = 0.8
lgres@lgItemTypes        = (/"Markers","Markers","Markers","Markers","Markers","Markers"/)
lgres@lgMarkerIndexes    = (/      16,      16,      16,      16,      16,      16/)
lgres@lgMarkerThicknesses  = (/    3.0,    3.0,    3.0,    3.0,    3.0,    3.0/)
;   lgres@lgMarkerColors     = (/  "White",  "Black", "Black"/) 
;   lgres@lgMarkerSizes      = (/   0.0001,   0.004,    0.004/)
lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow",   "green",    "blue"    /) ; colors for legend lines
lgres@lgDashIndexes      = (/      0,          0,          0,         0,               0,      0      /) ; dash indexes

legend_labels = (/"Category 4/5","Category 3","Category 2",\
               "Category 1","Tropical Storm","Tropical Depression"/)
legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
if (basin .eq. "atlantic")
amres@amParallelPosF   = 0.43		    ; move legend to the right
amres@amOrthogonalPosF = -.3             ; move the legend down
else
amres@amParallelPosF   = -0.37		    ; move legend to the right
amres@amOrthogonalPosF = .27             ; move the legend down
end if

annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot
  
print("Drawing plot")
draw(map)
frame(wks)

end
