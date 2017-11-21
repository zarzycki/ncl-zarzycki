;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Description: Draw a time-lon (Hovmoller) plot of unfiltered CLAUS overlaid 
; with wave-filtered contours
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; User Contributed routines follow. They are NOT supported by the NCL team. 
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Main
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
begin

numfiles = 3

  wks = gsn_open_wks( "pdf", "kelvinFilter" )
  plot = new(numfiles,graphic)
  cont = new(numfiles,graphic)         

do ii = 0,numfiles-1

  gridlist = (/"uniform_15","quadrant_15_x8","uniform_120"/)
  titlelist = (/"Coarse","Var-res","Fine"/)
  gridname = gridlist(ii)
  print("Doing grid: "+gridname)
  
  if (gridname .eq. "quadrant_15_x8") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h2_0002.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"
    inFile     = addfile( src_file, "r" )
    timeUnits = inFile->time@units
    startDate = ut_inv_calendar( 0002, 04, 01, 00, 0, 0, timeUnits, 0 )
    endDate   = ut_inv_calendar( 0002, 08, 31, 00, 0, 0, timeUnits, 0 )
  else if (gridname .eq. "uniform_15") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_15/h2_0002.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"
    inFile     = addfile( src_file, "r" )
    timeUnits = inFile->time@units
    startDate = ut_inv_calendar( 0003, 04, 01, 00, 0, 0, timeUnits, 0 )
    endDate   = ut_inv_calendar( 0003, 08, 31, 00, 0, 0, timeUnits, 0 )
  else if (gridname .eq. "uniform_120") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_120/h2_0001.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uniform_120_TO_0.25x0.25_patc.130729.nc"
    inFile     = addfile( src_file, "r" )
    timeUnits = inFile->time@units
    startDate = ut_inv_calendar( 0002, 04, 01, 00, 0, 0, timeUnits, 0 )
    endDate   = ut_inv_calendar( 0002, 08, 31, 00, 0, 0, timeUnits, 0 )
  else
    print("Uh, don't have a grid for that!")
    exit
  end if
  end if
  end if

  mis = -999
  mis@_FillValue = -999

  ; set the wave parameters
  tMin = 2.5
  tMax = 20
  kMin = 1
  kMax = 14
  hMin = 8
  hMax = 90
  waveName = "Kelvin"  

  ; number of timesteps in data for each day
  obsPerDay = 4

  ; number of days to filter on each side of the period we're interested in
  bufferDays = 90

  ; calculate our number of weights
  if( isStrSubset( timeUnits, "days" ) ) then
    buffer = bufferDays * 1
  else
    if( isStrSubset( timeUnits, "hours" ) ) then
      buffer = bufferDays * 24
    else
      print( "DANGER! DANGER! Unexpected time units" )
      return
    end if
  end if

  filtStart = startDate - buffer
  filtStart@units = timeUnits
  filtEnd   = endDate + buffer
  filtEnd@units = timeUnits

  print("Startdate: "+filtStart+" end date: "+filtEnd)
  
  print( "Reading..." )
  inData_se   = inFile->FLUT({filtStart:filtEnd},:)
  Opt         = True
  inData_remap  = ESMF_regrid_with_weights(inData_se,wgt_file,Opt)
  ; -10, 10
  inData =  lonFlip(inData_remap(:,{-10:10},:))
  delete(inData_remap)
  delete(inData_se)
  
  origData = dim_avg_n_Wrap( inData, 1 )
  numtimes = dimsizes(origData(:,0))
  newtimearray = (fspan(0,numtimes-1,numtimes)/obsPerDay) - buffer
  ;newtimearray@units = timeUnits
  ;print(newtimearray)
  printVarSummary(origData)
  origData&time = newtimearray
  printVarSummary(newtimearray)
  
  ;print(origData&time)
  
  startDate = 0
  ;filtStart@units = timeUnits
  endDate   = newtimearray(numtimes-1) - buffer
  ;filtEnd@units = timeUnits
  
  print("Startdate: "+startDate+" end date: "+endDate)

  print( "Filtering..." )
  filtData = kf_filter( origData(time|:,lon|:), obsPerDay \
                      , tMin, tMax, kMin, kMax, hMin, hMax, waveName )

  printVarSummary( filtData )
  print( min(filtData) + " " + max(filtData) )


  ;gsn_define_colormap(wks,"WhBlGrYeRe")
  gsn_merge_colormaps( wks, "posneg_2", "default" )

  res = True

  res@cnFillOn = True
  res@cnFillMode          = "RasterFill"
  res@cnRasterSmoothingOn = True
  res@cnMonoFillColor     = False
  res@cnLineLabelsOn      = False
  res@cnInfoLabelOn       = False
  res@cnLinesOn           = False
  
  res@lbLabelBarOn        = False           ; turn off individual cb's

;  res@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
;  res@cnMinLevelValF       = 0.	        ; min level
;  res@cnMaxLevelValF       = 4.0e-7               ; max level
;  res@cnLevelSpacingF      = 0.2e-7                 ; contour level spacing

  res@cnLevelSelectionMode= "ExplicitLevels"
  res@cnLevels            = (/ 180, 190, 200, 210, 220, 230, 240, 250, 260 /)
  res@gsnSpreadColors     = True
  res@gsnSpreadColorStart = 21
  res@gsnSpreadColorEnd   = 13
  res@cnMissingValFillColor = "gray"

  res@gsnLeftString = ""
  res@gsnRightString = ""
  if(ii .eq. 0) then
    res@tiYAxisString = "Days"
  else
    res@tiYAxisString = ""
  end if
  res@gsnDraw = False
  res@gsnFrame = False

  res@trYReverse = True

  ; Add title to each panel
  ;res@gsnCenterString = titlelist(ii)
  res@tiMainString    = titlelist(ii)

  ; use tTick to set the time axis
  resTick = True
  resTick@ttFormat = "%d %c"
  resTick@ttAxis = "YL"
  resTick@ttMajorStride = 40
  ;tTick( origData&time,  res, resTick )

  plot(ii) = gsn_csm_hov( wks, origData({startDate:100},:), res )

  cnRes = True
  cnRes@cnLineThicknessF = 1.0
  cnRes@cnLineLabelsOn   = False
  cnRes@cnLineColor      = "black"
  cnRes@gsnLeftString    = ""
  cnRes@gsnRightString   = ""
  cnRes@gsnDraw          = False
  cnRes@gsnFrame         = False
  cnRes@cnLevelSelectionMode = "ExplicitLevels"
  cnRes@cnLevels         = (/ -15, -5 /)
  cnRes@cnInfoLabelOn = False

  cont(ii) = gsn_csm_contour( wks, filtData, cnRes )
  overlay( plot(ii), cont(ii) )
  
  if (gridname .eq. "quadrant_15_x8") then
  
    plres                  = True
    plres@gsLineColor      = "black"
    plres@gsLineThicknessF = 2.5

    pgy = (/ 0., 10000. /)
    pgx1 = (/ -36., -36. /)
    pgx2 = (/ 36., 36. /)
    pgx3 = (/ -45., -45. /)
    pgx4 = (/ 45., 45. /)

    dum1 = gsn_add_polyline(wks, plot(ii), pgx1, pgy, plres)
    dum2 = gsn_add_polyline(wks, plot(ii), pgx2, pgy, plres)
    dum3 = gsn_add_polyline(wks, plot(ii), pgx3, pgy, plres)
    dum4 = gsn_add_polyline(wks, plot(ii), pgx4, pgy, plres)
  
  end if

  delete([/filtData,origData,inData,newtimearray/])

end do

;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnPanelLabelBar = True                   ; add common colorbar

  ;resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
  ;resP@lbLabelStride    = 4
  ;resP@pmLabelBarWidthF = 0.7
  
  amres = True
  amres@amJust           = "TopLeft"
  resP@gsnPanelFigureStrings= (/"a.","b.","c."/)
  resP@gsnPanelFigureStringsFontHeightF = 0.02

  resP@gsnPanelXWhiteSpacePercent = 0.0
  
  gsn_panel(wks,plot,(/1,numfiles/),resP)               ; now draw as one plot

print( "Thank you, come again." + systemfunc("date") )

end
