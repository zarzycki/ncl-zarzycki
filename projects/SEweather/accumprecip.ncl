load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "rainratetodbz.ncl"

begin

zz  = ispan(12,960,3)
zzs = sprinti("%0.3i",zz)   ; "000", "001", ... "100"

datafiledir = "/glade/scratch/zarzycki/archive/eastseaboard_30_x8/atm/hist/"
datafilename = "2012_12_28_00z_h1.nc"
datafile = addfile(datafiledir+datafilename,"r")

datafilename2 = "2012_12_28_00z_h0.nc"
datafile2 = addfile(datafiledir+datafilename2,"r")


lat = datafile->lat
lon = datafile->lon

maxlat = 50           ; choose subregion           
minlat = 38
maxlon = 300. 
minlon = 280. 

PRECT = datafile->PRECT(:,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECSL = datafile->PRECSL(:,{minlat-5:maxlat+5},{minlon-5:maxlon+5})
PRECSC = datafile->PRECSC(:,{minlat-5:maxlat+5},{minlon-5:maxlon+5})

; Combine snowfall rates (LS + C) for total snowfall rate
PRECST = PRECSL+PRECSC
copy_VarMeta(PRECSL,PRECST)

delete(PRECSL)
delete(PRECSC)

PRECST = PRECST * 3. * 3600. * 39.37 ; convert m/s to in
snowrainratio = 10 ;10:1
PRECST = PRECST * snowrainratio
PRECST_cumsum = dim_cumsum_n_Wrap(PRECST,2,0)

;PRECT = PRECT * 3. * 3600. * 39.37 ; convert m/s to in
;PRECT_cumsum = dim_cumsum_n_Wrap(PRECT,2,0)
 
PSL = datafile2->PSL
PSL = PSL/100                   ; convert to mb

do time = 0,getfilevardimsizes(datafile, "time" )-1

print("Plotting time #: "+time)

out_type = "ps"
wks = gsn_open_wks(out_type,"accumprecip"+zzs(time))

;*****************************************************
; PLOT
;*****************************************************

  gsn_define_colormap(wks,"precip2_15lev")

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
  res_rain@gsnLeftString = "Accumulated LWE precip"
  res_rain@gsnRightString = "in"

  res_rain@gsnSpreadColors      = True              ; use full colormap
;  res_rain@gsnSpreadColorStart= -1
;  res_rain@gsnSpreadColorEnd = 2
;  res_rain@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_rain@cnFillColors = (/10,11,12,13,14,15,16,17/)
;  res_rain@cnMaxLevelCount = 7			 ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
;  res_rain@cnFillColors = (/-1,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32/)
;  res_rain@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_rain@cnMaxLevelCount =13		 ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_rain@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
  res_rain@cnLevels    = (/0.01, .1, .25, .5, .75, 1, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0, 5.0/)	; set levels
  res_rain@cnLevels    = res_rain@cnLevels * 10

  res_rain@lbLabelStride = 2
  res_rain@lbOrientation = "vertical"
  
  
  res_mslp = res
  res_mslp@tiMainString = ""
  res_mslp@gsnLeftString = ""
  res_mslp@gsnRightString = ""
  res_mslp@cnInfoLabelOn = False
  res_mslp@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res_mslp@cnMinLevelValF       = 920.              ; set min contour level
  res_mslp@cnMaxLevelValF       =  1090.              ; set max contour level
  res_mslp@cnLevelSpacingF      =  4.              ; set contour spacing
  res_mslp@cnLineLabelsOn       = True
  res_mslp@cnLineLabelInterval = 4
  res_mslp@gsnContourZeroLineThicknessF = 4. 	; doubles thickness of zero contour
  res_mslp@gsnContourNegLineDashPattern = 1 	; sets negative contours to dash pattern 1


  plotrain = gsn_csm_contour_map(wks,PRECST_cumsum(time,:,:),res_rain)
        
  plot_slp = gsn_csm_contour(wks,PSL(time,:,:),res_mslp) 
  
  overlay(plotrain,plot_slp) 

  draw(plotrain)
  frame(wks)


end do

;----------- Get rid of 000001 on the end of png files
  delete(wks)
  delete(res)

end

