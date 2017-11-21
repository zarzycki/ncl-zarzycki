;----------------------------------------------------------------------
; vector_3.ncl
;
; Concepts illustrated:
;   - Drawing a black-and-white vector plot over a cylindrical equidistant map
;   - Adding a time stamp to a plot
;   - Thinning vectors using a minimum distance resource
;   - Moving the vector reference annotation to the top right of the plot
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;************************************************
begin
;************************************************
; read in netCDF file
;************************************************
  a = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/uv300.nc","r")
  
  gridname = "quadrant_15_x8"
  
  if (gridname .eq. "quadrant_15_x8") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h2_0002.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"
    inFile     = addfile( src_file, "r" )
  else if (gridname .eq. "uniform_15") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_15/h2_all.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"
    inFile     = addfile( src_file, "r" )
  else if (gridname .eq. "uniform_120") then
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_120/h2_full.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uniform_120_TO_0.25x0.25_patc.130729.nc"
    inFile     = addfile( src_file, "r" )
  else
    print("Uh, don't have a grid for that!")
    exit
  end if
  end if
  end if

;************************************************
; read in zonal [u] and meridional [v] winds (July)
;************************************************

  print( "Reading..." )
  u850_se_full   = inFile->U200(:,:) ;time, ncol
  v850_se_full   = inFile->V200(:,:) ;time, ncol
  u850_se = dim_avg_n_Wrap(u850_se_full,0)
  v850_se = dim_avg_n_Wrap(v850_se_full,0)
  delete([/u850_se_full,v850_se_full/])
  Opt         = True
  u850  = ESMF_regrid_with_weights(u850_se,wgt_file,Opt)  
  delete(u850_se)
  v850  = ESMF_regrid_with_weights(v850_se,wgt_file,Opt)  
  delete(v850_se)
  
;************************************************
; create plot
;************************************************
  wks = gsn_open_wks("x11","vector")                ; open a ps file

  vcres                         = True             ; plot mods desired
  vcres@gsnFrame                = False            ; so we can draw time stamp
  vcres@vcRefAnnoOrthogonalPosF = -1.0             ; move ref vector up
  vcres@vcRefMagnitudeF         = 10.0             ; define vector ref mag
  vcres@vcRefLengthF            = 0.045            ; define length of vec ref
  vcres@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
  vcres@vcMinDistanceF          = 0.017

  vector = gsn_csm_vector_map_ce(wks,u850,v850,vcres)
;************************************************
; add time stamp to plot
;************************************************
;  infoTimeStamp(wks,0.025,"uv300.nc")      ; arguments are workstation
                                           ; size of text desired, and
                                           ; right string.         
  frame (wks)  
end
