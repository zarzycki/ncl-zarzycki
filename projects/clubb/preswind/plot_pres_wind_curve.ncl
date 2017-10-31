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

out_type = "png"
plot_850 = False   ; if T, use 850 winds, if F use BOT winds
plot_obs = True

drawRegLines=True
maskBasins=False
basin = 1

wind_factor = "log"
traj_a_dir = "/glade/u/home/zarzycki/work/clubb-tracking/CAM5_ALL/"
traj_a_filename = "trajectories.txt.CAM5"
traj_a_name="CAM5"
traj_b_dir = "/glade/u/home/zarzycki/tempest-scripts/clubb/"
traj_b_filename = "traj.txt.CLUBB"
traj_b_name="CAM6"

ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"

colorArray = (/"blue","red","springgreen4"/)
lineColors = (/"blue4","red4","darkgreen"/)

markerTypes = (/2,5,1/)

threshWind = 20.0 ; threshold wind in m/s

if (plot_850 .and. plot_obs) then
  print("Really shouldn't overlay ibtracs obs with 850 mb winds -- turning off obs")
  plot_obs=False
end if

;----------------Constants-----------------------------------

nEntries=50000
ms_to_kts = 1.94384449

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)
factor = 100./115. ; from Franklin et al 2003
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
if (plot_850) then
  traj_a_wind = traj_a_data(:,4,:)
else
  traj_a_wind = traj_a_data(:,5,:)*factor
end if

maxLines = -1
traj_b_data = getTrajectories(traj_b_dir+"/"+traj_b_filename,ncols,maxLines)
traj_b_lon = traj_b_data(:,1,:)
traj_b_lat = traj_b_data(:,2,:)
traj_b_pres = traj_b_data(:,3,:)/100.
if (plot_850) then
  traj_b_wind = traj_b_data(:,4,:)
else
  traj_b_wind = traj_b_data(:,5,:)*factor
end if


if (maskBasins) then

  tmpDim=dimsizes(traj_a_lon)
  traj_nstorms=tmpDim(0)
  traj_nrows=tmpDim(1)
  do i = 0,traj_nstorms-1
  do j = 0,traj_nrows-1
    if (.not.ismissing(traj_a_lon(i,j))) then
      cyclon = traj_a_lon(i,j)
      cyclat = traj_a_lat(i,j)
      ;print("cyclon: "+cyclon+"    cyclat: "+cyclat)
      if (cyclon .gt. max(tcMask&lon))
        cyclon = max(tcMask&lon)
      end if
      if (tcMask({cyclat},{cyclon}) .ne. basin)
        ; If not in Atlantic basin, replace with missing values
        traj_a_pres(i,j) = -999
        traj_a_wind(i,j) = -999
      else
      end if
    end if
  end do
  end do

  tmpDim=dimsizes(traj_b_lon)
  traj_nstorms=tmpDim(0)
  traj_nrows=tmpDim(1)
  do i = 0,traj_nstorms-1
  do j = 0,traj_nrows-1
    if (.not.ismissing(traj_b_lon(i,j))) then
      cyclon = traj_b_lon(i,j)
      cyclat = traj_b_lat(i,j)
      ;print("cyclon: "+cyclon+"    cyclat: "+cyclat)
      if (cyclon .gt. max(tcMask&lon))
        cyclon = max(tcMask&lon)
      end if
      if (tcMask({cyclat},{cyclon}) .ne. basin)
        ; If not in Atlantic basin, replace with missing values
        traj_b_pres(i,j) = -999
        traj_b_wind(i,j) = -999
      else
      end if
    end if
  end do
  end do

end if

onedpres_a = ndtooned(traj_a_pres)
onedwind_a = ndtooned(traj_a_wind)
onedpres_b = ndtooned(traj_b_pres)
onedwind_b = ndtooned(traj_b_wind)

;--------------------------------------------------------

if (plot_obs) then

  print("Get ibTracs data")

  ibfile = addfile(ibdir+ibfilename,"r")

  iblat = ibfile->lat_for_mapping*.01
  iblon = ibfile->lon_for_mapping*.01
  ; Quick fix for lons that go outside the tcMask
  iblon(:,0) = where(iblon(:,0).gt.180.0-maskspacing,180.0-maskspacing,iblon(:,0))
  ibpres = ibfile->source_pres(:,:,0)*.1
  ibyear = ibfile->season
  ibwind = ibfile->source_wind(:,:,0)*.1/ms_to_kts

  ibdimsizes = dimsizes(iblat)
  ibnumstorms = ibdimsizes(0)

  do i = 0,ibnumstorms-1
    if (ibyear(i) .ge. 1980 .and. ibyear(i) .le. 2009) then
    else
      ibpres(i,:) = ibpres@_FillValue
      ibwind(i,:) = ibwind@_FillValue
    end if
  end do

  onedpres = ndtooned(ibpres)
  onedwind = ndtooned(ibwind)

  if (threshWind .gt. 0) then
    onedpres = where(onedwind.lt.threshWind, -999, onedpres)
    onedwind = where(onedwind.lt.threshWind, -999, onedwind)  
    onedpres_a = where(onedwind_a.lt.threshWind, -999, onedpres_a)
    onedwind_a = where(onedwind_a.lt.threshWind, -999, onedwind_a)  
    onedpres_b = where(onedwind_b.lt.threshWind, -999, onedpres_b)
    onedwind_b = where(onedwind_b.lt.threshWind, -999, onedwind_b)  
  end if

end if

;--------------------------------------------------------
if drawRegLines then
  print("Calculating regression for best-fit line")
  polyn = 3
  regx = fspan(0,100,750)

  quad_a = lspoly(onedwind_a, onedpres_a , 1, polyn)
  quad_b = lspoly(onedwind_b, onedpres_b , 1, polyn)
  a_regy = new(dimsizes(regx),float)
  b_regy = new(dimsizes(regx),float)
  a_regy = quad_a(0) + quad_a(1)*regx + quad_a(2)*regx^2
  b_regy = quad_b(0) + quad_b(1)*regx + quad_b(2)*regx^2

  if (plot_obs) then
    quad_obs = lspoly(onedwind, onedpres , 1, polyn)
    obsregy = new(dimsizes(regx),float)
    obsregy = quad_obs(0) + quad_obs(1)*regx + quad_obs(2)*regx^2
  end if
end if
  
;-------------------------------------------------------- 


if (plot_850) then
  mainStr  = "Pressure-Wind (850mb)"
  plotName = "pres_wind_850"
else
  mainStr  = "Pressure-Wind (10-m)"
  plotName = "pres_wind_10m"
end if

wks  = gsn_open_wks(out_type,plotName)            ; open a ps file

res  = True
res@gsnMaximize            = True       ; Maximize plot in frame.
res@gsnDraw    = False                         ; don't draw
res@gsnFrame   = False                         ; don't advance frame

res@tiMainString  = mainStr

res@tiYAxisString = "Wind speed (m/s)" 	; y axis title
res@tiXAxisString = "Surface pressure (hPa)" 	; y axis title

res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = 0.018
res@tiMainFontHeightF = 0.02
res@tmXBLabelFontHeightF = 0.015
res@tmYLLabelFontHeightF = 0.015

res@trXMinF           = 875.
res@trXMaxF           = 1025.
res@trYMinF           = 20.
res@trYMaxF           = 95.

res@xyMarkLineMode = "Markers"


; Draw ibTracks data


; Draw CAM-SE data
res@xyMarkerColors = colorArray(1)
res@xyMarker      = markerTypes(1)
res@xyMarkerSizeF = 0.005
plot = gsn_csm_xy(wks,onedpres_a,onedwind_a,res)

res@xyMarkerColors = "white"
res@xyMarker      = markerTypes(2)
res@xyMarkerSizeF = 0.008 ;0.018
plot5 = gsn_csm_xy(wks,onedpres_b,onedwind_b,res)
overlay(plot,plot5)
res@xyMarkerColors = colorArray(2)
res@xyMarker      = markerTypes(2)
res@xyMarkerSizeF = 0.006 ;0.018
plot6 = gsn_csm_xy(wks,onedpres_b,onedwind_b,res)
overlay(plot,plot6)

if (plot_obs) then
  res@xyMarkerColors = colorArray(0)
  res@xyMarker      = markerTypes(0)
  res@xyMarkerSizeF = 0.005
  plot2 = gsn_csm_xy(wks,onedpres,onedwind,res)
  overlay(plot,plot2)
end if





; Now we will plot the quad fit lines
if drawRegLines then
  res@xyMarker      = 1
  
  if (plot_obs) then
    res@xyMarkerSizeF = 0.020
    res@xyMarkerColors = lineColors(0)
    plot3 = gsn_csm_xy(wks,obsregy,regx,res)
    overlay(plot,plot3)
  end if
  
  res@xyMarkerColors = lineColors(1)
  plot4 = gsn_csm_xy(wks,a_regy,regx,res)
  overlay(plot,plot4)
  
  res@xyMarkerColors = lineColors(2)
  plot6 = gsn_csm_xy(wks,b_regy,regx,res)
  overlay(plot,plot6)
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
if (plot_obs) then
  lbid = gsn_create_legend(wks,3,(/traj_b_name,traj_a_name,"Obs (IBTrACS)"/),lgres)
else
  lbid = gsn_create_legend(wks,2,(/traj_b_name,traj_a_name/),lgres)
end if

amres = True
amres@amParallelPosF   = 0.3		    ; move legend to the right
amres@amOrthogonalPosF = -.4             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

draw(plot)
frame(wks)

end

