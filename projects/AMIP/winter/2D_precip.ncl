load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "~/ncl/functions/rainratetodbz.ncl"
load "~/ncl/functions/plot_hommegrid_fcn.ncl"

begin

;16

;datafiledir = "/glade/u/home/zarzycki/scratch/h2files/atl30x4/1993/"
;datafilename = "atl_30_x4_refine_nochem.cam.h2.1993-01-28-00000.nc"
;datafile = addfile(datafiledir+datafilename,"r")

datafile = addfile("/glade/scratch/zarzycki/winter/avg.nc","r")

lat = datafile->lat
lon = datafile->lon

maxlat = 75.           ; choose subregion           
minlat = 30.
maxlon = 305. 
minlon = 270. 

index = 20

;PRECT_SNOW = datafile->PRECT_SNOW(0,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECT_SNOW = datafile->PRECT_SNOW_RATE(0,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECT_ICE = datafile->PRECT_ICE(0,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECT_FZRA = datafile->PRECT_FZRA(0,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
;RATIO = datafile->RATIO({minlat-5:maxlat+5},{minlon-5:maxlon+5})

;PRECT = PRECT_SNOW
;PRECT = PRECT_SNOW*RATIO*141732.283*24*21.5

;PRECT_SNOW = PRECT_SNOW*141732.283*24*10*(26+28+31)
PRECT_SNOW = PRECT_SNOW*141732.283*24*(26+28+31)
PRECT_ICE = PRECT_ICE*141732.283*24*(26+28+31)
PRECT_FZRA = PRECT_FZRA*141732.283*24*(26+28+31)

;RAINDBZ = rainratetodbz(PRECT_SNOW,1)

out_type = "x11"
wks = gsn_open_wks(out_type,"weatherplot")

plot = new(3,"graphic")
;*****************************************************
; PLOT
;*****************************************************

  gsn_define_colormap(wks,"3gauss")          ; choose colormap
  
; Use for PNG
;  wks_type@wkWidth = 1024
;  wks_type@wkHeight = 1024


;----------- Global resources -----------------------------------------
  
  res                 = True
  
  res@gsnDraw      = False                        ; don't draw yet
  res@gsnFrame     = False                        ; don't advance frame yet
  res@gsnMaximize = True
  
  res@gsnAddCyclic = False                    ; Don't add a cyclic point.
  
  res_rain                      = res
    
  res_rain@cnFillOn		  = True
  res_rain@cnLinesOn   = False 
    
  res_rain@mpFillOn                    = False        ; turn off gray fill
  res_rain@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
  res_rain@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
  res_rain@mpGeophysicalLineThicknessF = 3            ; thickness of outlines

  res_rain@mpMaxLatF                   = maxlat           ; choose subregion           
  res_rain@mpMinLatF                   = minlat
  res_rain@mpMinLonF = minlon 
  res_rain@mpMaxLonF = maxlon 
  res_rain@mpCenterLonF = (res_rain@mpMinLonF+res_rain@mpMaxLonF)/2. 
  
  res_rain@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res_rain@cnMinLevelValF  = 0.			; set the minimum contour level
  res_rain@cnMaxLevelValF  = 200.0		; set the maximum contour level
  res_rain@cnLevelSpacingF = 10.0		; set the interval between contours
  
res_rain@gsnSpreadColors      = True              ; use full colormap
;  res_rain@cnFillColors = (/-1,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32/)
;res_rain@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
;res_rain@cnLevels    = (/0,0.1,12,24,36,48/)	; set levels
 ; res_rain@lbLabelStride = 2
 ; res_rain@lbOrientation = "vertical"

  ;plotrain = gsn_csm_map(wks,res)
  plot(0) = gsn_csm_contour_map(wks,PRECT_SNOW(:,:),res_rain)

  res_rain@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res_rain@cnMinLevelValF  = 0.			; set the minimum contour level
  res_rain@cnMaxLevelValF  = 4.0		; set the maximum contour level
  res_rain@cnLevelSpacingF = 0.2		; set the interval between contours
  
  plot(1) = gsn_csm_contour_map(wks,PRECT_ICE(:,:),res_rain)

  res_rain@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res_rain@cnMinLevelValF  = 0.			; set the minimum contour level
  res_rain@cnMaxLevelValF  = 4.0		; set the maximum contour level
  res_rain@cnLevelSpacingF = 0.2		; set the interval between contours

  plot(2) = gsn_csm_contour_map(wks,PRECT_FZRA(:,:),res_rain)

;  plotrain = plot_hommegrid_fcn(wks,plotrain,"~/work/grids/exodus/atlantic_30_x4.g","black",2.0,minlat,maxlat,minlon-360,maxlon-360)

  
  ;draw(plotrain)
  ;frame(wks)

gsn_panel(wks,plot,(/1,3/),False)  

end
