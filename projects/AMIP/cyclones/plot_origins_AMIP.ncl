;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================
begin

; User settings!
basin = "atlantic" ; Valid values: atlantic, wpac, (anything else for global)
modelgrid = "vr" ; valid are vr, 1deg, ibtracs
factor = 0.85 ; correction for model winds
output_type = "pdf"
domask = 0 ; 0 = true, 1 = false
maskbasin = 1
maskspacing = 2
styr = 1980
enyr = 2002

cutwind = 17

colors = (/"blue","green3","yellow2","orange","darkorange3","red"/)

ms_to_kts = 1.94384449

print("Getting TC masks")
if (modelgrid .eq. "ibtracs") then
  tcMask = mask_tc(0,-999,-999,maskspacing,180)
else
  tcMask = mask_tc(0,-999,-999,maskspacing,360)
end if
print("Done getting TC masks")
print("------------------------------------------------")

if (modelgrid .eq. "ibtracs") then
  print("Plotting iBtracks data from: "+styr+" to "+enyr)
  print("Loading data, this may take awhile.")
  ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
  ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"
  
  ibfile = addfile(ibdir+ibfilename,"r")
  startlat = ibfile->lat_for_mapping(:,0)*.01
  startlon = ibfile->lon_for_mapping(:,0)*.01
  startlon = where(startlon.gt.180.0-maskspacing,180.0-maskspacing,startlon)
  year = toint(ibfile->season)
  wind_full = ibfile->source_wind(:,:,:)*.1/ms_to_kts
  wind_avg = dim_avg_n_Wrap(wind_full,2)
  onedwind = dim_max_n_Wrap(wind_avg,1)
  numstorms = dimsizes(year)
else
  traj_filename = "/glade/u/home/zarzycki/tcstats/ori_"+modelgrid+".txt"
  traj_ncols = numAsciiCol(traj_filename)
  ; Given the # of columns, we can use readAsciiTable to read this file.
  traj_data = readAsciiTable(traj_filename,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  print("'" + traj_filename + "' has " + traj_nrows + " rows and " + traj_ncols + \
          " columns of data.")
  stormid = traj_data(:,0)
  year = traj_data(:,1)
  month = traj_data(:,2)
  day = traj_data(:,3)
  hour = traj_data(:,4)
  startlat = traj_data(:,5)
  startlon = traj_data(:,6)
  onedwind = traj_data(:,7)*factor
  onedpres = traj_data(:,8)
  numstorms = dimsizes(year)
end if


print("Masking out basins")
if (domask .eq. 0)
  do i = 0,numstorms-1
        if (tcMask({startlat(i)},{startlon(i)}) .ne. maskbasin .or. year(i) .lt. styr .or. year(i) .gt. enyr)
          startlat(i) = startlat@_FillValue
          startlon(i) = startlon@_FillValue
          onedwind(i) = onedwind@_FillValue
        end if
  end do
end if



;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(output_type,"pdf/oris_"+modelgrid+"_"+basin)            ; open a ps file
map = new(1,graphic)                          ; create a plot array
  
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
  
dum = new(numstorms,graphic)
dum2 = new(numstorms,graphic)
plotted_storms = 0
  
do i = 0,numstorms-1

if (.not.ismissing(onedwind(i)))

  if (onedwind(i) .gt. cutwind) then
  
  polyres@gsMarkerSizeF = 0.05
  polyres@gsMarkerColor = "Black"
  dum2(i) = gsn_add_polymarker(wks,map,startlon(i),startlat(i),polyres)
    
    
  polyres@gsMarkerSizeF = 0.04          ; select size to avoid streaking
  if (onedwind(i) .lt. 17)
    polyres@gsMarkerColor = colors(0)
  else if (onedwind(i) .ge. 17 .and. onedwind(i) .lt. 33)
    polyres@gsMarkerColor = colors(1)
  else if (onedwind(i) .ge. 33 .and. onedwind(i) .lt. 43)
    polyres@gsMarkerColor = colors(2)
  else if (onedwind(i) .ge. 43 .and. onedwind(i) .lt. 49)
    polyres@gsMarkerColor = colors(3)
  else if (onedwind(i) .ge. 49 .and. onedwind(i) .lt. 58)
    polyres@gsMarkerColor = colors(4)
  else
    polyres@gsMarkerColor = colors(5)
  end if
  end if
  end if
  end if
  end if
  
  dum(i) = gsn_add_polymarker(wks,map,startlon(i),startlat(i),polyres)
  plotted_storms = plotted_storms + 1
  
  end if
  
end if

end do

print(plotted_storms)

; if we are doing a varres grid, let's push an outline of the atl30x4 grid
if (modelgrid .eq. "vr") then
  map = plot_outline_fcn(wks,map,"black",2.5)
end if

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

if (cutwind .eq. 0) then
lgres@lgItemCount        = 6
;lgres@lgLineDashSegLenF  = 0.8
lgres@lgItemTypes        = (/"Markers","Markers","Markers","Markers","Markers","Markers"/)
lgres@lgMarkerIndexes    = (/      16,      16,      16,      16,      16,      16/)
lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow",   "green",    "blue"    /) ; colors for legend lines
;lgres@lgDashIndexes      = (/      0,          0,          0,         0,               0,      0      /) ; dash indexes
legend_labels = (/"Category 4/5","Category 3","Category 2",\
               "Category 1","Tropical Storm","Tropical Depression"/)
else if (cutwind .eq. 17) then
  lgres@lgItemCount        = 5
  lgres@lgItemTypes        = (/legendType,legendType,legendType,legendType,legendType/)
  lgres@lgMarkerIndexes    = (/markerIndex,markerIndex,markerIndex,markerIndex,markerIndex/)
  lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
  lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow2",   "green3" /) ; colors for legend lines
  legend_labels = (/"Category 4/5","Category 3","Category 2",\
                 "Category 1","Tropical Storm"/)
else
end if
end if

legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
if (basin .eq. "atlantic")
  amres@amParallelPosF   = 0.42		    ; move legend to the right
  amres@amOrthogonalPosF = -.314             ; move the legend down
else
  amres@amParallelPosF   = -0.37		    ; move legend to the right
  amres@amOrthogonalPosF = .27             ; move the legend down
end if

annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot
  
print("Drawing plot")

resP = True
resP@amJust           = "TopLeft"
if (modelgrid .eq. "1deg") then
  resP@gsnPanelFigureStrings= (/"a."/)
else if (modelgrid .eq. "vr") then
  resP@gsnPanelFigureStrings= (/"b."/)
else
  resP@gsnPanelFigureStrings= (/"c."/)
end if
end if
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot


end
