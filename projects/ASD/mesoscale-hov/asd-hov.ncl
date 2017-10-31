load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
  
   do_regrid=True
;   fils = systemfunc ("ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.*.cam.h4.1998-07-*-00000.nc") ; file paths
;   fils = systemfunc ("ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.*.cam.h4.1998-07-*-00000.nc") ; file paths
   fils = systemfunc ("ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.*.cam.h4.1985-05-*-00000.nc") ; file paths

  print(fils)

   f    = addfiles (fils, "r")   
   ListSetType (f, "cat")        ; concatenate (=default)



  ;minlat=30.0
  ;maxlat=48.0
  ;minlon=360.-115.0
  ;maxlon=360.-78.0

  minlat=35.0
  maxlat=48.0
  minlon=360.-105.0
  maxlon=360.-80.0

  PRECT   = f[:]->PRECT
  PRECT = PRECT*3.6e6  ; mm/hr

  if(do_regrid) then
;    wgtFileName="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"
;    wgtFileName="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_mp120a_to_1x1reg_patch.nc"
    wgtFileName="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"

    Opt                = True
    Opt@PrintTimings   = True
    temp_regrid = ESMF_regrid_with_weights(PRECT,wgtFileName,Opt)
    delete(PRECT)
    PRECT = temp_regrid
  end if

  PRECTsub   = PRECT(:,{minlat:maxlat},{minlon:maxlon})
  PRECTav = dim_avg_n_Wrap(PRECTsub,1)

  time = f[:]->time
  time_pretty = cd_calendar(time,3)
  ;print(time_pretty)
  ;PRECTav&time=time_pretty

;==============================================
; create color plot
;=============================================
  wks  = gsn_open_wks ("x11", "hov" )           ; send graphics to PNG file

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnFillPalette        = "WhViBlGrYeOrRe"           ; set color map

  res@vpWidthF = 0.3
  res@vpHeightF = 0.6
  ;res@gsnMaximize = True

  res@cnFillMode       = "RasterFill"       ; Raster Mode
  res@cnLinesOn        =  False             ; Turn off contour lines

  res@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
  res@cnMinLevelValF       = 0.1        ; min level
  res@cnMaxLevelValF       = 1.7               ; max level
  res@cnLevelSpacingF      = 0.1                 ; contour level spacing
  
  ;res@tmYLMode   = "Explicit"
  ;res@tmYLValues = time_pretty
  ;res@tmYLLabels = "" + res@tmYLValues 

  res@gsnLeftString=""
  res@gsnRightString=""

  plot = gsn_csm_hov(wks, PRECTav, res) 
  
end
