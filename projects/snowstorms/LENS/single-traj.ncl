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

output_type="x11"

; JRA
;stormID=14
;year=2010
;trajfile="/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/tempest.JRA."+year+"."+year
;stormfile="/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.JRA."+year+"."+year+".5e-9_12.nc.tempest.nc"

;/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS.1990.035.5e-9_12.nc.tempest.nc,XXX,00233,1995020700,090, 32.61,5
;/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS.1990.035.5e-9_12.nc.tempest.nc,XXX,00346,1997120612,126, 48.44,5
;/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS.1990.001.5e-9_12.nc.tempest.nc	XXX	89	1991121806	90	16.8	4

stormID=89
ensmem="001"
year=1990
trajfile="/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/tempest.LENS."+year+"."+ensmem
stormfile="/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS."+year+"."+ensmem+".5e-9_12.nc.tempest.nc"

ncols = 9                     ; assign number of columns

delim = ","

ncases = dimsizes(trajfile)
print("Doing "+ncases+"  number of cases")
  
maxLines = -1
traj_data = getTrajectories(trajfile,ncols,maxLines)

ndims = dimsizes(traj_data)
nstorms = ndims(0)
ncols   = ndims(1)
ntimes  = ndims(2)

; need to be modified to 2,3,4 if using latlon data
lon = traj_data(stormID,2,:)
lat = traj_data(stormID,3,:)
pres = traj_data(stormID,4,:)/100.

f = addfile(stormfile,"r")

SNOW=f->CUM_SNOWFALL(stormID,:,:)
SNOW=SNOW*12
SNOW=where(SNOW.lt.1.0,SNOW@_FillValue,SNOW)

; Smoother?

nave = 3
opt = 0
lon = runave_Wrap(lon,nave,opt)
lat = runave_Wrap(lat,nave,opt)

;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(output_type,"latlon_traj_plot")
gsn_define_colormap(wks,"MPL_BuPu")   ; choose colormap
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
 
res@mpMinLatF             = 30
res@mpMaxLatF             = 60
res@mpMinLonF             = 260
res@mpMaxLonF             = 300
;map = gsn_csm_map_ce(wks,res)

res@gsnAddCyclic = False

res@mpProjection = "Orthographic"
res@mpLimitMode           = "LatLon"
res@mpCenterLatF      =  45.
res@mpCenterLonF      =  280.

res@gsnSpreadColors     = True         ; Use full colormap, but start
res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.
res@cnFillMode          = "RasterFill"

map = gsn_csm_contour_map(wks,SNOW,res)

;gsn_define_colormap(wks,"rainbow+white+gray")
polyres               = True          ; poly marker mods desired 
polyres@gsMarkerIndex = 1            ; choose circle as polymarker
lineres = True

dum = new((/ntimes/),graphic)

do j = 0,ntimes-1

  thisPres=pres(j)

  ;linethicknesses = (/1.5,1.5,1.5,1.5,2.0,2.5/)
  linethicknesses = (/1.0,2.0,3.0,3.0,3.0,3.0/)
  linethicknesses = linethicknesses * 3.0

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
      dum(j) = gsn_add_polyline(wks,map,(/lon(j),lon(j-1)/),(/lat(j),lat(j-1)/),lineres)
    end if
  
  end if

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





end
