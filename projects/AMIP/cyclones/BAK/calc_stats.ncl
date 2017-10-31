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


; Select the wind correction factor. Valid options are "power" "log" and "none"
wind_factor = "log"
; Trajectory file output from tracker
traj_dir = "/glade/u/home/zarzycki/tcstats/"
traj_filename = "traj_1deg"
; Origin/max intensity file (output from C++ script)
orimax_dir =""
orimax_file = ""
; iBTracs data
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"
out_type = "x11"
; Do we want to normalize tracked storms by average observed?
correct_average=False
do_plot=True
maxtrackerlat = 45.0

howmanybasins=8
styr = 1980
enyr = 2002

;Constants
ms_to_kts = 1.94384449
ocn_basins = (/"natl","epac","cpac","wpac","nio","sio","spac","satl","glob"/)
numyears = enyr-styr+1
time = ispan(styr,enyr,1)

storetcdays = new((/2,howmanybasins+1,numyears/),"float")
storehurrdays = new((/2,howmanybasins+1,numyears/),"float")
storemajhurrdays = new((/2,howmanybasins+1,numyears/),"float")
ACEperyear = new((/2,howmanybasins+1,numyears/),"float")

print("Getting TC masks")
  maskspacing = 2 ; degrees
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
  
  print("Get ibTracs data")
  
  ibfile = addfile(ibdir+ibfilename,"r")
  
  iblat = ibfile->lat_for_mapping*.01
  iblon = ibfile->lon_for_mapping*.01
  ibpres = ibfile->source_pres(:,:,:)*.1
  ibyear = ibfile->season
  ibtype = toint(ibfile->nature_for_mapping)

  ibwind = ibfile->source_wind(:,:,:)*.1/ms_to_kts
  
  ibdimsizes = dimsizes(iblat)
  ibnumstorms = ibdimsizes(0)
  
  ; Quick fix for lons that go outside the tcMask
  iblon(:,0) = where(iblon(:,0).gt.180.0-maskspacing,180.0-maskspacing,iblon(:,0))
  traj_data(:,0) = where(traj_data(:,0).gt.360.-maskspacing,360.-maskspacing,traj_data(:,0)) 
  
  

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
ACEperyear(:,howmanybasins,:) = dim_sum_n_Wrap(ACEperyear(:,2:7,:),1)
storetcdays(:,howmanybasins,:) = dim_sum_n_Wrap(storetcdays(:,2:7,:),1)
storehurrdays(:,howmanybasins,:) = dim_sum_n_Wrap(storehurrdays(:,2:7,:),1)
storemajhurrdays(:,howmanybasins,:) = dim_sum_n_Wrap(storemajhurrdays(:,2:7,:),1)

avgTCdays = dim_avg_n_Wrap(storetcdays,2)
stdevTCdays = dim_stddev_n_Wrap(storetcdays,2)
avghurrdays = dim_avg_n_Wrap(storehurrdays,2)
stdevhurrdays = dim_stddev_n_Wrap(storehurrdays,2)
avgmajhurrdays = dim_avg_n_Wrap(storemajhurrdays,2)
stdevmajhurrdays = dim_stddev_n_Wrap(storemajhurrdays,2)
avgACE = dim_avg_n_Wrap(ACEperyear,2)
stdevACE = dim_stddev_n_Wrap(ACEperyear,2)

print(stdevACE)
print(ACEperyear)

;print(ACEperyear)
;totals = dim_sum_n_Wrap(storetcdays,2) / (numyears)

; Figure out correlations?
;ccr = escorc(ACEperyear(1,0,:),ACEperyear(0,0,:))   ; ccr is a scalar
;print("CCR between obs and obs is "+ccr)

  write_table("stats.txt","w",[/"basin,tcdays,tcdays_sd,hurrdays,hurrdays_sd,majhurrdays,majhurrdays_sd,ace,ace_sd"/],"%s")
  write_table("stats.txt","a",[/ocn_basins(0:howmanybasins),avgTCdays(0,:),stdevTCdays(0,:),avghurrdays(0,:),stdevhurrdays(0,:),avgmajhurrdays(0,:),stdevmajhurrdays(0,:),avgACE(0,:),stdevACE(0,:)/], \
              "%s,%f,(%f),%f,(%f),%f,(%f),%f,(%f)")
  write_table("stats.txt","a",[/ocn_basins(0:howmanybasins),avgTCdays(1,:),stdevTCdays(1,:),avghurrdays(1,:),stdevhurrdays(1,:),avgmajhurrdays(1,:),stdevmajhurrdays(1,:),avgACE(1,:),stdevACE(1,:)/], \
              "%s,%f,(%f),%f,(%f),%f,(%f),%f,(%f)")
;              "%s%4.1f%4.1f")

;print(totals)

if (do_plot)

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
  res@trYMaxF = max(ACEperyear)
  
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
  
  plot = gsn_xy(wks,time,ACEperyear(:,0,:),res)
  
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
      centers(i,t)   = gsn_add_polymarker(wks,plot,time(t),ACEperyear(i,0,t),polyres)
      ; the error bar is draw in two segements, above and below the true
      ; value of u(t). I made up these value. You would change this to 
      ; true error.      
      error_bar(i,t) = gsn_add_polyline(wks,plot,(/time(t),time(t)/),(/ACEperyear(i,0,t)+(stdevACE(i,0)/2.),ACEperyear(i,0,t)-(stdevACE(i,0)/2.)/),\
      polyres)
    end do
  end do
  ; ==============
  
  draw(plot)
  frame(wks)
  
end if

end

