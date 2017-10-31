load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "rainratetodbz.ncl"

begin

zz  = ispan(12,960,3)
zzs = sprinti("%0.3i",zz)   ; "000", "001", ... "100"

datafiledir = "/glade/scratch/zarzycki/archive/westatl_30_x8/atm/hist/"
datafilename = "1026_00z.nc"
datafile = addfile(datafiledir+datafilename,"r")

lat = datafile->lat
lon = datafile->lon

maxlat = 50           ; choose subregion           
minlat = 20
maxlon = 300. 
minlon = 270. 

PRECT = datafile->PRECT(:,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECSL = datafile->PRECSL(:,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECSC = datafile->PRECSC(:,{minlat-5:maxlat+5},{minlon-5:maxlon+5})

; Combine snowfall rates (LS + C) for total snowfall rate
PRECST = PRECSL+PRECSC
copy_VarMeta(PRECSL,PRECST)

delete(PRECSL)
delete(PRECSC)

RAINDBZ = rainratetodbz(PRECT,1)
SNOWDBZ = rainratetodbz(PRECST,1)
 
PSL = datafile->PSL
PSL = PSL/100                   ; convert to mb
;Z1000 = datafile->Z1000
;Z500 = datafile->Z500
;THICK = Z1000
;THICK = Z500-Z1000
T850 = datafile->T850
T850 = T850-273.15
printVarSummary(T850)

do time = 0,getfilevardimsizes(datafile, "time" )-1

print("Plotting time #: "+time)

out_type = "ps"
wks = gsn_open_wks(out_type,"weatherplot"+zzs(time))

;*****************************************************
; PLOT
;*****************************************************

  gsn_define_colormap(wks,"rainsnowradar")          ; choose colormap
  
; Use for PNG
;  wks_type@wkWidth = 1024
;  wks_type@wkHeight = 1024


;----------- Global resources -----------------------------------------
  
  res                 = True
  
  res@gsnDraw      = False                        ; don't draw yet
  res@gsnFrame     = False                        ; don't advance frame yet
  res@gsnMaximize = True
  
  res@gsnAddCyclic = False                    ; Don't add a cyclic point.
  
  
  
  
  
;  res@lbOrientation = "vertical"
  
  
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
  
  res_rain@tiMainString = ""
  res_rain@gsnLeftString = "Simulated Reflectivity"
  res_rain@gsnRightString = "dBZ"

  res_rain@gsnSpreadColors      = False              ; use full colormap
;  res_rain@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_rain@cnFillColors = (/10,11,12,13,14,15,16,17/)
;  res_rain@cnMaxLevelCount = 7			 ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_rain@cnFillColors = (/-1,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32/)
;  res_rain@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_rain@cnMaxLevelCount =13		 ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_rain@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
  res_rain@cnLevels    = (/0,5,10,15,20,25,30,35,40,45,50,55,60,65,70/)	; set levels
  res_rain@lbLabelStride = 2
  res_rain@lbOrientation = "vertical"
  
  
  res_mslp = res
  res_mslp@tiMainString = ""
  res_mslp@gsnLeftString = ""
  res_mslp@gsnRightString = ""
  res_mslp@cnInfoLabelOn = False
  res_mslp@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res_mslp@cnMinLevelValF       = 950.              ; set min contour level
  res_mslp@cnMaxLevelValF       =  1020.              ; set max contour level
  res_mslp@cnLevelSpacingF      =  4.              ; set contour spacing
  res_mslp@cnLineLabelsOn       = True
  res_mslp@cnLineLabelInterval = 4
  res_mslp@gsnContourZeroLineThicknessF = 4. 	; doubles thickness of zero contour
  res_mslp@gsnContourNegLineDashPattern = 1 	; sets negative contours to dash pattern 1

  res_snow = res
  res_snow@tiMainString = ""
  res_snow@gsnLeftString = ""
  res_snow@gsnRightString = ""
  res_snow@cnFillOn		  = True
;  res_snow@lbOrientation = "vertical"
  res_snow@lbLabelBarOn = False
  res_snow@cnLineLabelsOn       = False
  res_snow@cnInfoLabelOn = False
  res_snow@cnFillColors = (/-1,2,3,4,5,6,7,8,9/)
  res_snow@cnLinesOn   = False 
  res_snow@cnFillColors(0)    = -1  ; make 1st two contours are transparent
;  res_snow@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_snow@cnMaxLevelCount = 7			 ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_snow@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
  res_snow@cnLevels    = (/0,5,10,15,20,25,30,35/)	; set levels
  
  res_thick = res
  res_thick@tiMainString = ""
  res_thick@gsnLeftString = ""
  res_thick@gsnRightString = ""
  res_thick@cnInfoLabelOn = False
  res_thick@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res_thick@cnLineColor      = "Red" 
  res_thick@cnMinLevelValF       = -50.              ; set min contour level
  res_thick@cnMaxLevelValF       =  50.              ; set max contour level
  res_thick@cnLevelSpacingF      =  10.              ; set contour spacing
  res_thick@cnLineLabelsOn       = True
  res_thick@cnLineLabelInterval = 4
  res_thick@gsnContourZeroLineThicknessF = 4. 	; doubles thickness of zero contour
  res_thick@gsnContourNegLineDashPattern = 1 	; sets negative contours to dash pattern 1
  
  


;  plotrain = gsn_csm_contour_map(wks,PRECT(time,:,:),res_rain)
  plotrain = gsn_csm_contour_map(wks,RAINDBZ(time,:,:),res_rain)
      
  plotsnow = gsn_csm_contour(wks,SNOWDBZ(time,:,:),res_snow)
  
  plot_slp = gsn_csm_contour(wks,PSL(time,:,:),res_mslp)
  
  plot_thick = gsn_csm_contour(wks,T850(time,:,:),res_thick)
  
  overlay(plotrain,plotsnow) 
  overlay(plotrain,plot_slp) 
  overlay(plotrain,plot_thick) 

  draw(plotrain)
  frame(wks)


end do

;----------- Get rid of 000001 on the end of png files
  delete(wks)
  delete(res)

end
