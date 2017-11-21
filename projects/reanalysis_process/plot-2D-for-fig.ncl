;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "../radial_plots/radialAvg.ncl"
load "~/ncl/functions/psminsolver.ncl"
;========================================================
begin

trackfile="~/scratch/h1files/CFSR/2005/CFSR.h1.2005082612.nc"
pslFOdist=3.0
pslFOmag=4.0
wcFOdist=5.0
wcFOmag=-50.0
outType="pdf"
f=addfile(trackfile,"r")

minLat=18.
maxLat=32.
minLon=268.
maxLon=288.
buffer=1.

PSL=f->PSL(0,{minLat-buffer:maxLat+buffer},{minLon-buffer:maxLon+buffer})
PSL=PSL/100.
DZ300500=f->DZ300500(0,{minLat-buffer:maxLat+buffer},{minLon-buffer:maxLon+buffer})
lat=f->lat({minLat-buffer:maxLat+buffer})
lon=f->lon({minLon-buffer:maxLon+buffer})
minPSL=min(PSL)
maxDZ300500=max(DZ300500)

dims = dimsizes(PSL)
x1d = ndtooned(PSL)      ; convert 2D array to 1D for use in minind
inds = ind_resolve(minind (x1d), dims)    ; convert 1D array back to 2D 
ilat = inds(0,0)        ; select the latitude index where the X array is at its' minimum  
ilon = inds(0,1)        ; select the longitude index where the X array is at its' minimum  
PSLmin_lat = PSL&lat(ilat)   ; insert the latitude index into the lat coordinate variable
PSLmin_lon = PSL&lon(ilon)   ; insert the longitude index into the lon coordinate variable
print("Minimum value located at "+PSLmin_lat+", "+PSLmin_lon) 

dims = dimsizes(DZ300500)
x1d = ndtooned(DZ300500)      ; convert 2D array to 1D for use in minind
inds = ind_resolve(maxind (x1d), dims)    ; convert 1D array back to 2D 
ilat = inds(0,0)        ; select the latitude index where the X array is at its' minimum  
ilon = inds(0,1)        ; select the longitude index where the X array is at its' minimum  
DZ300500max_lat = DZ300500&lat(ilat)   ; insert the latitude index into the lat coordinate variable
DZ300500max_lon = DZ300500&lon(ilon)   ; insert the longitude index into the lon coordinate variable
print("Minimum value located at "+DZ300500max_lat+", "+DZ300500max_lon) 

wks = gsn_open_wks(outType,"DZ300500_max")          ; send graphics to PNG file
gsn_define_colormap(wks,"WhiteYellowOrangeRed")   ; choose colormap

allres                   = True
allres@gsnDraw=False
allres@gsnFrame=False
allres@gsnAddCyclic=False
allres@tiMainString=""

res=allres
res@lbLabelBarOn = False
res@gsnSpreadColors     = True         ; Use full colormap, but start
res@cnFillOn            = True         ; Turn on contour fill
res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@mpMinLatF              = minLat
res@mpMaxLatF              = maxLat
res@mpMinLonF              = minLon
res@mpMaxLonF              = maxLon
res@mpGeophysicalLineColor = "Black"
res@mpGeophysicalLineThicknessF = 2.0
res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = min(DZ300500)			; set the minimum contour level
res@cnMaxLevelValF  = max(DZ300500)		; set the maximum contour level
res@cnLevelSpacingF = (res@cnMaxLevelValF -res@cnMinLevelValF )/20	; set the interval between contours

 ; Turn off tickmarks and labels 
res@tmXTOn = False
res@tmYROn = False
res@tmXBOn = False
res@tmYLOn = False  

res@gsnLeftString=""
res@gsnRightString=""

dum = new(1,"graphic")
dum2 = new(1,"graphic")
dum3 = new(1,"graphic")

res2=allres
res2@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res2@cnLevels    = (/ maxDZ300500+wcFOmag /)	; set levels
res2@cnLineLabelsOn       = False
res2@cnInfoLabelOn = False 
res2@cnLineThicknessF = 4.	       ; doubles thickness of zero contour
plot = gsn_csm_contour_map_overlay(wks,DZ300500,DZ300500,res,res2)

clat = new(100,float)
clon = new(100,float)
nggcog(tofloat(DZ300500max_lat),tofloat(DZ300500max_lon),wcFOdist,clat,clon)
circleres=True
circleres@gsLineColor = "black"
circleres@gsLineThicknessF = 5.0
circleres@gsLineDashPattern = 2
dum = gsn_add_polyline(wks, plot, clon, clat, circleres)

polyres=True
polyres@gsMarkerColor="white"
polyres@gsMarkerIndex = 16 
polyres@gsMarkerSizeF = 8 
dum2 = gsn_add_polymarker(wks, plot, DZ300500max_lon, DZ300500max_lat, polyres)

tres                      = True                ; text mods desired
tres@txFontHeightF        = 0.018               ; make smaller
tres@amJust           = "TopCenter"
dum3 = gsn_add_text(wks,plot,sprintf("%4.0f",maxDZ300500),DZ300500max_lon,DZ300500max_lat-.5,tres)

draw(plot)
frame(wks)

wks = gsn_open_wks(outType,"PSL_min")          ; send graphics to PNG file
gsn_define_colormap(wks,"WhiteBlue")   ; choose colormap

allres                   = True
allres@gsnDraw=False
allres@gsnFrame=False
allres@gsnAddCyclic=False
allres@tiMainString=""

res=allres
res@lbLabelBarOn = False
res@gsnSpreadColors     = True         ; Use full colormap, but start
res@cnFillOn            = True         ; Turn on contour fill
res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@mpMinLatF              = minLat
res@mpMaxLatF              = maxLat
res@mpMinLonF              = minLon
res@mpMaxLonF              = maxLon
res@mpGeophysicalLineColor = "White"
res@mpGeophysicalLineThicknessF = 2.0
res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = min(PSL)			; set the minimum contour level
res@cnMaxLevelValF  = max(PSL)		; set the maximum contour level
res@cnLevelSpacingF =  (res@cnMaxLevelValF -res@cnMinLevelValF )/20		; set the interval between contours

 ; Turn off tickmarks and labels 
res@tmXTOn = False
res@tmYROn = False
res@tmXBOn = False
res@tmYLOn = False  

res@gsnLeftString=""
res@gsnRightString=""

dum = new(1,"graphic")
dum2 = new(1,"graphic")
dum3 = new(1,"graphic")

res2=allres
res2@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res2@cnLevels    = (/ minPSL+pslFOmag /)	; set levels
res2@cnLineLabelsOn       = False
res2@cnInfoLabelOn = False 
res2@cnLineThicknessF = 4.	       ; doubles thickness of zero contour
plot = gsn_csm_contour_map_overlay(wks,PSL,PSL,res,res2)

clat = new(100,float)
clon = new(100,float)
nggcog(tofloat(PSLmin_lat),tofloat(PSLmin_lon),pslFOdist,clat,clon)
circleres=True
circleres@gsLineColor = "black"
circleres@gsLineThicknessF = 5.0
circleres@gsLineDashPattern = 2
dum = gsn_add_polyline(wks, plot, clon, clat, circleres)

polyres=True
polyres@gsMarkerColor="red"
polyres@gsMarkerIndex = 16 
polyres@gsMarkerSizeF = 8 
dum2 = gsn_add_polymarker(wks, plot, PSLmin_lon, PSLmin_lat, polyres)

tres                      = True                ; text mods desired
tres@txFontHeightF        = 0.018               ; make smaller
tres@amJust           = "TopCenter"
dum3 = gsn_add_text(wks,plot,sprintf("%4.0f",minPSL),PSLmin_lon,PSLmin_lat-.5,tres)

draw(plot)
frame(wks)

end

