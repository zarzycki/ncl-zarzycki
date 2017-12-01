load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"

begin

out_type="png"

; 2D var to load
var = "PHIS"

; File with native data (in this case, PHIS)
;dataname = "/glade/p/work/zarzycki/unigridFiles/antarctica_30_x8/topo/topo_antarctica_30_x8_smooth.nc"
dataname = "/glade/p/work/zarzycki/unigridFiles/antarctica_30_x4/topo/topo_antarctica_30_x4_smooth.nc"
;dataname="/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc"
datafile = addfile(dataname,"r")

; exodus grid file to overlay
;gridname = "/glade/p/work/zarzycki/grids/exodus/antarctica_30_x8.g"
gridname = "/glade/p/work/zarzycki/grids/exodus/antarctica_30_x4.g"
;gridname = "/glade/p/work/zarzycki/grids/exodus/uniform_30.g"
gridfile = addfile(gridname,"r")

; loading var and lat/lon arrays
theVar=datafile->$var$(:)
lon1d=datafile->lon
lat1d=datafile->lat

; Orthographic Projection
wks = gsn_open_wks(out_type,"grid")

res = True

res@gsnDraw=False
res@gsnFrame=False

res@sfXArray            = lon1d        ; Required to tell NCL where to
res@sfYArray            = lat1d        ; overlay data on globe.

  res@cnFillOn            = True         ; Turn on contour fill
;  res@cnFillMode       = "AreaFill" ; Style of fill. You can also use "CellFill" and "RasterFill"

res@mpProjection      = "Orthographic"
res@mpOutlineBoundarySets = "National"

; SOUTH POLE
res@mpCenterLatF      =  -90.
res@mpCenterLonF      =  -15.

res@vpXF      = 0.05
res@vpYF      = 0.9
res@vpWidthF  = 0.9
res@vpHeightF = 0.8

res@gsnDraw  = False       ; don't draw the plots now
res@gsnFrame = False       ; or advance the frame

res@mpOutlineOn            = True
res@mpPerimOn              = False
res@mpLandFillColor        = "tan"
res@mpOceanFillColor       = "LightBlue"
res@mpInlandWaterFillColor = "Blue"
res@mpGreatCircleLinesOn = True


;gsn_define_colormap(wks,(/"white","black","tan","LightBlue","Blue"/))
gsn_define_colormap(wks,"MPL_gist_earth")
;gsn_define_colormap(wks,"cb_9step")
res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines
res@cnFillMode = "RasterFill"
res@gsnSpreadColors      = True              ; use full colormap
res@cnLinesOn = False

res@cnLevelSelectionMode = "ManualLevels"
res@cnLevelSpacingF      =  500.
res@cnMinLevelValF       =  0.0
res@cnMaxLevelValF       =  40000.0

plot = gsn_csm_contour_map(wks,theVar,res)  ; create the plot

; overlay SE gridfile using polygons
gridlinesize=0.5
gridlinecolor="white"
plot = plot_hommegrid_fcn(wks,plot,gridname,gridlinecolor,gridlinesize,-90,10,-180,180)

draw(plot)
frame(wks)

end


