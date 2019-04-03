;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "read_csv.ncl"
load "../../../functions/trackDensity.ncl"

begin

file1=read_CSV_f("LF.trajectories.txt.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.ALL")
file2=read_CSV_f("LF.ibtracs-2003-2015-GLOB.txt")

printVarSummary(file1)

lon1=file1(:,0)
lat1=file1(:,1)

lon2=file2(:,0)
lat2=file2(:,1)

lon1 = where(lon1.gt.330.,lon1@_FillValue,lon1)
lat1 = where(lon1.gt.330.,lat1@_FillValue,lat1)
lon2 = where(lon2.gt.330.,lon2@_FillValue,lon2)
lat2 = where(lon2.gt.330.,lat2@_FillValue,lat2)

lon1 = where(lat1.gt.30.,lon1@_FillValue,lon1)
lat1 = where(lat1.gt.30.,lat1@_FillValue,lat1)

print(min(lon2)+" "+max(lon2))
print(min(lat2)+" "+max(lat2))

opt_lat         = True
opt_lat@bin_min =  10.
opt_lat@bin_max =  50.
lat1_pdf=pdfx(lat1,20,opt_lat)
lat2_pdf=pdfx(lat2,20,opt_lat)
print(escorc(lat1_pdf,lat2_pdf))

opt_lon         = True
opt_lon@bin_min =  260.
opt_lon@bin_max =  300.
lon1_pdf=pdfx(lon1,20,opt_lon)
lon2_pdf=pdfx(lon2,20,opt_lon)
print(escorc(lon1_pdf,lon2_pdf))

gridsize=8.0
trackdens1 = track_density(gridsize,0.0,lat1,lon1,True)
trackdens1 = trackdens1/3.
trackdens2 = track_density(gridsize,0.0,lat2,lon2,True)


trackdens1= where(ismissing(trackdens1) .and. .not.ismissing(trackdens2),0,trackdens1)
trackdens1= where(ismissing(trackdens1) .and. .not.ismissing(trackdens2),0,trackdens1)
;trackdens1= where(ismissing(trackdens1),trackdens1@_FillValue,1)
;trackdens1=-trackdens1

patterncorr = pattern_cor(trackdens1,trackdens2,1.,0)
print(patterncorr)
print(escorc(ndtooned(trackdens1),ndtooned(trackdens2)))


;************************************************
; create plot
;************************************************
plotname = "landfall_dens"
out_type="x11"
wks = gsn_open_wks(out_type,plotname)
plot = new(2,"graphic")

colorMap1="WhiteBlueGreenYellowRed"

res                       = True     ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False
res@gsnAddCyclic          = False

res@cnFillOn              = True     ; turn on color fill
res@cnFillMode            = "RasterFill"       ; Raster Mode
res@cnLinesOn             = False    ; turn of contour lines
res@cnLineLabelsOn  = False
res@lbLabelStride = 2
res@gsnCenterString       = ""

res@mpMinLatF             = 5.
res@mpMaxLatF             = 55.
res@mpMinLonF             = 260.
res@mpMaxLonF             = 350.
res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 0.
res@cnMaxLevelValF        = 20.0
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 10.
res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,trackdens1(:,:),res)
plot(1) = gsn_csm_contour_map_ce(wks,trackdens2(:,:),res)

resP = True
resP@txString           = "Annual TC track density, all storms"
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"1","2"/)
gsn_panel(wks,plot,(/2,1/),resP)

end