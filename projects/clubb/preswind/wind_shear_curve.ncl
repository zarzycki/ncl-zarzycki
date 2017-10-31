;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

;---------------User settings----------------------------

out_type = "pdf"

drawRegLines=True
maskBasins=False
basin = 1

wind_factor = "log"
traj_a_dir = "/glade/scratch/zarzycki/clubb-tracking/CAM5/"
traj_a_filename = "trajectories.txt.CAM5"
traj_a_name="CAM5"
traj_b_dir = "/glade/scratch/zarzycki/clubb-tracking/CLUBB/"
traj_b_filename = "trajectories.txt.CLUBB"
traj_b_name="CAM5.5"

colorArray = (/"blue","red","springgreen4"/)
lineColors = (/"blue4","red4","darkgreen"/)

markerTypes = (/2,5,1/)

;----------------Constants-----------------------------------

nEntries=50000
ms_to_kts = 1.94384449

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;--------------------------------------------------------

print("Getting TC Mask")
maskspacing=2
tcMask = mask_tc(0,-999,-999,maskspacing,360)
tcMaskIB = mask_tc(0,-999,-999,maskspacing,180)

;--------------------------------------------------------

print("Read in TC locations from CAM")

ncols = 12                     ; assign number of columns
maxLines = -1

traj_a_data = getTrajectories(traj_a_dir+"/"+traj_a_filename,ncols,maxLines)
traj_a_lon = traj_a_data(:,1,:)
traj_a_lat = traj_a_data(:,2,:)
traj_a_pres = traj_a_data(:,3,:)/100.
traj_a_wind850 = traj_a_data(:,4,:)
traj_a_wind10 = traj_a_data(:,5,:)*factor

maxLines = -1
traj_b_data = getTrajectories(traj_b_dir+"/"+traj_b_filename,ncols,maxLines)
traj_b_lon = traj_b_data(:,1,:)
traj_b_lat = traj_b_data(:,2,:)
traj_b_pres = traj_b_data(:,3,:)/100.
traj_b_wind850 = traj_b_data(:,4,:)
traj_b_wind10 = traj_b_data(:,5,:)*factor

onedwind10_a  = ndtooned(traj_a_wind10)
onedwind850_a = ndtooned(traj_a_wind850)
onedwind10_b  = ndtooned(traj_b_wind10)
onedwind850_b = ndtooned(traj_b_wind850)


;--------------------------------------------------------
if drawRegLines then
  print("Calculating regression for best-fit line")
  polyn = 3
  regx = fspan(0,100,750)

  quad_a = lspoly(onedwind10_a, onedwind850_a , 1, polyn)
  quad_b = lspoly(onedwind10_b, onedwind850_b , 1, polyn)
  a_regy = new(dimsizes(regx),float)
  b_regy = new(dimsizes(regx),float)
  a_regy = quad_a(0) + quad_a(1)*regx + quad_a(2)*regx^2
  b_regy = quad_b(0) + quad_b(1)*regx + quad_b(2)*regx^2

end if
  
;-------------------------------------------------------- 



mainStr  = "Wind (10m)-Wind (850mb)"
plotName = "wind_shear_850_10m"

wks  = gsn_open_wks(out_type,plotName)            ; open a ps file

res  = True
res@gsnMaximize            = True       ; Maximize plot in frame.
res@gsnDraw    = False                         ; don't draw
res@gsnFrame   = False                         ; don't advance frame

res@tiMainString  = mainStr

res@tiXAxisString = "850 mb wind speed (m/s)"
res@tiYAxisString = "10-m wind speed (m/s)"

res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = 0.018
res@tiMainFontHeightF = 0.02
res@tmXBLabelFontHeightF = 0.015
res@tmYLLabelFontHeightF = 0.015

res@trXMinF           = 0.
res@trXMaxF           = 95.
res@trYMinF           = 0.
res@trYMaxF           = 95.

res@xyMarkLineMode = "Markers"


; Draw ibTracks data


; Draw CAM-SE data
res@xyMarkerColors = colorArray(1)
res@xyMarker      = markerTypes(1)
res@xyMarkerSizeF = 0.004
plot = gsn_csm_xy(wks,onedwind850_a,onedwind10_a,res)

res@xyMarkerColors = "white"
res@xyMarker      = markerTypes(2)
res@xyMarkerSizeF = 0.016 ;0.018
plot5 = gsn_csm_xy(wks,onedwind850_b,onedwind10_b,res)
overlay(plot,plot5)
res@xyMarkerColors = colorArray(2)
res@xyMarker      = markerTypes(2)
res@xyMarkerSizeF = 0.014 ;0.018
plot6 = gsn_csm_xy(wks,onedwind850_b,onedwind10_b,res)
overlay(plot,plot6)



; Now we will plot the quad fit lines
if drawRegLines then
  res@xyMarker      = 1
  
  res@xyMarkerColors = lineColors(1)
  plot4 = gsn_csm_xy(wks,a_regy,regx,res)
  overlay(plot,plot4)
  
  res@xyMarkerColors = lineColors(2)
  plot6 = gsn_csm_xy(wks,b_regy,regx,res)
  overlay(plot,plot6)

  res@xyMarkerColors = "black"
  plotref = gsn_csm_xy(wks,regx,regx,res)
  overlay(plot,plotref)
end if


lgres                    = True
lgres@lgMonoMarkerSize = False
lgres@lgLabelFontHeightF = .18
lgres@vpWidthF           = 0.24
lgres@vpHeightF          = 0.10
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgMonoMarkerIndex = False
lgres@lgItemType         = "Markers"

lgres@lgMarkerColors     = colorArray(::-1)
lgres@lgMarkerIndexes = markerTypes(::-1)
lgres@lgMarkerSizes = (/0.028,0.005,0.007/)

lbid = gsn_create_legend(wks,2,(/traj_b_name,traj_a_name/),lgres)


amres = True
amres@amParallelPosF   = -0.3		    ; move legend to the right
amres@amOrthogonalPosF = -.4             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

draw(plot)
frame(wks)

end

