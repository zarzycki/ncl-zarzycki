;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; timeLon.ncl
; Carl Schreck (carl@atmos.albany.edu)
; January 2010
;------------------------------------------------------------------------------
; Description: Draw a time-lon (Hovmoller) plot of unfiltered CLAUS overlaid 
; with wave-filtered contours
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
; User Contributed routines follow. They are NOT supported by the NCL team. 
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Main
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
begin

numfiles = 1

;  wks = gsn_open_wks( "pdf", "wkSpaceTime" )
;  plot = new(numfiles,graphic)
;  cont = new(numfiles,graphic)         

do ii = 0,numfiles-1

  gridlist = (/"quadrant_15_x8","uniform_15","uniform_120"/)
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
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_15/h2_all.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"
    inFile     = addfile( src_file, "r" )
    timeUnits = inFile->time@units
    startDate = ut_inv_calendar( 0003, 04, 01, 00, 0, 0, timeUnits, 0 )
    endDate   = ut_inv_calendar( 0003, 08, 31, 00, 0, 0, timeUnits, 0 )
  else if (gridname .eq. "uniform_120") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_120/h2_full.nc"
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

  spd      = 4       ; samples per day (6 hour sampling rate)
  var      = "FLUT"  ; user specified 
    
  numtimes = dimsizes(inFile->time)
  timeCut = numtimes - mod(numtimes,spd)
  print("Numtimes = "+numtimes+" so we are cutting at time = "+timeCut)

  mis = -999
  mis@_FillValue = -999

   case     = "CAM APE"  
  diro     = "./"        ; output dir: location of plots 

  latN     = 15
  latS     = -latN       ; symmetric about the equator

  nDayWin  = 96      ; Wheeler-Kiladis [WK] temporal window length (days)
  nDaySkip = 30      ; time (days) between temporal windows [segments]
                     ; negative means there will be overlapping 
                     ; temporal segments

  opt      = True
  opt@debug= True
  opt@pltType     = "pdf"
  opt@cnLinesOn   = False   ; turn off contour lines
                     ; specify the plot intervals



;  diri     = "/project/cas/shea/WHEELER/"
;  fili     = "OMEGA.2001-2005.nc"    
  
  print( "Reading..." )
  inData_se   = inFile->FLUT(:,:) ;time, ncol
  Opt         = True
  inData_remap  = ESMF_regrid_with_weights(inData_se,wgt_file,Opt)  
  inData =  lonFlip(inData_remap(0:(timeCut-1),{latS:latN},:))
  delete(inData_remap)
  delete(inData_se)

;  f        = addfile (diri+fili, "r") 
;  omega    = f->omega(:,0,{latS:latN},:)     ; (time,lat,lon)

                     ; calculation and create plots
  wkSpaceTime (inData, diro, case, var,latN, spd, nDayWin, nDaySkip, opt  )
 
end do


end
