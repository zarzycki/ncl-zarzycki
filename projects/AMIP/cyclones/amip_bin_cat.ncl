;========================================================
; AMIP Histogram by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
;========================================================
begin

windunits = "kts" ; options are "kts" and "ms"
wind_factor = "log"
domask = 0 ; 0 = true, 1 = false
maskbasin = 1
maskspacing = 2
countCut = 0.0 ;64.0 for hurricane
ms_to_kts = 1.94384449

; iBTracs data
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"
traj_filename = "/glade/u/home/zarzycki/outfile.txt"

; Wind speed power relation
if (wind_factor .eq. "power") then
  z_10 = 10.
  z_r = 64.
  alpha = 0.11
  factor = (z_10/z_r)^alpha
  print("Using "+wind_factor+" correction and wind correction factor: "+factor)
else if (wind_factor .eq. "log") then
  ; Garret 1992 -- Wind profile formulation
  ; Wieringa 1993 -- roughness coefficient
  z_10 = 10.
  z_r = 65.
  z_0 = 0.0002 ; roughness coeff
  factor = 1 + log(z_10/z_r)/log(z_r/z_0)
  print("Using "+wind_factor+" correction and wind correction factor: "+factor)
else if (wind_factor .eq. "none") then
  print("No correction used.")
else
  print("Incorrect wind correction type.")
  exit
end if
end if
end if
print("------------------------------------------------")

print("Getting TC masks")
  tcMask = mask_tc(0,-999,-999,maskspacing,360)
;  printVarSummary(tcMask)
  tcMaskIB = mask_tc(0,-999,-999,maskspacing,180)
;  printVarSummary(tcMaskIB)
print("Done getting TC masks")
print("------------------------------------------------")


print("Getting ibTracs data")

ibfile = addfile(ibdir+ibfilename,"r")
iblat = ibfile->lat_for_mapping(:,0)*.01
iblon = ibfile->lon_for_mapping(:,0)*.01
ibdimsizes = dimsizes(iblat)
ibnumstorms = ibdimsizes(0)
;ibyear = ibfile->season
ibsourcedate = ibfile->source_time(:,0)
ibdate = ut_calendar(ibsourcedate,0)
ibyear   = tointeger(ibdate(:,0))    ; Convert to integer for
ibmonth  = tointeger(ibdate(:,1))    ; use sprinti 
ibday    = tointeger(ibdate(:,2))
ibhour   = tointeger(ibdate(:,3))
ibminute = tointeger(ibdate(:,4))
ibsecond = ibdate(:,5)
ibname = ibfile->name

ibpres = ibfile->source_pres(:,:,:)*.1
if (windunits .eq. "kts") then
  ibwind = ibfile->source_wind(:,:,:)*.1
else if (windunits .eq. "ms") then
  ibwind = ibfile->source_wind(:,:,:)*.1/ms_to_kts
else
  print("invalid windunits")
  exit()
end if
end if

print("Beginning correction for wind averaging period")
; GUIDELINES FOR CONVERTING BETWEEN VARIOUS WIND
; AVERAGING PERIODS IN TROPICAL CYCLONE CONDITIONS 
; B. A. Harper, J. D. Kepert and J. D. Ginger
; August 2010
; WMO

wind_avg_period = toint(ibfile->wind_avg_period)
ibsource = ibfile->source
do i = 0,24
  if (wind_avg_period(i) .eq. 10) then
    print("Correcting "+ibsource(i,:)+" source from "+wind_avg_period(i)+" min")
    ibwind(:,:,i) = ibwind(:,:,i) / 0.9
  else if (wind_avg_period(i) .gt. 1.5 .and. wind_avg_period(i) .lt. 9.5) then
    print("Correcting "+ibsource(i,:)+" source from "+wind_avg_period(i)+" min")
    ibwind(:,:,i) = ibwind(:,:,i) / 0.98
  else
    print("Not correcting "+ibsource(i,:))
  end if
  end if
end do

; Here we specify which center we'd like to use
center = -999
if (maskbasin .eq. 1) then
  center = 0  ; hurdat_atl
else if (maskbasin .eq. 2) then
  center = 14 ; hurdat_epac
end if
end if

if (center .ge. 0) then
  print("We are only using center number "+ibsource(center,:)+" from ibTracs data")
else
  print("We are using all centers available for a particular storm. Use with CAUTION")
end if

if (center .lt. 0) then
  ; average over available values since we aren't sure which center
  ; from ibtracs to use
  ibpres_ = dim_avg_n_Wrap(ibpres,2)
  ibwind_ = dim_avg_n_Wrap(ibwind,2)
else
  ; we have specified the center we would like to use
  ibpres_ = ibpres(:,:,center)
  ibwind_ = ibwind(:,:,center)
end if

; Find array of max winds/min pres over cyclone lifespan
ibmaxwind = dim_max_n(ibwind_,1)
ibminpres = dim_min_n(ibpres_,1)

; Quick fix for lons that go outside the tcMask
iblon = where(iblon.gt.180.0-maskspacing,180.0-maskspacing,iblon)

print("Done getting ibTracs data")
print("------------------------------------------------")


print("Get AMIP data")

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
if (windunits .eq. "kts") then
  maxwind = traj_data(:,7)*ms_to_kts
else if (windunits .eq. "ms") then
  maxwind = traj_data(:,7)
else
  print("invalid windunits")
  exit()
end if
end if
minpres = traj_data(:,8)
;pathlength = traj_data(:,9)
numyears = toint(max(year) - min(year) + 1)
styear = toint(min(year))
enyear = toint(max(year))
numstorms = toint(max(stormid))



histogramInd = ispan(0,6,1)
histogram = new(7,integer)
histogram(:) = 0
ibhistogram = histogram

print("Masking out basins")
if (domask .eq. 0)
  do i = 0,numstorms-1
        if (tcMask({startlat(i)},{startlon(i)}) .ne. maskbasin)
          maxwind(i) = maxwind@_FillValue
          minpres(i) = minpres@_FillValue
        end if
  end do
  do i = 0,ibnumstorms-1
        if (tcMaskIB({iblat(i)},{iblon(i)}) .ne. maskbasin)
          ibmaxwind(i) = ibmaxwind@_FillValue
          ibminpres(i) = ibminpres@_FillValue
        end if
  end do  
end if

print("Generating wind copies for cutting by intensity")
maskwind = maxwind
ibmaskwind = ibmaxwind

if (windunits .eq. "kts") then
  cut_ts   = 34
  cut_cat1 = 64
  cut_cat2 = 83
  cut_cat3 = 96
  cut_cat4 = 114
  cut_cat5 = 135
else if (windunits .eq. "ms") then
  cut_ts   = 17
  cut_cat1 = 33
  cut_cat2 = 43
  cut_cat3 = 49
  cut_cat4 = 58
  cut_cat5 = 70
else
  print("invalid windunits")
end if
end if

print("Doing AMIP intensity binning")
do i = 0,numstorms-1
  if (.not.ismissing(maxwind(i)))
    if (maxwind(i) .lt. cut_ts*(1/factor))
      histogram(0) = histogram(0) + 1
    else if (maxwind(i) .ge. cut_ts*(1/factor)   .and. maxwind(i) .lt. cut_cat1*(1/factor))
      histogram(1) = histogram(1) + 1
    else if (maxwind(i) .ge. cut_cat1*(1/factor) .and. maxwind(i) .lt. cut_cat2*(1/factor))
      histogram(2) = histogram(2) + 1
    else if (maxwind(i) .ge. cut_cat2*(1/factor) .and. maxwind(i) .lt. cut_cat3*(1/factor))
      histogram(3) = histogram(3) + 1
    else if (maxwind(i) .ge. cut_cat3*(1/factor) .and. maxwind(i) .lt. cut_cat4*(1/factor))
      histogram(4) = histogram(4) + 1
    else if (maxwind(i) .ge. cut_cat4*(1/factor) .and. maxwind(i) .lt. cut_cat5*(1/factor))
      histogram(5) = histogram(5) + 1
    else
      histogram(6) = histogram(6) + 1
    end if
    end if
    end if
    end if
    end if
    end if
  end if
  if (.not.ismissing(maskwind(i)))
  if (maskwind(i) .lt. countCut*(1/factor))
    maskwind(i) = maskwind@_FillValue
  end if
  end if
end do

do i = 0,ibnumstorms-1
  if (ibyear(i) .ge. styear .and. ibyear(i) .le. enyear .and. .not.ismissing(ibmaskwind(i)))
    print("Storm name: "+ibname(i,:))
    if (ibmaxwind(i) .lt. cut_ts)
      ibhistogram(0) = ibhistogram(0) + 1
    else if (ibmaxwind(i) .ge. cut_ts   .and. ibmaxwind(i) .lt. cut_cat1)
      ibhistogram(1) = ibhistogram(1) + 1
    else if (ibmaxwind(i) .ge. cut_cat1 .and. ibmaxwind(i) .lt. cut_cat2)
      ibhistogram(2) = ibhistogram(2) + 1
    else if (ibmaxwind(i) .ge. cut_cat2 .and. ibmaxwind(i) .lt. cut_cat3)
      ibhistogram(3) = ibhistogram(3) + 1
    else if (ibmaxwind(i) .ge. cut_cat3 .and. ibmaxwind(i) .lt. cut_cat4)
      ibhistogram(4) = ibhistogram(4) + 1
    else if (ibmaxwind(i) .ge. cut_cat4 .and. ibmaxwind(i) .lt. cut_cat5)
      ibhistogram(5) = ibhistogram(5) + 1
    else
      ibhistogram(6) = ibhistogram(6) + 1
    end if
    end if
    end if
    end if
    end if
    end if
  end if
  if (.not.ismissing(ibmaskwind(i)))
  if (ibmaskwind(i) .lt. countCut)
    ibmaskwind(i) = ibmaskwind@_FillValue
  end if
  end if
end do

; Create year array
yearArray = ispan(1830,2011,1)
cutHisto = new(dimsizes(yearArray),integer)
cutHisto(:) = 0
cutHisto!0 = "time"
cutHisto&time = yearArray

; Create month array
monthArray = ispan(1,12,1)
monthHisto = new(dimsizes(monthArray),integer)
monthHisto(:) = 0
monthHisto!0 = "time"
monthHisto&time = monthArray

do i = 0,numstorms-1
  if (.not.ismissing(maskwind(i)))
    cutHisto({toint(year(i))}) = cutHisto({toint(year(i))}) + 1
    monthHisto({toint(month(i))}) = monthHisto({toint(month(i))}) + 1
  end if
end do

print("Do ibtracs analysis")

IBcutHisto = new(dimsizes(yearArray),integer)
IBcutHisto(:) = 0
IBcutHisto!0 = "time"
IBcutHisto&time = yearArray

IBmonthHisto = new(dimsizes(monthArray),integer)
IBmonthHisto(:) = 0
IBmonthHisto!0 = "time"
IBmonthHisto&time = monthArray

do i = 0,ibnumstorms-1
  if (ibyear(i) .ge. styear .and. ibyear(i) .le. enyear .and. .not.ismissing(ibmaskwind(i))) then
    IBcutHisto({toint(ibyear(i))}) = IBcutHisto({toint(ibyear(i))}) + 1
    IBmonthHisto({toint(ibmonth(i))}) = IBmonthHisto({toint(ibmonth(i))}) + 1
  end if
end do

;print(IBcutHisto)

cumHistoNorm = tofloat(histogram+.1)/tofloat(numyears)
ibcumHistoNorm = tofloat(ibhistogram+.1)/tofloat(numyears)

print(IBmonthHisto)
print(monthHisto)


print("Ib sum: "+sum(IBcutHisto))
print("CAM sum: "+sum(cutHisto))

; ====== calc el nino stats

elninoyrs = (/1982,1986,1987,1991,1994,1997,2002/)
laninayrs = (/1983,1984,1985,1988,1995,1998,2000/)
neutrayrs = (/1980,1981,1989,1990,1992,1993,1996,1999,2001/)

numelnino = dimsizes(elninoyrs)
numlanina = dimsizes(laninayrs)
numneutra = dimsizes(neutrayrs)

elninoArr = new((/2,numelnino/),"integer")
laninaArr = new((/2,numlanina/),"integer")
neutraArr = new((/2,numneutra/),"integer")

do i = 0,numelnino-1
  elninoArr(0,i) = cutHisto({elninoyrs(i)})
  elninoArr(1,i) = IBcutHisto({elninoyrs(i)})
end do
do i = 0,numlanina-1
  laninaArr(0,i) = cutHisto({laninayrs(i)})
  laninaArr(1,i) = IBcutHisto({laninayrs(i)})
end do
do i = 0,numneutra-1
  neutraArr(0,i) = cutHisto({neutrayrs(i)})
  neutraArr(1,i) = IBcutHisto({neutrayrs(i)})
end do

;print(elninoArr)
elninoAvg = dim_avg_n_Wrap(elninoArr,1)
laninaAvg = dim_avg_n_Wrap(laninaArr,1)
neutraAvg = dim_avg_n_Wrap(neutraArr,1)

print(laninaAvg)
print(neutraAvg)
print(elninoAvg)


  wks = gsn_open_wks("pdf","yeartimeseries")

  res               = True 
  res@gsnMaximize   = True
  res@tiMainString  = "Annual Atlantic TC Count"        ; title
  res@tiYAxisString = "Observed TCs"     ; y axis title
  res@tiXAxisString = "YEAR"    ; y axis title
  res@trXMinF = 1980
  res@trXMaxF = 2002

  res@xyLineThicknessF = 5.0
  res@xyLineColor      ="blue"
  res@xyDashPattern = 0
  ;res@xyMarkLineMode = "MarkLines"
  ;res@xyMarker     = 16
  ;res@xyMarkerColor = res@xyLineColor
  
  res@trYMinF = 0
  res@trYMaxF = max(IBcutHisto)
  
  res2 = res
  res2@tiYAxisString = "Simulated CAM-SE TCs"     ; y axis title
  res2@xyLineThicknessF = 5.0
  res2@xyLineColor      ="red"
  res2@xyDashPattern = 0
  ;res2@xyMarkLineMode = "MarkLines"
  ;res2@xyMarker     = 16
  res2@trYMinF = 0
  res2@trYMaxF = max(IBcutHisto)
  plot = gsn_csm_xy2(wks,yearArray,IBcutHisto,cutHisto,res,res2)
  
  delete(res)
  delete(res2)
  
  wks = gsn_open_wks("x11","montimseries")

  res               = True 
  res@gsnMaximize   = True
  res@tiMainString  = "Annual Atlantic TC Count"        ; title
  res@tiYAxisString = "Observed TCs"     ; y axis title
  res@tiXAxisString = "month"    ; y axis title
  res@trXMinF = 1
  res@trXMaxF = 12

  res@xyLineThicknessF = 5.0
  res@xyLineColor      ="blue"
  res@xyDashPattern = 0
  ;res@xyMarkLineMode = "MarkLines"
  ;res@xyMarker     = 16
  ;res@xyMarkerColor = res@xyLineColor
  
  res@trYMinF = 0
  res@trYMaxF = max(IBmonthHisto)
  
  res2 = res
  res2@tiYAxisString = "Simulated CAM-SE TCs"     ; y axis title
  res2@xyLineThicknessF = 5.0
  res2@xyLineColor      ="red"
  res2@xyDashPattern = 0
  ;res2@xyMarkLineMode = "MarkLines"
  ;res2@xyMarker     = 16
  res2@trYMinF = 0
  res2@trYMaxF = max(IBmonthHisto)
  plot = gsn_csm_xy2(wks,monthArray,IBmonthHisto,monthHisto,res,res2)
  
  delete(res)
  delete(res2)
  







labels = (/"TD","TS","Cat 1","Cat 2","Cat 3","Cat 4","Cat 5"/)

 wks = gsn_open_wks("pdf","intensityHisto_basin"+maskbasin)                  ; open ps file
 
;---Set resources common to both plots
  res                       = True                 ; plot mods desired         
  res@gsnFrame              = False
  ;res@gsnDraw               = False

;  res@trXMinF               = 0.0
;  res@trXMaxF               = max(barX)+.5 
  res@trYMinF               = 0.0    ; set to same for both plots
                                     ; we'll let ncl set the max Y
  res@trYMaxF               = max(cumHistoNorm)    ; set to same for both plots
                                     ; we'll let ncl set the max Y
                                     
  res@tmXBOn              = False
  res@tmXTOn              = False
  ;res@tmYLOn              = False
  res@tmYROn              = False
  res@tmYRLabelsOn        = False
                                      
   barres                       = res                 ; plot mods desired         
   barres@gsnFrame              = False                ; don't advance frame yet
   barres@gsnXYBarChart         = True                 ; turn on bar chart
;   res@gsnXYBarChartBarWidth = 0.75                 ; change bar widths
;   barres@gsnXYBarChartColors = barcolors          ; choose colors
  barres@gsnXYBarChartColors = (/"blue","green","yellow","orange", \
  "darkorange3","red","red4"/)    
   
   barres@tmXBOn                = False                ; turn off tickmarks at bot
   
   barres@tiMainString          = "Average TC intensity profile"
   barres@tiYAxisString          = "Number of TCs per year"
 
   bar_plot = gsn_csm_xy (wks,histogramInd,cumHistoNorm,barres)                  ; create plot
   
;
; The default behavior of gsn_add_annotation is is to add one 


;
; "maximize_output" will resize graphics to maximize them
; on the page. This is necessary so that right Y axis
; labels don't run off the page.
;

;**********************************************************
; add labelbar to second plot
;********************************************************** 
;---Get viewport values for bar plot
   getvalues bar_plot
     "vpXF"      : vpx
     "vpYF"      : vpy
     "vpWidthF"  : vpw
     "vpHeightF" : vph
   end getvalues

  lbw    = 0.4 * vpw           ; Make labelbar size a fraction of the plot.
  lbh    = 0.5 * vph
  nboxes = dimsizes(barres@gsnXYBarChartColors)
   
  lbres                    = True          ; labelbar only resources
  lbres@vpWidthF           = 0.4 * vpw     ; labelbar width
  lbres@vpHeightF          = 0.5 * vph     ; labelbar height
  lbres@lbBoxMajorExtentF  = 0.75          ; puts space between color boxes
  lbres@lbFillColors       = barres@gsnXYBarChartColors ; labelbar colors
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
  lbres@lbLabelFontHeightF = 0.02          ; font height. default is small
  lbres@lbLabelJust        = "CenterLeft"  ; left justify labels
   
  gsn_labelbar_ndc(wks,nboxes,labels,vpx+vph-lbw,0.77,lbres)
   
  frame(wks)

  
  ;pres             = True
  ;pres@gsnMaximize = True
  ;maximize_output(wks,pres)

end
