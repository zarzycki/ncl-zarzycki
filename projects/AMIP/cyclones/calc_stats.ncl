;========================================================
; Reads in a trajectory data file and calculates hurricane days
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "calc_area.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================
begin

;---------------User settings----------------------------

cam_version = "1deg" ; 1 deg or vr
windunits = "ms" ; options are "kts" and "ms"
; Select the wind correction factor. Valid options are "power" "log" and "none"
wind_factor = "log"
; Trajectory file output from tracker
traj_dir = "/glade/u/home/zarzycki/tcstats/"
traj_filename = "traj_"+cam_version
; Origin/max intensity file (output from C++ script)
orimax_dir =""
orimax_file = ""
ori_filename = "/glade/u/home/zarzycki/tcstats/ori_"+cam_version+".txt"
; iBTracs data
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"
out_type = "x11"
; Do we want to normalize tracked storms by average observed?
correct_average=False
do_plot=True
maxtrackerlat = 45.0
rest_of_globe = True ; Calculate global sums as non ATL non EPAC sum


domask = 0 ; 0 = true, 1 = false
;maskbasin = 1
maskspacing = 2
countCutArray = (/0.0,33.0,50.0/)
countCutNames = (/"storms","hurr","majhurr"/)

howmanybasins=8
styr = 1980
enyr = 2002

;Constants
ms_to_kts = 1.94384449
ocn_basins = (/"natl","epac","cpac","wpac","nio","sio","spac","satl","glob"/)
ocn_basins_fullname = (/"N. Atlantic","E. Pacific","C. Pacific","W. Pacific","N. Indian","S. Indian","S. Pacific","S. Atlantic","Global"/)
numyears = enyr-styr+1
time = ispan(styr,enyr,1)

storetcdays = new((/2,howmanybasins+1,numyears/),"float")
storehurrdays = new((/2,howmanybasins+1,numyears/),"float")
storemajhurrdays = new((/2,howmanybasins+1,numyears/),"float")
ACEperyear = new((/2,howmanybasins+1,numyears/),"float")

print("Getting TC masks")
  tcMask = mask_tc(0,-999,-999,maskspacing,360)
;  printVarSummary(tcMask)
  tcMaskIB = mask_tc(0,-999,-999,maskspacing,180)
;  printVarSummary(tcMaskIB)
print("Done getting TC masks")
print("------------------------------------------------")
  
; Wind speed power relation
if (wind_factor .eq. "power") then
  z_10 = 10.
  z_r = 65.
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


print("Reading all data into memory")
print("------------------------------------------------")

print("Read in TC locations from CAM")
traj_cleanfile = "traj_filt_clean.TMP" ; hardcoded temp file name, feel free to change
print("Removing text headers from trajectories")
system("grep -v '^start' "+ traj_dir+traj_filename +" > "+traj_cleanfile+"")

traj_ncols = numAsciiCol(traj_cleanfile)
traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
print("'" + traj_filename + "' has " + traj_nrows + " rows and " + traj_ncols + \
    " columns of data.")
print("Removing temporary file:"+traj_cleanfile)
system("rm -rf "+traj_cleanfile)

;(0)	291.75 lon
;(1)	34.75 lat
;(2)	31.85 wind
;(3)	986.89 pres
;(4)	1980 year
;(5)	 1 mon
;(6)	23 day
;(7)	12 hour
; wind is column 2, pressure is column 3

ori_ncols = numAsciiCol(ori_filename)
; Given the # of columns, we can use readAsciiTable to read this file.
ori_data = readAsciiTable(ori_filename,ori_ncols,"float",0)
ori_nrows = dimsizes(ori_data(:,0))    ; calculate # of rows
print("'" + ori_filename + "' has " + ori_nrows + " rows and " + ori_ncols + \
        " columns of data.")
stormid = ori_data(:,0)
year = ori_data(:,1)
month = ori_data(:,2)
day = ori_data(:,3)
hour = ori_data(:,4)
startlat = ori_data(:,5)
startlon = ori_data(:,6)
if (windunits .eq. "kts") then
  maxwind = ori_data(:,7)*ms_to_kts
else if (windunits .eq. "ms") then
  maxwind = ori_data(:,7)
else
  print("invalid windunits")
  exit()
end if
end if
minpres = ori_data(:,8)
;pathlength = ori_data(:,9)
numyears = toint(max(year) - min(year) + 1)
styear = toint(min(year))
enyear = toint(max(year))
numstorms = toint(max(stormid))

print("Get ibTracs data")

ibfile = addfile(ibdir+ibfilename,"r")
iblat = ibfile->lat_for_mapping*.01
iblon = ibfile->lon_for_mapping*.01
ibdimsizes = dimsizes(iblat)
ibnumstorms = ibdimsizes(0)
ibtype = toint(ibfile->nature_for_mapping)
ibsourcedate = ibfile->source_time(:,0)
ibdate = ut_calendar(ibsourcedate,0)
;ibyear = toint(ibfile->season)
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


  
; Quick fix for lons that go outside the tcMask
iblon(:,0) = where(iblon(:,0).gt.180.0-maskspacing,180.0-maskspacing,iblon(:,0))
traj_data(:,0) = where(traj_data(:,0).gt.360.-maskspacing,360.-maskspacing,traj_data(:,0)) 

;=========================================================================================

print("Doing histogram statistics")



do cutnumber = 0,dimsizes(countCutArray)-1

countCut = countCutArray(cutnumber)
countName = countCutNames(cutnumber)

; First we'll do intensity
histogramInd = ispan(0,6,1)
histogram = new((/howmanybasins+1,dimsizes(histogramInd)/),integer)
histogram(:,:) = 0
ibhistogram = histogram

; Create year array
yearArray = ispan(1830,2011,1)
cutHisto = new((/howmanybasins+1,dimsizes(yearArray)/),integer)
cutHisto(:,:) = 0
cutHisto!1 = "time"
cutHisto&time = yearArray

; Create month array
monthArray = ispan(1,12,1)
monthHisto = new((/howmanybasins+1,dimsizes(monthArray)/),integer)
monthHisto(:,:) = 0
monthHisto!1 = "time"
monthHisto&time = monthArray

IBcutHisto = new((/howmanybasins+1,dimsizes(yearArray)/),integer)
IBcutHisto(:,:) = 0
IBcutHisto!1 = "time"
IBcutHisto&time = yearArray

IBmonthHisto = new((/howmanybasins+1,dimsizes(monthArray)/),integer)
IBmonthHisto(:,:) = 0
IBmonthHisto!1 = "time"
IBmonthHisto&time = monthArray



do maskbasin=1,howmanybasins

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

maxwindbasin = maxwind
minpresbasin = minpres
ibmaxwindbasin = ibmaxwind
ibminpresbasin = ibminpres

print("Masking out basins")

  do i = 0,numstorms-1
        if (tcMask({startlat(i)},{startlon(i)}) .ne. maskbasin)
          maxwindbasin(i) = maxwindbasin@_FillValue
          minpresbasin(i) = minpresbasin@_FillValue
        end if
  end do
  do i = 0,ibnumstorms-1
        if (tcMaskIB({iblat(i,0)},{iblon(i,0)}) .ne. maskbasin)
          ibmaxwindbasin(i) = ibmaxwindbasin@_FillValue
          ibminpresbasin(i) = ibminpresbasin@_FillValue
        end if
  end do  

print("Generating wind copies for cutting by intensity")
maskwind = maxwindbasin
ibmaskwind = ibmaxwindbasin

print("Doing AMIP intensity binning")
do i = 0,numstorms-1
  if (.not.ismissing(maxwindbasin(i)))
    if (maxwindbasin(i) .lt. cut_ts*(1/factor))
      histogram(maskbasin-1,0) = histogram(maskbasin-1,0) + 1
    else if (maxwindbasin(i) .ge. cut_ts*(1/factor)   .and. maxwindbasin(i) .lt. cut_cat1*(1/factor))
      histogram(maskbasin-1,1) = histogram(maskbasin-1,1) + 1
    else if (maxwindbasin(i) .ge. cut_cat1*(1/factor) .and. maxwindbasin(i) .lt. cut_cat2*(1/factor))
      histogram(maskbasin-1,2) = histogram(maskbasin-1,2) + 1
    else if (maxwindbasin(i) .ge. cut_cat2*(1/factor) .and. maxwindbasin(i) .lt. cut_cat3*(1/factor))
      histogram(maskbasin-1,3) = histogram(maskbasin-1,3) + 1
    else if (maxwindbasin(i) .ge. cut_cat3*(1/factor) .and. maxwindbasin(i) .lt. cut_cat4*(1/factor))
      histogram(maskbasin-1,4) = histogram(maskbasin-1,4) + 1
    else if (maxwindbasin(i) .ge. cut_cat4*(1/factor) .and. maxwindbasin(i) .lt. cut_cat5*(1/factor))
      histogram(maskbasin-1,5) = histogram(maskbasin-1,5) + 1
    else
      histogram(maskbasin-1,6) = histogram(maskbasin-1,6) + 1
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
    ;print("Storm name: "+ibname(i,:))
    if (ibmaxwindbasin(i) .lt. cut_ts)
      ibhistogram(maskbasin-1,0) = ibhistogram(maskbasin-1,0) + 1
    else if (ibmaxwindbasin(i) .ge. cut_ts   .and. ibmaxwindbasin(i) .lt. cut_cat1)
      ibhistogram(maskbasin-1,1) = ibhistogram(maskbasin-1,1) + 1
    else if (ibmaxwindbasin(i) .ge. cut_cat1 .and. ibmaxwindbasin(i) .lt. cut_cat2)
      ibhistogram(maskbasin-1,2) = ibhistogram(maskbasin-1,2) + 1
    else if (ibmaxwindbasin(i) .ge. cut_cat2 .and. ibmaxwindbasin(i) .lt. cut_cat3)
      ibhistogram(maskbasin-1,3) = ibhistogram(maskbasin-1,3) + 1
    else if (ibmaxwindbasin(i) .ge. cut_cat3 .and. ibmaxwindbasin(i) .lt. cut_cat4)
      ibhistogram(maskbasin-1,4) = ibhistogram(maskbasin-1,4) + 1
    else if (ibmaxwindbasin(i) .ge. cut_cat4 .and. ibmaxwindbasin(i) .lt. cut_cat5)
      ibhistogram(maskbasin-1,5) = ibhistogram(maskbasin-1,5) + 1
    else
      ibhistogram(maskbasin-1,6) = ibhistogram(maskbasin-1,6) + 1
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
  
do i = 0,numstorms-1
  if (.not.ismissing(maskwind(i)))
    cutHisto(maskbasin-1,{toint(year(i))}) = cutHisto(maskbasin-1,{toint(year(i))}) + 1
    monthHisto(maskbasin-1,{toint(month(i))}) = monthHisto(maskbasin-1,{toint(month(i))}) + 1
  end if
end do

do i = 0,ibnumstorms-1
  if (ibyear(i) .ge. styear .and. ibyear(i) .le. enyear .and. .not.ismissing(ibmaskwind(i))) then
    IBcutHisto(maskbasin-1,{toint(ibyear(i))}) = IBcutHisto(maskbasin-1,{toint(ibyear(i))}) + 1
    IBmonthHisto(maskbasin-1,{toint(ibmonth(i))}) = IBmonthHisto(maskbasin-1,{toint(ibmonth(i))}) + 1
  end if
end do

cumHistoNorm = tofloat(histogram+.1)/tofloat(numyears)
ibcumHistoNorm = tofloat(ibhistogram+.1)/tofloat(numyears)

print("Running ib sum: "+sum(IBcutHisto))
print("Running CAM sum: "+sum(cutHisto))

delete(ibmaskwind)
delete(maskwind)
delete(ibmaxwindbasin)
delete(maxwindbasin)
delete(ibminpresbasin)
delete(minpresbasin)
delete(ibpres_)
delete(ibwind_)

end do

;print(IBcutHisto(:,{styr:enyr}))

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
  elninoArr(0,i) = cutHisto(0,{elninoyrs(i)})
  elninoArr(1,i) = IBcutHisto(0,{elninoyrs(i)})
end do
do i = 0,numlanina-1
  laninaArr(0,i) = cutHisto(0,{laninayrs(i)})
  laninaArr(1,i) = IBcutHisto(0,{laninayrs(i)})
end do
do i = 0,numneutra-1
  neutraArr(0,i) = cutHisto(0,{neutrayrs(i)})
  neutraArr(1,i) = IBcutHisto(0,{neutrayrs(i)})
end do

;print(elninoArr)
elninoAvg = dim_avg_n_Wrap(elninoArr,1)
laninaAvg = dim_avg_n_Wrap(laninaArr,1)
neutraAvg = dim_avg_n_Wrap(neutraArr,1)

print(elninoAvg)
print(neutraAvg)
print(laninaAvg)

write_table("enso_bar_"+countName+".txt","w",[/elninoAvg(:),neutraAvg(:),laninaAvg(:)/],"%f,%f,%f")

print("Calculating global sums")
if (rest_of_globe) then
  cutHisto(howmanybasins,{styr:enyr}) = dim_sum_n_Wrap(cutHisto(2:7,{styr:enyr}),0)
  IBcutHisto(howmanybasins,{styr:enyr}) = dim_sum_n_Wrap(IBcutHisto(2:7,{styr:enyr}),0)
  cumHistoNorm(howmanybasins,:) = dim_sum_n_Wrap(cumHistoNorm(2:7,:),0)
  ibcumHistoNorm(howmanybasins,:) = dim_sum_n_Wrap(ibcumHistoNorm(2:7,:),0)
  IBmonthHisto(howmanybasins,:) = dim_sum_n_Wrap(IBmonthHisto(2:7,:),0)
  monthHisto(howmanybasins,:) = dim_sum_n_Wrap(monthHisto(2:7,:),0)
else
  cutHisto(howmanybasins,{styr:enyr}) = dim_sum_n_Wrap(cutHisto(0:howmanybasins-1,{styr:enyr}),0)
  IBcutHisto(howmanybasins,{styr:enyr}) = dim_sum_n_Wrap(IBcutHisto(0:howmanybasins-1,{styr:enyr}),0)
  cumHistoNorm(howmanybasins,:) = dim_sum_n_Wrap(cumHistoNorm(0:howmanybasins-1,:),0)
  ibcumHistoNorm(howmanybasins,:) = dim_sum_n_Wrap(ibcumHistoNorm(0:howmanybasins-1,:),0)
  IBmonthHisto(howmanybasins,:) = dim_sum_n_Wrap(IBmonthHisto(0:howmanybasins-1,:),0)
  monthHisto(howmanybasins,:) = dim_sum_n_Wrap(monthHisto(0:howmanybasins-1,:),0)
end if

textfile="stats/stats_tcs_by_year_"+countName+"_"+cam_version+".txt"
write_table(textfile,"w",[/ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s,%s,%s,%s,%s,%s,%s,%s,%s")
write_table(textfile,"a",[/"cam"/],"%s")
write_table(textfile,"a",[/cutHisto(0,{styr:enyr}),cutHisto(1,{styr:enyr}),cutHisto(2,{styr:enyr}),cutHisto(3,{styr:enyr}),cutHisto(4,{styr:enyr}),cutHisto(5,{styr:enyr}),cutHisto(6,{styr:enyr}),cutHisto(7,{styr:enyr}),cutHisto(8,{styr:enyr})/], \
      "%d,%d,%d,%d,%d,%d,%d,%d,%d")
write_table(textfile,"a",[/"ibtracs"/],"%s")
write_table(textfile,"a",[/IBcutHisto(0,{styr:enyr}),IBcutHisto(1,{styr:enyr}),IBcutHisto(2,{styr:enyr}),IBcutHisto(3,{styr:enyr}),IBcutHisto(4,{styr:enyr}),IBcutHisto(5,{styr:enyr}),IBcutHisto(6,{styr:enyr}),IBcutHisto(7,{styr:enyr}),IBcutHisto(8,{styr:enyr})/], \
      "%d,%d,%d,%d,%d,%d,%d,%d,%d")

textfile="stats/stats_tcs_by_month_"+countName+"_"+cam_version+".txt" 
write_table(textfile,"w",[/ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s,%s,%s,%s,%s,%s,%s,%s,%s")
write_table(textfile,"a",[/"cam"/],"%s")
write_table(textfile,"a",[/monthHisto(0,:),monthHisto(1,:),monthHisto(2,:),monthHisto(3,:),monthHisto(4,:),monthHisto(5,:),monthHisto(6,:),monthHisto(7,:),monthHisto(8,:)/], \
      "%d,%d,%d,%d,%d,%d,%d,%d,%d")
write_table(textfile,"a",[/"ibtracs"/],"%s")
write_table(textfile,"a",[/IBmonthHisto(0,:),IBmonthHisto(1,:),IBmonthHisto(2,:),IBmonthHisto(3,:),IBmonthHisto(4,:),IBmonthHisto(5,:),IBmonthHisto(6,:),IBmonthHisto(7,:),IBmonthHisto(8,:)/], \
      "%d,%d,%d,%d,%d,%d,%d,%d,%d")

if (do_plot) then
  ;============================================================================
  ; Do histograms
  ;============================================================================
  labels = (/"TD","TS","Cat 1","Cat 2","Cat 3","Cat 4","Cat 5"/)
  namestring = (/"ibtracs","cam_vr"/)
  titlestring = (/"IBTrACS","CAM-SE VR"/)
  
  maskbasin = 1
  do maskbasin = 1,howmanybasins+1
  do i = 0,1 ; ibtracs/cam loop
  
  wks = gsn_open_wks("pdf","pdf/intensityHisto_"+namestring(i)+"_basin_"+ocn_basins(maskbasin-1))
  
  ;---Set resources common to both plots
  res                       = True                 ; plot mods desired         
  res@gsnFrame              = False
  res@gsnDraw               = False
  
  res@trYMinF               = 0.0
  maxcam = max(cumHistoNorm(maskbasin-1,:))
  maxib = max(ibcumHistoNorm(maskbasin-1,:))
  
  if (maskbasin .eq. howmanybasins+1)
    if (i .eq. 0) then
      res@trYMaxF = maxib + 0.5
    else if (i .eq. 1) then
      res@trYMaxF = maxcam + 0.5
    else
      ;res@trYMaxF = max((/maxcam,maxib/)) + 0.5
    end if
    end if
  else
    res@trYMaxF = max((/maxcam,maxib/)) + 0.5
  end if
  
; This block of code was added for the JAMES paper to standardize the
; y-axis in the plots for Fig 6. Can be removed if you want to go back to
; basin/model specific y-axis to better plot data

  yAxisMax = 7.25
  if (i .eq. 0 .and. maskbasin .eq. 1) then
    res@trYMaxF = yAxisMax
  else if (i .eq. 0 .and. maskbasin .eq. 2) then
    res@trYMaxF = yAxisMax
  else if (i .eq. 0 .and. maskbasin .eq. howmanybasins+1) then
    res@trYMaxF = 35
  else if (i .eq. 1 .and. maskbasin .eq. 1) then
    res@trYMaxF = yAxisMax
  else if (i .eq. 1 .and. maskbasin .eq. 2) then
    res@trYMaxF = yAxisMax
  else if (i .eq. 1 .and. maskbasin .eq. howmanybasins+1) then
    res@trYMaxF = yAxisMax
  else
    print("We aren't correcting the min specified earlier")
  end if
  end if
  end if
  end if
  end if
  end if

; END
  

                                     
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
  
  barres@tiMainString          = titlestring(i)+": "+ocn_basins_fullname(maskbasin-1)
  barres@tiYAxisString          = "Number of TCs per year"
  
  if (i .eq. 0) then
    bar_plot = gsn_csm_xy (wks,histogramInd,ibcumHistoNorm(maskbasin-1,:),barres)
  else if (i .eq. 1) then
    bar_plot = gsn_csm_xy (wks,histogramInd,cumHistoNorm(maskbasin-1,:),barres)
  else
  end if
  end if
  
  ; add labelbar
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
   
  gsn_labelbar_ndc(wks,nboxes,labels,vpx+vph-lbw+0.14,0.85,lbres)
   
  ;frame(wks)
  
  resP = True
  resP@amJust           = "TopLeft"
  print(maskbasin+" "+ocn_basins_fullname(maskbasin-1))
  ; i = 0 ibtracs, i = 1, cam-se
  ; maskbasin = 1 atl, = 2 epac, = howmanybasins glob
  if (i .eq. 0 .and. maskbasin .eq. 1) then
    resP@gsnPanelFigureStrings= (/"d."/)
  else if (i .eq. 0 .and. maskbasin .eq. 2) then
    resP@gsnPanelFigureStrings= (/"e."/)
  else if (i .eq. 0 .and. maskbasin .eq. howmanybasins+1) then
    resP@gsnPanelFigureStrings= (/"f."/)
  else if (i .eq. 1 .and. maskbasin .eq. 1) then
    resP@gsnPanelFigureStrings= (/"a."/)
  else if (i .eq. 1 .and. maskbasin .eq. 2) then
    resP@gsnPanelFigureStrings= (/"b."/)
  else if (i .eq. 1 .and. maskbasin .eq. howmanybasins+1) then
    resP@gsnPanelFigureStrings= (/"c."/)
  else
    resP@gsnPanelFigureStrings= (/"X."/)
  end if
  end if
  end if
  end if
  end if
  end if

  resP@gsnPanelFigureStringsFontHeightF = 0.035
  gsn_panel(wks,bar_plot,(/1,1/),resP)             ; now draw as one plot
  delete(lbres)
  delete(res)
  delete(wks)
  delete(nboxes)
  delete(barres)
  delete(bar_plot)
  delete(resP)
  
  end do
  end do

end if
      
delete([/histogramInd,histogram,ibhistogram/])
delete([/yearArray,cutHisto/])
delete([/monthArray,monthHisto/])
delete([/IBcutHisto/])
delete([/IBmonthHisto/])
      
end do
      
      
;=======================================================


do basin = 1,howmanybasins
  print("Doing basin number "+basin)
  

  
  print("Processing data from our tracker")
  do n = styr,enyr
      print("Doing tracker year "+n)
      cycwindarr = traj_data(:,2)*factor
      cycpresarr = traj_data(:,3)
    do i = 0,traj_nrows-1
      cyclon = traj_data(i,0)
      cyclat = traj_data(i,1)
      cycyear = traj_data(i,4)
    ;  if (tcMask({cyclat},{cyclon}) .ne. basin)
      if (cycyear .eq. n .and. tcMask({cyclat},{cyclon}) .eq. basin) then
        ; do nothing
      else
        ; If not in basin or year, replace with missing values
        cycwindarr(i) = -999
        cycpresarr(i) = -999
      end if
    end do
    
    delete(i)
  
    ;traj_data(:,2) = where(traj_data(:,2).lt.17.5,traj_data(:,2),-999)
    ;print(num(traj_data(:,2) .gt. 33.))
    ACE = sum((where(cycwindarr.ge.17.0,cycwindarr,0.0)*ms_to_kts)^2)
    TCdaysperyear = num(cycwindarr .ge. 17.)*.25
    Hurrdaysperyear = num(cycwindarr .ge. 33.)*.25
    MajHurrdaysperyear= num(cycwindarr .ge. 50.)*.25
    
    delete(cycwindarr)
    delete(cycpresarr)
    
    ACEperyear(0,basin-1,n-styr) = ACE
    storetcdays(0,basin-1,n-styr) = TCdaysperyear
    storehurrdays(0,basin-1,n-styr) = Hurrdaysperyear
    storemajhurrdays(0,basin-1,n-styr) = MajHurrdaysperyear
    
    delete(ACE)
    delete(TCdaysperyear)
    delete(Hurrdaysperyear)
    delete(MajHurrdaysperyear)
  
  end do
  
  delete(n)
  
  
  ;print(traj_data(:,2))
  ; Do a search for number of values in this thing that are > TS, then > Hurr then > Cat 3
  ; then multiple counts by .25 because they are each 6-hour increments
  
  ;--------------------------------------------------------
  
  print("processing ibTracs data")
  
  center = -999
  if (basin .eq. 1) then
    center = 0
  else if (basin .eq. 2) then
    center = 14 ; hurdat_epac
  end if
  end if
  
  if (center .ge. 0) then
    print("We are only using center number "+center+" from ibTracs data")
  else
    print("We are using all centers available for a particular storm. Use with CAUTION")
  end if
  print("------------------------------------------------")
  
  ;--------------------------------------------------------
  
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
  
  
  
  print("processing ibTracs data")

  do n = styr,enyr
    print("Doing ibTracs year "+n)
    ibpresyr = ibpres_
    ibwindyr = ibwind_
    
    do i = 0,ibnumstorms-1
    ;do j = 0,190
      ;print("Lon is: "+iblon(i,0))
      if (ibyear(i) .eq. n .and. tcMaskIB({iblat(i,0)},{iblon(i,0)}) .eq. basin ) then
      ;.and. abs(iblat(i,0)) .le. maxtrackerlat 
      ;if (ibyear(i) .ge. styr .and. ibyear(i) .le. enyr .and. tcMaskIB({iblat(i,0)},{iblon(i,0)}) .eq. basin) then
        ;print("Were in the basin with lat "+iblat(i,0)+" lon "+iblon(i,0))
        ;print(ibpres(i,:))
      ;if (ibyear(i) .ge. 1980 .and. ibyear(i) .le. 2002) then
      else
        ibpresyr(i,:) = ibpresyr@_FillValue
        ibwindyr(i,:) = ibwindyr@_FillValue
      end if
    ;end do
    end do
    
    delete(i)

    onedpres = ndtooned(ibpresyr)
    onedwind = ndtooned(ibwindyr)
    onedtype = ndtooned(ibtype)
    
    onedwind = where(onedtype.eq.0,onedwind,onedwind@_FillValue)
    onedpres = where(onedtype.eq.0,onedpres,onedpres@_FillValue)
    
    delete(ibpresyr)
    delete(ibwindyr)
    
    TCdaysperyear = num(onedwind .ge. 17.)*.25
    Hurrdaysperyear = num(onedwind .ge. 33.)*.25
    MajHurrdaysperyear= num(onedwind .ge. 50.)*.25
    ACE = sum((where(onedwind.ge.17.0,onedwind,0.0)*ms_to_kts)^2)
    
    delete(onedwind)
    delete(onedpres)
    
    ACEperyear(1,basin-1,n-styr) = ACE
    storetcdays(1,basin-1,n-styr) = TCdaysperyear
    storehurrdays(1,basin-1,n-styr) = Hurrdaysperyear
    storemajhurrdays(1,basin-1,n-styr) = MajHurrdaysperyear
    
    delete(ACE)
    delete(TCdaysperyear)
    delete(Hurrdaysperyear)
    delete(MajHurrdaysperyear)
 
 
  end do
  
      delete(n)
  
    delete(ibpres_)
    delete(ibwind_)

  ;list_vars()
  
  ; ONLY USE THIS CODE IF YOU NEED TO PRINT MASK
  ;   wks = gsn_open_wks("x11","tc_mask")
  ;   res                      = True
  ;   res@gsnMaximize          = True
  ;   res@cnFillOn             = True
  ;   res@cnLinesOn            = False
  ;   res@cnLineLabelsOn       = False
  ;   res@gsnAddCyclic = False
  ;   plot = gsn_csm_contour_map(wks,tcMaskIB,res)
  
  print("-----------------------------------------------")

end do

; Correct ACE by scalingfactor
ACEperyear=ACEperyear*10^(-4)

if (correct_average) then
  print("we are correcting averages")
  print("Ratio = "+(avg(ACEperyear(1,:,:))/avg(ACEperyear(0,:,:))))
  ratio = (avg(ACEperyear(1,:,:))/avg(ACEperyear(0,:,:)))
  ACEperyear(0,:,:) = ACEperyear(0,:,:) * ratio
end if

print("Calculating global sums")
if (rest_of_globe) then
  ACEperyear(:,howmanybasins,:) = dim_sum_n_Wrap(ACEperyear(:,2:7,:),1)
  storetcdays(:,howmanybasins,:) = dim_sum_n_Wrap(storetcdays(:,2:7,:),1)
  storehurrdays(:,howmanybasins,:) = dim_sum_n_Wrap(storehurrdays(:,2:7,:),1)
  storemajhurrdays(:,howmanybasins,:) = dim_sum_n_Wrap(storemajhurrdays(:,2:7,:),1)
else
  ACEperyear(:,howmanybasins,:) = dim_sum_n_Wrap(ACEperyear(:,0:howmanybasins-1,:),1)
  storetcdays(:,howmanybasins,:) = dim_sum_n_Wrap(storetcdays(:,0:howmanybasins-1,:),1)
  storehurrdays(:,howmanybasins,:) = dim_sum_n_Wrap(storehurrdays(:,0:howmanybasins-1,:),1)
  storemajhurrdays(:,howmanybasins,:) = dim_sum_n_Wrap(storemajhurrdays(:,0:howmanybasins-1,:),1)
end if

avgTCdays = dim_avg_n_Wrap(storetcdays,2)
stdevTCdays = dim_stddev_n_Wrap(storetcdays,2)
avghurrdays = dim_avg_n_Wrap(storehurrdays,2)
stdevhurrdays = dim_stddev_n_Wrap(storehurrdays,2)
avgmajhurrdays = dim_avg_n_Wrap(storemajhurrdays,2)
stdevmajhurrdays = dim_stddev_n_Wrap(storemajhurrdays,2)
avgACE = dim_avg_n_Wrap(ACEperyear,2)
stdevACE = dim_stddev_n_Wrap(ACEperyear,2)

textfile="stats/stats_ace_by_year_"+cam_version+".txt"
write_table(textfile,"w",[/ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s,%s,%s,%s,%s,%s,%s,%s,%s")
write_table(textfile,"a",[/"cam"/],"%s")
write_table(textfile,"a",[/ACEperyear(0,0,:),ACEperyear(0,1,:),ACEperyear(0,2,:),ACEperyear(0,3,:),ACEperyear(0,4,:),ACEperyear(0,5,:),ACEperyear(0,6,:),ACEperyear(0,7,:),ACEperyear(0,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
write_table(textfile,"a",[/"ibtracs"/],"%s")
write_table(textfile,"a",[/ACEperyear(1,0,:),ACEperyear(1,1,:),ACEperyear(1,2,:),ACEperyear(1,3,:),ACEperyear(1,4,:),ACEperyear(1,5,:),ACEperyear(1,6,:),ACEperyear(1,7,:),ACEperyear(1,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
      
textfile="stats/stats_tcdays_by_year_"+cam_version+".txt"
write_table(textfile,"w",[/ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s,%s,%s,%s,%s,%s,%s,%s,%s")
write_table(textfile,"a",[/"cam"/],"%s")
write_table(textfile,"a",[/storetcdays(0,0,:),storetcdays(0,1,:),storetcdays(0,2,:),storetcdays(0,3,:),storetcdays(0,4,:),storetcdays(0,5,:),storetcdays(0,6,:),storetcdays(0,7,:),storetcdays(0,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
write_table(textfile,"a",[/"ibtracs"/],"%s")
write_table(textfile,"a",[/storetcdays(1,0,:),storetcdays(1,1,:),storetcdays(1,2,:),storetcdays(1,3,:),storetcdays(1,4,:),storetcdays(1,5,:),storetcdays(1,6,:),storetcdays(1,7,:),storetcdays(1,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
      
textfile="stats/stats_hurrdays_by_year_"+cam_version+".txt"
write_table(textfile,"w",[/ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s,%s,%s,%s,%s,%s,%s,%s,%s")
write_table(textfile,"a",[/"cam"/],"%s")
write_table(textfile,"a",[/storehurrdays(0,0,:),storehurrdays(0,1,:),storehurrdays(0,2,:),storehurrdays(0,3,:),storehurrdays(0,4,:),storehurrdays(0,5,:),storehurrdays(0,6,:),storehurrdays(0,7,:),storehurrdays(0,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
write_table(textfile,"a",[/"ibtracs"/],"%s")
write_table(textfile,"a",[/storehurrdays(1,0,:),storehurrdays(1,1,:),storehurrdays(1,2,:),storehurrdays(1,3,:),storehurrdays(1,4,:),storehurrdays(1,5,:),storehurrdays(1,6,:),storehurrdays(1,7,:),storehurrdays(1,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
      
textfile="stats/stats_majhurrdays_by_year_"+cam_version+".txt"
write_table(textfile,"w",[/ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s,%s,%s,%s,%s,%s,%s,%s,%s")
write_table(textfile,"a",[/"cam"/],"%s")
write_table(textfile,"a",[/storemajhurrdays(0,0,:),storemajhurrdays(0,1,:),storemajhurrdays(0,2,:),storemajhurrdays(0,3,:),storemajhurrdays(0,4,:),storemajhurrdays(0,5,:),storemajhurrdays(0,6,:),storemajhurrdays(0,7,:),storemajhurrdays(0,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")
write_table(textfile,"a",[/"ibtracs"/],"%s")
write_table(textfile,"a",[/storemajhurrdays(1,0,:),storemajhurrdays(1,1,:),storemajhurrdays(1,2,:),storemajhurrdays(1,3,:),storemajhurrdays(1,4,:),storemajhurrdays(1,5,:),storemajhurrdays(1,6,:),storemajhurrdays(1,7,:),storemajhurrdays(1,8,:)/], \
      "%f,%f,%f,%f,%f,%f,%f,%f,%f")


;print(stdevACE)
;print(ACEperyear)

;print(ACEperyear)
;totals = dim_sum_n_Wrap(storetcdays,2) / (numyears)

; Figure out correlations?
;ccr = escorc(ACEperyear(1,0,:),ACEperyear(0,0,:))   ; ccr is a scalar
;print("CCR between obs and obs is "+ccr)




stats_days_file = "stats/days_"+cam_version+".txt"
;write_table("stats_tcs.txt","w",[/"year,"ocn_basins(0),ocn_basins(1),ocn_basins(2),ocn_basins(3),ocn_basins(4),ocn_basins(5),ocn_basins(6),ocn_basins(7),ocn_basins(8)/],"%s")
;write_table("stats_tcs.txt","a",[/ocn_basins(0:howmanybasins),avgTCdays(0,:),stdevTCdays(0,:),avghurrdays(0,:),stdevhurrdays(0,:),avgmajhurrdays(0,:),stdevmajhurrdays(0,:),avgACE(0,:),stdevACE(0,:)/], \
;      "%d,%d,%d,%d,%d,%d,%d,%d,%d")
      
write_table(stats_days_file,"w",[/"basin,tcdays,tcdays_sd,hurrdays,hurrdays_sd,majhurrdays,majhurrdays_sd,ace,ace_sd"/],"%s")
write_table(stats_days_file,"a",[/"cam"/],"%s")
write_table(stats_days_file,"a",[/ocn_basins(0:howmanybasins),avgTCdays(0,:),stdevTCdays(0,:),avghurrdays(0,:),stdevhurrdays(0,:),avgmajhurrdays(0,:),stdevmajhurrdays(0,:),avgACE(0,:),stdevACE(0,:)/], \
      "%s,%f,%f,%f,%f,%f,%f,%f,%f")
write_table(stats_days_file,"a",[/"ibtracs"/],"%s")
write_table(stats_days_file,"a",[/ocn_basins(0:howmanybasins),avgTCdays(1,:),stdevTCdays(1,:),avghurrdays(1,:),stdevhurrdays(1,:),avgmajhurrdays(1,:),stdevmajhurrdays(1,:),avgACE(1,:),stdevACE(1,:)/], \
      "%s,%f,%f,%f,%f,%f,%f,%f,%f")


if (do_plot)


;============================================================================

  ;**************************************************
  ; create plot
  ;**************************************************
  

  wks = gsn_open_wks("pdf","amip_timeseries")                           ; Open a workstation.
  
  res               = True                                ; plot mods desired
  res@gsnDraw = False
  res@gsnFrame = False
  res@gsnMaximize            = True       ; Maximize plot in frame.
  res@tiMainString  = "Annual Atlantic TC Count"        ; title
  res@tiYAxisString = "Number of Tropical Cyclones"     ; y axis title
  res@tiXAxisString = "Year"    ; y axis title
  res@trXMinF = styr                                                       ; set minimum X-axis value
  res@trXMaxF = enyr                                                    ; set maximum X-axis value
  
  res@trYMinF = 0
  res@trYMaxF = max(storetcdays(:,0,:))
  
  res@xyLineThicknesses = (/5.0,5.0,5.0/)               ; make 2nd lines thicker
  res@xyLineColors      = (/"blue","red","green"/)          ; change line color
  res@xyDashPattern = 0               ; Make curves all solid
  
  res@xyMarkLineMode = "MarkLines"    ; Markers *and* lines
  res@xyMarkers      = (/16,16,16/)    ; 3 different markers
  
  res@xyMarkerColors = (/"blue","red","green"/)  ; 3 different colors
  
  ;---Further customize the legend
  ;  res@trYMinF                = -3.5      ; Leave space at bottom for legend
  res@pmLegendDisplayMode    = "Always"   ; Display a legend.
  res@xyExplicitLegendLabels = (/"CAM-SE","Obs","CAM-FV 1deg","CAM-FV 0.25deg"/)
  
  ;  res@lgJustification        = "TopRight"
  res@pmLegendOrthogonalPosF = -1.05     ; Move into plot
  res@pmLegendParallelPosF   = 0.75       ; Move to right
  res@pmLegendWidthF         = 0.2       ; Decrease width
  res@pmLegendHeightF        = 0.1       ; Decrease height
  res@lgBoxMinorExtentF      = 0.1       ; Shorten the legend lines
  ;  res@lgLabelFontHeightF     = 0.0005     ; Change the font size
  
  plot = gsn_xy(wks,time,storetcdays(:,0,:),res)
  
  ; ====== ERROR BARS
  polyres                   = True                       ; marker resources
  polyres@gsMarkerIndex     = 1                          ; index for circle
  polyres@gsMarkerSizeF     = .02                        ; size 
  
  ; gsn_add* templates are functions that we set to dummy values. Since
  ; we are going to draw numerous error bars, we create two arrays to
  ; hold the dummy values.
  error_bar = new((/2,dimsizes(time)/),graphic)
  centers   = new((/2,dimsizes(time)/),graphic)
  
  ; loop through the points
  do i=0,1
    do t=0,dimsizes(time)-1
      ; add a polymarker as the center of the error bar located at each data
      ; point
      centers(i,t)   = gsn_add_polymarker(wks,plot,time(t),storetcdays(i,0,t),polyres)
      ; the error bar is draw in two segements, above and below the true
      ; value of u(t). I made up these value. You would change this to 
      ; true error.      
      error_bar(i,t) = gsn_add_polyline(wks,plot,(/time(t),time(t)/),(/storetcdays(i,0,t)+(stdevTCdays(i,0)/2.),storetcdays(i,0,t)-(stdevTCdays(i,0)/2.)/),\
      polyres)
    end do
  end do
  ; ==============
  
  draw(plot)
  frame(wks)
  
end if

end

