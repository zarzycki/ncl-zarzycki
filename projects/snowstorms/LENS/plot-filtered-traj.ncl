;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
;========================================================
begin

output_type="png"

RSIthresh=3

; use running smoother over trajectory?
do_smooth_traj=True

trajfile=(/"/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/LENS-8/tempest.LENS.1990.ALL"/)
RSIfile = (/"/glade/scratch/zarzycki/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv.SNOW.tempest.csv"/)
ncols = 9                     ; assign number of columns

delim = ","

ncases = dimsizes(trajfile)
print("Doing "+ncases+"  number of cases")

do z = 0,ncases-1
  
  maxLines = -1
  traj_data = getTrajectories(trajfile(z),ncols,maxLines)

  lines = asciiread(RSIfile(z),-1,"string")

  ;member   = str_get_field(lines,1,delim)
  ;stormID  = tointeger(str_get_field(lines,2,delim))
  ;RSIval   = tofloat(str_get_field(lines,3,delim))
  RSIcat   = tointeger(str_get_field(lines,7,delim))

  ndims = dimsizes(traj_data)
  nstorms = ndims(0)
  ncols   = ndims(1)
  ntimes  = ndims(2)

  do i = 0,nstorms-1
    if (RSIcat(i) .lt. RSIthresh)
      ;print("filling... "+RSIcat(i))
      traj_data(i,:,:) = traj_data@_FillValue
    end if
  end do

  ; need to be modified to 2,3,4 if using latlon data
  lon = traj_data(:,2,:)
  lat = traj_data(:,3,:)
  pres = traj_data(:,4,:)/100.

  lon = where(lon .gt. 180.,lon-360.,lon)
  
  ; use running smoother over trajectories
  if (do_smooth_traj) then
    do kk = 0,nstorms-1
      nave = 3
      opt = 1
      lon(kk,:) = runave_Wrap(lon(kk,:),nave,opt)
      lat(kk,:) = runave_Wrap(lat(kk,:),nave,opt)
    end do
  end if

;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(output_type,"latlon_traj_plot")
map = new(1,graphic)
  
res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
res@mpOutlineBoundarySets = "National"
 
res@mpMinLatF             = 20
res@mpMaxLatF             = 60
res@mpMinLonF             = 240
res@mpMaxLonF             = 305
;map = gsn_csm_map_ce(wks,res)

res@mpProjection = "Orthographic"
res@mpLimitMode           = "LatLon"
res@mpCenterLatF      =  45.
res@mpCenterLonF      =  280.
map = gsn_csm_map(wks,res)


 

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True





dum = new((/nstorms,ntimes/),graphic)

do i = 0,nstorms-1
do j = 0,ntimes-1

thisPres=pres(i,j)

;linethicknesses = (/1.5,1.5,1.5,1.5,2.0,2.5/)
;linethicknesses = (/1.0,2.0,3.0,3.0,3.0,3.0/)
linethicknesses = (/3.0,4.0,5.0,5.0,5.0,5.0/)


if (.not.ismissing(thisPres))

  if (thisPres .gt. 1010)
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (thisPres .ge. 1000 .and. thisPres .lt. 1010)
    polyres@gsMarkerColor = (/"green3"/)
    lineres@gsLineColor = (/"green3"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (thisPres .ge. 990 .and. thisPres .lt. 1000)
    polyres@gsMarkerColor = (/"yellow2"/)
    lineres@gsLineColor = (/"yellow2"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (thisPres .ge. 975 .and. thisPres .lt. 990)
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (thisPres .ge. 960 .and. thisPres .lt. 975)
    polyres@gsMarkerColor = (/"darkorange3"/)
    lineres@gsLineColor = (/"darkorange3"/)
    lineres@gsLineThicknessF  = linethicknesses(4)
  else
    polyres@gsMarkerColor = (/"red"/) 
    lineres@gsLineColor = (/"red"/)
    lineres@gsLineThicknessF  = linethicknesses(5)
  end if
  end if
  end if
  end if
  end if
  
 txres               = True                            
 txres@txFontHeightF = 0.01             ; Set the font height
  
  if (j .ne. 0) then
    dum(i,j) = gsn_add_polyline(wks,map,(/lon(i,j),lon(i,j-1)/),(/lat(i,j),lat(i,j-1)/),lineres)
  end if
  
end if

end do
end do


;******************
; Plot a legend   *
;******************

lgres                    = True

lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.17       ; was 0.08        ; width of legend (NDC)
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

;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.09
lgres@lgLabelFontAspectF      = 1.4
lgres@lgLabelConstantSpacingF = 0.0

legendType = "Markers"
markerSize = .01
markerIndex = 16

lgres@lgItemCount        = 6
;lgres@lgLineDashSegLenF  = 0.8
lgres@lgItemTypes        = (/"Markers","Markers","Markers","Markers","Markers","Markers"/)
lgres@lgMarkerIndexes    = (/      16,      16,      16,      16,      16,      16/)
lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow",   "green",    "blue"    /) ; colors for legend lines
;lgres@lgDashIndexes      = (/      0,          0,          0,         0,               0,      0      /) ; dash indexes
legend_labels = (/"<950mb","950-965mb","965-980mb",\
               "980-995mb","995-1005mb",">1005mb"/)

legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
amres@amParallelPosF   = -0.30		    ; move legend to the right .37 formerly
amres@amOrthogonalPosF = .27             ; move the legend down

annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot
  
print("Drawing plot")

resP = True
resP@amJust           = "TopLeft"

;  resP@gsnPanelFigureStrings= (/"a."/)

resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot



delete(lat)
delete(lon)
delete(pres)
delete(traj_data)
delete(lines)
delete(RSIcat)
delete(nstorms)

end do



end
