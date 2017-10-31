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

; for JAMES paper
;basin = "tropics" ; Valid values: atlantic, wpac, tropics, (anything else for global)
;modelgrid = "1deg" ; valid are vr, 1deg, ibtracs
;factor = 0.85 ; correction for model winds
;cutwind = 17 ; 0 for all, 17 for TS+, 33 for cat1+, 49 for cat3+
;output_type = "pdf"

; User settings!
basin = "atlantic"      ;Valid values: atlantic, wpac, tropics, (anything else for global)
modelgrid = "1deg" ; valid are vr, 1deg, ibtracs
factor = 0.85 ; correction for model winds
cutwind = 17 ; 0 for all, 17 for TS+, 33 for cat1+, 49 for cat3+
output_type = "pdf"

;Set this to true to quickly plot CAM 
notProduction=True
if (notProduction) then
  ; these are only used if notProduction=True
  notTrajDir="/glade/u/home/zarzycki/tcstats/FinalJAMESPaper/"
  notTrajFile="traj_1deg"
  modelgrid="1deg" ; 1deg or vr (vr overlays grid)
end if

ibstyr=1980
ibenyr=2002

if (cutwind .eq. 0) then
  ;colors = (/"blue","green","yellow","orange","darkorange3","red"/)
else if (cutwind .eq. 17) then
  ;colors = (/"blue","lightseagreen","green","yellow","orange","red"/)
else
end if
end if

ms_to_kts = 1.94384449

if (modelgrid .eq. "ibtracs") then
  print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
  print("Loading data, this may take awhile.")
  ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
  ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"
  
  ibfile = addfile(ibdir+ibfilename,"r")
  iblat = ibfile->lat_for_mapping*.01
  iblon = ibfile->lon_for_mapping*.01
  ibyear = toint(ibfile->season)
  ibtype = toint(ibfile->nature_for_mapping)
  ibwind = ibfile->source_wind(:,:,:)*.1/ms_to_kts
  
  ; Average over all centers -- for plotting, this is ok even if there
  ; are small discrepancies
  ibwind_ = dim_avg_n_Wrap(ibwind,2)

  onedwind = ndtooned(ibwind_)
  onedlat = ndtooned(iblat)
  onedlon = ndtooned(iblon)
  onedtype = ndtooned(ibtype)
  onedyear = ndtooned(conform_dims(dimsizes(iblat),ibyear,0))
  
  traj_nrows = dimsizes(onedwind)
  
  onedwind = where(onedwind.ge.cutwind,onedwind,onedwind@_FillValue)
  onedlat = where(onedwind.ge.cutwind,onedlat,onedlat@_FillValue)
  onedlon = where(onedwind.ge.cutwind,onedlon,onedlon@_FillValue)
  
  onedwind = where(onedtype.eq.0,onedwind,onedwind@_FillValue)
  onedlat = where(onedtype.eq.0,onedlat,onedlat@_FillValue)
  onedlon = where(onedtype.eq.0,onedlon,onedlon@_FillValue)
  
  onedwind = where(onedyear.lt.ibstyr,onedwind@_FillValue,onedwind)
  onedlat = where(onedyear.lt.ibstyr,onedlat@_FillValue,onedlat)
  onedlon = where(onedyear.lt.ibstyr,onedlon@_FillValue,onedlon)
  
  onedwind = where(onedyear.gt.ibenyr,onedwind@_FillValue,onedwind)
  onedlat = where(onedyear.gt.ibenyr,onedlat@_FillValue,onedlat)
  onedlon = where(onedyear.gt.ibenyr,onedlon@_FillValue,onedlon)
 
else
  print("Plotting CAM data")
  traj_dir = "/glade/u/home/zarzycki/tcstats/"
  if (modelgrid .eq. "vr") then
    traj_filename = "traj_vr"
  else if (modelgrid .eq. "1deg") then
    traj_filename = "traj_1deg"
  else
    print("No model grid")
    exit
  end if
  end if

  if (notProduction) then
    print("modifying traj path/file")
    traj_dir=notTrajDir
    traj_filename=notTrajFile
  end if
  
  traj_cleanfile = "traj_filt_clean.TMP"
  
  print("Removing text headers from trajectories")
  system("grep -v '^start' "+ traj_dir+traj_filename +" > "+traj_cleanfile+"")
  
  traj_ncols = numAsciiCol(traj_cleanfile)
  ; Given the # of columns, we can use readAsciiTable to read this file.
  traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  
  print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
        " columns of data.")
  
  print("Removing temporary file:"+traj_cleanfile)
  system("rm -rf "+traj_cleanfile)
        
  ;do i = 0,traj_nrows-1
  ;  if (traj_data(i,4) .ge. 1985)
  ;    traj_data(i,2) = traj_data@_FillValue
  ;  end if
  ;end do
  
  onedwind = traj_data(:,2)*factor
  onedlon = traj_data(:,0)
  onedlat = traj_data(:,1)
  
end if



;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(output_type,"pdf/trajs_"+modelgrid+"_"+basin)
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
if (basin .eq. "tropics")
  res@mpMinLatF             = -65
  res@mpMaxLatF             = 65
  res@mpCenterLonF = 200.
end if
 
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new(traj_nrows,graphic)

do i = 0,traj_nrows-1

;lineres@gsLineThicknessF = 8.0
; We need to use thinner lines for the global map
if (basin .eq. "global") then
  linethicknesses = (/0.2,0.3,1.3,1.9,2.3,2.7/)
else if (basin .eq. "tropics") then
  linethicknesses = (/0.1,0.7,1.6,2.0,2.6,3.2/)
else
  linethicknesses = (/1.8,1.9,2.0,2.25,2.5,2.75/)
end if
end if

if (.not.ismissing(onedwind(i)))

;  polyres@gsMarkerSizeF = 2.0           ; select size to avoid streaking
  if (onedwind(i) .lt. 17)
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (onedwind(i) .ge. 17 .and. onedwind(i) .lt. 33)
    polyres@gsMarkerColor = (/"green3"/)
    lineres@gsLineColor = (/"green3"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (onedwind(i) .ge. 33 .and. onedwind(i) .lt. 43)
    polyres@gsMarkerColor = (/"yellow2"/)
    lineres@gsLineColor = (/"yellow2"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (onedwind(i) .ge. 43 .and. onedwind(i) .lt. 49)
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (onedwind(i) .ge. 49 .and. onedwind(i) .lt. 58)
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
  
  if (i .ne. 0) then
  if (gc_latlon(onedlat(i),onedlon(i),onedlat(i-1),onedlon(i-1),2,4) .lt. 400) then
    if(onedwind(i) .ge. cutwind) then
      dum(i) = gsn_add_polyline(wks,map,(/onedlon(i),onedlon(i-1)/),(/onedlat(i),onedlat(i-1)/),lineres)
      
      ;if (mod(i,4) .eq. 0) then
      ;  str = sprintf("%4.0f",traj_data(i,4))+sprintf("%2.0f",traj_data(i,5))+sprintf("%2.0f",traj_data(i,6))
      ;  gsn_text(wks,map,str,traj_data(i,0),traj_data(i,1),txres)
      ;end if
      if (modelgrid .eq. "ibtracs") then
        if (mod(i,1000) .eq. 0) then
          print("Working on lat/lon number: "+i+" of traj_nrows: "+traj_nrows+" which is year: "+onedyear(i))
        end if
      end if
    end if
  end if
  end if
  
;  gsn_polymarker(wks,map,traj_data(i,0),traj_data(i,1),polyres)
  
end if

end do

; if we are doing a varres grid, let's push an outline of the atl30x4 grid
if (modelgrid .eq. "vr") then
  map = plot_outline_fcn(wks,map,"black",3.0)
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
if (basin .eq. "atlantic") then
amres@amParallelPosF   = 0.43		    ; move legend to the right
amres@amOrthogonalPosF = -.3             ; move the legend down
else if (basin .eq. "tropics") then
amres@amParallelPosF   = 0.21		    ; move legend to the right .37 formerly
amres@amOrthogonalPosF = .27             ; move the legend down
else
amres@amParallelPosF   = -0.30		    ; move legend to the right .37 formerly
amres@amOrthogonalPosF = .27             ; move the legend down
end if
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
