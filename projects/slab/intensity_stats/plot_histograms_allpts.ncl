;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;========================================================
begin

;---------------User settings----------------------------

out_type = "pdf"

wind_factor = "log"

plot_wind=False
zoom_extremes=True
plot_thermo_only=False  ; if True, plot slab with thermo only terms

; PRES WIND CURVE
addPresWind=False
drawRegLines=True
colorArray = (/"blue","red","springgreen4"/)
markerTypes = (/2,5,1/)

plot_obs=False
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"

threshWind = 0.0 ; threshold wind in m/s

;----------------Constants-----------------------------------

nEntries=50000
ms_to_kts = 1.94384449

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;--------------------------------------------------------

;print("Getting TC Mask")
maskspacing=2
;tcMask = mask_tc(0,-999,-999,maskspacing,360)
;tcMaskIB = mask_tc(0,-999,-999,maskspacing,180)

;--------------------------------------------------------

print("Get ibTracs data")

if(plot_obs) then

ibfile = addfile(ibdir+ibfilename,"r")

ibpres = dim_avg_n_Wrap((ibfile->source_pres(:,:,:)*.1),2)
ibyear = ibfile->season
ibwind = dim_avg_n_Wrap((ibfile->source_wind(:,:,:)*.1/ms_to_kts),2)
ibtype = toint(ibfile->nature_for_mapping)
ibbasin = toint(ibfile->basin)
ibtime = ibfile->source_time


ibdimsizes = dimsizes(ibwind)
ibnumstorms = ibdimsizes(0)

do i = 0,ibnumstorms-1
  if (ibyear(i) .ge. 1980 .and. ibyear(i) .le. 2000) then
  ;.and. tcMaskIB({iblat(i,0)},{iblon(i,0)}) .eq. 1
  else
    ibpres(i,:) = ibpres@_FillValue
    ibwind(i,:) = ibwind@_FillValue
  end if
end do

onedpres = ndtooned(ibpres)
onedwind = ndtooned(ibwind)
onedtype = ndtooned(ibtype)
onedbasin = ndtooned(ibbasin)
onedtime = ndtooned(ibtime)
onedtime@units=ibtime@units

utc_date = cd_calendar(onedtime, 0)
onedmonth = utc_date(:,1)

onedpres = where(onedtype.ne.0, onedpres@_FillValue, onedpres)
onedwind = where(onedtype.ne.0, onedwind@_FillValue, onedwind)  

;do i = 0,dimsizes(onedmonth)-1
;  if (.not.ismissing(onedmonth(i)));
;
;    print(" "+onedmonth(i)+" "+onedpres(i))
;
;  end if
;end do

onedpres = where(onedmonth.lt.6 .or. onedmonth.gt.11 , onedpres@_FillValue, onedpres)
onedwind = where(onedmonth.lt.6 .or. onedmonth.gt.11 , onedwind@_FillValue, onedwind) 

onedpres = where(onedbasin.lt.0 .or. onedbasin.gt.3 , onedpres@_FillValue, onedpres)
onedwind = where(onedbasin.lt.0 .or. onedbasin.gt.3 , onedwind@_FillValue, onedwind) 

if (threshWind .gt. 0) then
  onedpres = where(onedpres.lt.threshWind, onedpres@_FillValue, onedpres)
  onedwind = where(onedwind.lt.threshWind, onedwind@_FillValue, onedwind)  
end if

end if

;--------------------------------------------------------


nfiles=3
do z = 0,2

if(z .eq. 0) then
  traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
  traj_filename = "cat_traj_fixedSST_900.txt"
else if(z .eq. 1) then
  traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
  ;traj_filename = "cat_traj_slab_08_7.05_900.txt"
  traj_filename = "cat_traj_slab_08_4.7_900.txt"
else if(z .eq. 2) then
  traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
  ;traj_filename = "cat_traj_slab_08_11.75_900.txt"
  traj_filename = "cat_traj_slab2_08_4.7_900.txt"
  if (plot_thermo_only) then
    traj_filename = "cat_traj_slab3_900.txt"
  end if
else
  print("Whoops")
end if
end if
end if

print("Read in TC locations from CAM")
traj_cleanfile = "traj_filt_clean.TMP" ; hardcoded temp file name, feel free to change
print("Removing text headers from trajectories")
system("grep -v '^start' "+ traj_dir+"/"+traj_filename +" > "+traj_cleanfile+"")

traj_ncols = numAsciiCol(traj_cleanfile)
traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
print("'" + traj_filename + "' has " + traj_nrows + " rows and " + traj_ncols + \
      " columns of data.")
print("Removing temporary file:"+traj_cleanfile)
system("rm -rf "+traj_cleanfile)

if (z .eq. 0)
  traj_lon = new((/nfiles,nEntries/),"float")
  traj_lat = new((/nfiles,nEntries/),"float")
  traj_wind = new((/nfiles,nEntries/),"float")
  traj_pres = new((/nfiles,nEntries/),"float")
end if
;print(traj_data)

do i = 0,traj_nrows-1
  traj_lon(z,i) = traj_data(i,3)
  traj_lat(z,i) = traj_data(i,4)
  traj_wind(z,i) = traj_data(i,5)*factor
  traj_pres(z,i) = traj_data(i,7)/100.
end do

delete(traj_data)
delete(traj_filename)
delete(traj_dir)
delete(traj_ncols)
delete(traj_nrows)
end do

if (threshWind .gt. 0) then
  traj_wind = where(traj_wind.lt.threshWind, traj_wind@_FillValue, traj_wind)
  traj_pres = where(traj_wind.lt.threshWind, traj_pres@_FillValue, traj_pres)
end if

opt = True
opt@PrintStat = True
print("-----------------------------------------------------------------------")
print("FIXED")
if (plot_wind) then
  stata = stat_dispersion(traj_wind(0,:), opt )
else
  stata = stat_dispersion(traj_pres(0,:), opt )
end if
print("-----------------------------------------------------------------------")
print("SLAB")
if (plot_wind) then
  statb = stat_dispersion(traj_wind(1,:), opt )
else
  statb = stat_dispersion(traj_pres(1,:), opt )
end if
print("-----------------------------------------------------------------------")
print("SLAB2")
if (plot_wind) then
  statc = stat_dispersion(traj_wind(2,:), opt )
else
  statc = stat_dispersion(traj_pres(2,:), opt )
end if
if(plot_obs) then
  print("-----------------------------------------------------------------------")
  print("OBS")
  statz = stat_dispersion(onedpres, opt )
end if

; NUM, MEAN, MEDIAN, 5%, 1%, 0.1%, MAX
; FIXED, SLAB1, SLAB2
if (plot_obs) then
  rowsForCSV=4
else
  rowsForCSV=3
end if
statArray = new((/rowsForCSV,7/),"float")

; Always modify the FIXEDSST runs, then copy paste into SLAB1 and SLAB2 and search/replace
; for statArray(X, and statb
; FIXED SST
statArray(0,0) = stata(19)
statArray(0,1) = stata(0)
statArray(0,2) = stata(8)
if (plot_wind) then      ; WIND
  statArray(0,3) = stata(25)
  statArray(0,4) = stata(26)
  statArray(0,5) = stata(27)
  statArray(0,6) = stata(14)
else                    ; MSLP
  statArray(0,3) = stata(24)
  statArray(0,4) = stata(23)
  statArray(0,5) = stata(22)
  statArray(0,6) = stata(2)
end if

; SLAB1
statArray(1,0) = statb(19)
statArray(1,1) = statb(0)
statArray(1,2) = statb(8)
if (plot_wind) then      ; WIND
  statArray(1,3) = statb(25)
  statArray(1,4) = statb(26)
  statArray(1,5) = statb(27)
  statArray(1,6) = statb(14)
else                    ; MSLP
  statArray(1,3) = statb(24)
  statArray(1,4) = statb(23)
  statArray(1,5) = statb(22)
  statArray(1,6) = statb(2)
end if

; SLAB2
statArray(2,0) = statc(19)
statArray(2,1) = statc(0)
statArray(2,2) = statc(8)
if (plot_wind) then      ; WIND
  statArray(2,3) = statc(25)
  statArray(2,4) = statc(26)
  statArray(2,5) = statc(27)
  statArray(2,6) = statc(14)
else                    ; MSLP
  statArray(2,3) = statc(24)
  statArray(2,4) = statc(23)
  statArray(2,5) = statc(22)
  statArray(2,6) = statc(2)
end if

;print("NUM,MEAN,MEDIAN,5%,1%,0.1%,MAX")
;do j = 0,2
;  print(statArray(j,0)+","+statArray(j,1)+","+statArray(j,2)+","+statArray(j,3)+","+statArray(j,4)+","+statArray(j,5)+","+statArray(j,6))
;end do

if (plot_wind) then
  outFileName="text/wind.csv"
else
  outFileName="text/mslp.csv"
end if

system("rm "+outFileName)
system("echo NUM,MEAN,MEDIAN,5%,1%,0.1%,MAX >> "+outFileName)
do j = 0,rowsForCSV-1
  system("echo "+statArray(j,0)+","+statArray(j,1)+","+statArray(j,2)+","+statArray(j,3)+","+statArray(j,4)+","+statArray(j,5)+","+statArray(j,6)+" >> "+outFileName)
end do

print("-----------------------")
print("mean fixed wind "+avg(traj_wind(1,:)))
print("mean slab wind "+avg(traj_wind(0,:)))
print("mean slab2 wind "+avg(traj_wind(2,:)))
print("-----------------------")
print("mean fixed pres "+avg(traj_pres(1,:)))
print("mean slab pres "+avg(traj_pres(0,:)))
print("mean slab2 pres "+avg(traj_pres(2,:)))
print("-----------------------")
print("num hits fixed "+num(.not.ismissing(traj_wind(1,:))))
print("num hits slab "+num(.not.ismissing(traj_wind(0,:))))
print("num hits slab2 "+num(.not.ismissing(traj_wind(2,:))))
print("-----------------------")

binSettings=True
if (plot_wind) then
  binSettings@bin_min=5.0
  binSettings@bin_max=70.0
  nbins=20
  ap  = pdfx(traj_wind(0,:), nbins, binSettings)
  bp  = pdfx(traj_wind(1,:), nbins, binSettings)
  cp  = pdfx(traj_wind(2,:), nbins, binSettings)
if(plot_obs) then
  zp  = pdfx(onedwind, nbins, binSettings)
end if
else
  binSettings@bin_min=895.0
  binSettings@bin_max=1025.0
  nbins = 20
  ap  = pdfx(traj_pres(0,:), nbins, binSettings)
  bp  = pdfx(traj_pres(1,:), nbins, binSettings)
  cp  = pdfx(traj_pres(2,:), nbins, binSettings)
if(plot_obs) then
  zp  = pdfx(onedpres, nbins, binSettings)
end if
end if

print("Fractional sums slab: "+sum(ap))
print("Fractional sums fixed: "+sum(bp))
if(plot_obs) then
  print("Fractional sums ibtracs: "+sum(zp))
end if
print("-----------------------")

nVar    = 3
if(plot_obs) then
  nVar    = nVar+1
end if

nBin    = ap@nbins          ; retrieve the number of bins

xx      = new ( (/nVar, nBin/), typeof(ap))

xx(0,:) = ap@bin_center
xx(1,:) = bp@bin_center
xx(2,:) = cp@bin_center
if(plot_obs) then
  xx(3,:) = zp@bin_center
end if

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap /)
yy(1,:) = (/ bp /)
yy(2,:) = (/ cp /)
if(plot_obs) then
  yy(3,:) = (/ zp /)
end if

if(plot_wind) then
  plotName="pdf-wind-6hrly"
else
  plotName="pdf-mslp-6hrly"
end if
wks  = gsn_open_wks (out_type,"pdf/"+plotName)
if (zoom_extremes) then
  plot = new(2,graphic)
else
  plot = new(1,graphic)
end if

  
res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/6.0,6.0,6.0,6.0/)        
res@xyLineColors             = (/"darkgreen","blue","red","black"/)  
res@xyMonoDashPattern        = False              ; all solid 
res@xyDashPatterns = (/1,2,16,4/)
res@tiYAxisString            = "PDF (%)"

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of 

res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height

if (plot_thermo_only)
  if(plot_obs) then
    res@xyExplicitLegendLabels = (/"fixedSST","slab","thermo","ibtracs"/)  ; create explicit labels
  else
    res@xyExplicitLegendLabels = (/"FIXEDSST","SLAB","THERMO"/)  ; create explicit labels
  end if
else
  if(plot_obs) then
    res@xyExplicitLegendLabels = (/"fixedSST","slab","slab2","ibtracs"/)  ; create explicit labels
  else
    res@xyExplicitLegendLabels = (/"FIXEDSST","SLAB1","SLAB2"/)  ; create explicit labels
  end if
end if

;res@vpHeightF = 0.5
;res@vpWidthF = 0.75

if(plot_wind) then  ; DO WIND

  res@tmXBPrecision = 2 ; Precision on x-axis always 2 (XX m/s)

  res@pmLegendParallelPosF   = .75                 ; move units right
  res@pmLegendOrthogonalPosF = -0.6                ; move units down
  res@tiXAxisString ="Wind speed (m/s)"
  res@tiMainString  = "10-m Wind PDF"	; title

  res@trXMinF           = 10.
  res@trXMaxF           = 70.
  plot(0) = gsn_csm_xy (wks, xx, yy, res)

  if(zoom_extremes)
    res@trXMinF           = 40.
    res@trXMaxF           = 70.
    res@trYMinF           = 0.
    res@trYMaxF           = 6.0

    res@tiMainString = res@tiMainString+" (zoom)"

    res@pmLegendDisplayMode="Never" ; turn legend off for extremes
    res@tiYAxisString            = ""
    plot(1) = gsn_csm_xy (wks, xx, yy, res)
  end if

else  ; DO SLP

  res@tmXBPrecision = 4 ; Precision on x-axis always 4 (XXXX hPa)

  res@pmLegendParallelPosF   = .25                 ; move units right
  res@pmLegendOrthogonalPosF = -0.4                ; move units down
  res@tiXAxisString = "Sea level pressure (hPa)" 
  res@tiMainString  = "Minimum SLP PDF"	; title

  res@trYMinF           = 0.   ; use for tuning to fix panel label issue
  res@trYMaxF           = 35.  ; use for tuning to fix panel label issue
  res@trXMinF           = 890.
  res@trXMaxF           = 1020.
  plot(0) = gsn_csm_xy (wks, xx, yy, res)

  if(zoom_extremes)
    res@tmXBPrecision = 3 ; need to change to 3 since we are only in XXX mb regime

    res@trXMinF           = 890.
    res@trXMaxF           = 965.
    res@trYMinF           = 0.
    res@trYMaxF           = 5.1

    res@tiMainString = res@tiMainString+" (zoom)"

    res@pmLegendDisplayMode="Never" ; turn legend off for extremes
    res@tiYAxisString            = ""
    plot(1) = gsn_csm_xy (wks, xx, yy, res)
  end if
end if
res@tiYAxisString = "Frequency (%)" 	; y axis title

resP=True
;resP@txString  = "Init: 2012090200, valid: +120h"
;resP@txFontHeightF = 0.015

resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.025
if (plot_wind) then
  resP@gsnPanelFigureStrings= (/"a.","b."/)
else
  resP@gsnPanelFigureStrings= (/"c.","d."/)
end if

gsn_panel(wks,plot,(/1,2/),resP)             ; now draw as one plot

delete(res)

















;===========================================================================

if(addPresWind) then

  ;--------------------------------------------------------
  if drawRegLines then
    print("Calculating regression for best-fit line")
  
    polyn = 3
    quad_obs = lspoly(onedwind, onedpres , 1, polyn)    ; all weights are set to one
    ;print("Calculating regression for cam")
    quad_slab = lspoly(traj_wind(0,:), traj_pres(0,:) , 1, polyn)
    quad_fixedSST = lspoly(traj_wind(1,:), traj_pres(1,:) , 1, polyn)
    ;print(quad_cam) ; Y = c(0) + c(1)*x + c(2)*x^2
    regx = fspan(0,100,750)
    slabregy = new(dimsizes(regx),float)
    obsregy = new(dimsizes(regx),float)
    fixedSSTregy = new(dimsizes(regx),float)
    slabregy = quad_slab(0) + quad_slab(1)*regx + quad_slab(2)*regx^2
    obsregy = quad_obs(0) + quad_obs(1)*regx + quad_obs(2)*regx^2
    fixedSSTregy = quad_fixedSST(0) + quad_fixedSST(1)*regx + quad_fixedSST(2)*regx^2

  end if
  
  ;-------------------------------------------------------- 

  wks  = gsn_open_wks("x11","pres_wind")            ; open a ps file

  res  = True
  res@gsnMaximize            = True       ; Maximize plot in frame.
  res@gsnDraw    = False                         ; don't draw
  res@gsnFrame   = False                         ; don't advance frame

  res@tiMainString  = "Pressure-Wind Relationship"	; title
  res@tiYAxisString = "Wind speed (m/s)" 	; y axis title
  res@tiXAxisString = "Surface pressure (hPa)" 	; y axis title

  res@tiYAxisFontHeightF = 0.018
  res@tiXAxisFontHeightF = 0.018
  res@tiMainFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.015
  res@tmYLLabelFontHeightF = 0.015

  res@trXMinF           = 887.
  res@trXMaxF           = 1022.
  res@trYMinF           = 17.5
  res@trYMaxF           = 86.

  res@xyMarkLineMode = "Markers"


  ; Draw ibTracks data
  res@xyMarkerColors = colorArray(0)
  res@xyMarker      = markerTypes(0)
  res@xyMarkerSizeF = 0.0025
  plot = gsn_csm_xy(wks,onedpres,onedwind,res)

  ; Draw CAM-SE data
  res@xyMarkerColors = colorArray(1)
  res@xyMarker      = markerTypes(1)
  res@xyMarkerSizeF = 0.002
  plot2 = gsn_csm_xy(wks,traj_pres(0,:),traj_wind(0,:),res)
  overlay(plot,plot2)

  res@xyMarkerColors = "white"
  res@xyMarker      = markerTypes(2)
  res@xyMarkerSizeF = 0.009 ;0.018
  plot5 = gsn_csm_xy(wks,traj_pres(1,:),traj_wind(1,:),res)
  overlay(plot,plot5)
  res@xyMarkerColors = colorArray(2)
  res@xyMarker      = markerTypes(2)
  res@xyMarkerSizeF = 0.007 ;0.018
  plot6 = gsn_csm_xy(wks,traj_pres(1,:),traj_wind(1,:),res)
  overlay(plot,plot6)

  ; Now we will plot the quad fit lines
  if drawRegLines then
    res@xyMarker      = 1
  
    res@xyMarkerSizeF = 0.020
    res@xyMarkerColors = colorArray(0)
    plot3 = gsn_csm_xy(wks,obsregy,regx,res)
    overlay(plot,plot3)
  
    res@xyMarkerColors = colorArray(1)
    plot4 = gsn_csm_xy(wks,slabregy,regx,res)
    overlay(plot,plot4)
  
    res@xyMarkerColors = colorArray(2)
    plot6 = gsn_csm_xy(wks,fixedSSTregy,regx,res)
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
  lbid = gsn_create_legend(wks,3,(/"CAM-SE Uni. (1~S~o~N~)","CAM-SE V-R (0.25~S~o~N~)","Obs (IBTrACS)"/),lgres)


  amres = True
  amres@amParallelPosF   = 0.3		    ; move legend to the right
  amres@amOrthogonalPosF = -.4             ; move the legend down
  annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

  draw(plot)
  frame(wks)

end if

end

