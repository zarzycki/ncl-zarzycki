;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

fileDir="/glade/scratch/zarzycki/LES-snow/storm-files/"
config="tempest"
LWE="12"
yearsArr=(/"5","10","12","15","20","30"/)
ncases=dimsizes(yearsArr)
slice=2071

do ii = 0,ncases-1
  configStr="5e-9_"+LWE+"_"+yearsArr(ii)
  all_files = systemfunc("ls "+fileDir+"/"+configStr+"/frac.tempest.LENS."+slice+"*"+configStr+".nc")
  f1 = addfiles (all_files, "r")
  ListSetType (f1, "join") 
  STORMFRAC_ALL = f1[:]->STORMFRAC   ; note syntax [:]
  DOUBLEFRAC_ALL = f1[:]->DOUBLEFRAC   ; note syntax [:]
  
  STORMFRAC=dim_avg_n_Wrap(STORMFRAC_ALL,0)
  DOUBLEFRAC=dim_avg_n_Wrap(DOUBLEFRAC_ALL,0)
  
  STORMFRAC=STORMFRAC*100.
  DOUBLEFRAC=DOUBLEFRAC*100.
  
  if (ii .eq. 0)
    ndims=dimsizes(STORMFRAC)
    nlat=ndims(0)
    nlon=ndims(1)
    ensavg=new((/ncases,nlat,nlon/),typeof(STORMFRAC))
    ensavg!1="lat"
    ensavg!2="lon"
    ensavg&lat=STORMFRAC&lat
    ensavg&lon=STORMFRAC&lon
    doubleavg=ensavg
    ;delete([/nlat,nlon,ndims/])
  end if
  ensavg(ii,:,:)=STORMFRAC
  doubleavg(ii,:,:)=DOUBLEFRAC
  delete([/STORMFRAC,DOUBLEFRAC,f1/])
end do

maskfile=addfile("/glade/u/home/zarzycki/snow-tracking/calc_RSI/NEmask.nc","r")
RSIOUT=maskfile->MASK
printVarSummary(RSIOUT)
MASKNATIVE=linint2_Wrap(RSIOUT&lon+360.,RSIOUT&lat,RSIOUT,False,ensavg&lon,ensavg&lat, 0)

ENSAVG_MASK=linint2_Wrap(ensavg&lon,ensavg&lat,ensavg,False,RSIOUT&lon+360.,RSIOUT&lat, 0)
DOUBLEAVG_MASK=linint2_Wrap(doubleavg&lon,doubleavg&lat,doubleavg,False,RSIOUT&lon+360.,RSIOUT&lat, 0)
delete(ensavg)
delete(doubleavg)

ENSAVG_MASK!1="lat"
ENSAVG_MASK!2="lon"
thislon=RSIOUT&lon+360.
thislon@units="degrees_east"
ENSAVG_MASK&lon=thislon
copy_VarCoords(ENSAVG_MASK,DOUBLEAVG_MASK)

do jj = 0,ncases-1
  ENSAVG_MASK(jj,:,:)=where(RSIOUT.gt.0.5,ENSAVG_MASK(jj,:,:),ENSAVG_MASK@_FillValue)
  DOUBLEAVG_MASK(jj,:,:)=where(RSIOUT.gt.0.5,DOUBLEAVG_MASK(jj,:,:),DOUBLEAVG_MASK@_FillValue)
end do
ensavg=ENSAVG_MASK
doubleavg=DOUBLEAVG_MASK

; note, we have to halve doubleavg since half of the error isn't really an error!
doubleavg = doubleavg/2.

; PLOT FRAC
nplots=ncases

wks = gsn_open_wks("pdf","pl_rad_sens")               ; open workstation
map = new(nplots,"graphic")

res                     = True         ; plot modifications desired
res@gsnDraw=False
res@gsnFrame=False

res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;res@mpOceanFillColor = "White"
;res@cnFillDrawOrder             = "PreDraw"
;res@cnLineDrawOrder             = "PreDraw"
;res@mpFillAreaSpecifiers        = (/"Land"/)
;res@mpSpecifiedFillColors       = (/"transparent"/)
;res@mpOutlineDrawOrder = "Draw"

res@cnFillPalette        = "BkBlAqGrYeOrReViWh200"              ; choose colormap
res@cnSpanFillPalette=True

;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

res@mpMinLatF             = 38.
res@mpMaxLatF             = 48.
res@mpMinLonF             = 279.
res@mpMaxLonF             = 293.
res@mpCenterLonF = 286.

res@lbLabelBarOn        = False 

res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 1.0  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 1.0
res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)

res@gsnStringFontHeightF=0.027

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 20.			; set the minimum contour level
res@cnMaxLevelValF  = 100.			; set the maximum contour level
res@cnLevelSpacingF = 5.0			; set the interval between contours

res@lbLabelStride = 2

resdouble=res
resdouble@cnFillPalette        = "WhiteBlueGreenYellowRed"              ; choose colormap
resdouble@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
resdouble@cnMinLevelValF  = 1			; set the minimum contour level
resdouble@cnMaxLevelValF  = 12.			; set the maximum contour level
resdouble@cnLevelSpacingF = 1.0			; set the interval between contours

resdouble@gsnRightString="%"
resdouble@gsnLeftString="Percent error"
do zz = 0,ncases-1
  resdouble@gsnCenterString="r~B~P~N~="+yearsArr(zz)+"~S~o~N~"
  map(zz) = gsn_csm_contour_map_ce(wks,doubleavg(zz,:,:),resdouble)
end do

res_outline=True
res_outline@gsnDraw=False
res_outline@gsnFrame=False
res_outline@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res_outline@cnLevels    = (/ 0.95 /)      ; set levels
res_outline@cnLineLabelsOn       = False
res_outline@cnInfoLabelOn = False
res_outline@cnLineColor="black"
res_outline@cnLineThicknessF = 5.             ; doubles thickness of zero contour
plotzeroline = new(nplots,graphic)

do zz = 0,nplots-1
  plotzeroline(zz) = gsn_csm_contour(wks,RSIOUT,res_outline)
  overlay(map(zz),plotzeroline(zz))
end do

;************************************************
; create panel
;************************************************
pres                  = True
pres@gsnPanelLabelBar = True
pres@pmLabelBarWidthF = 0.6

;---figure string resources
pres@gsnPanelFigureStringsPerimOn     = False
pres@gsnPanelFigureStringsFontHeightF = 0.01
pres@amJust                           = "TopLeft"

pres@gsnPanelMainString = "Percent annual snowfall flagged with >1 ETC"

fig_strs = (/"a","b","c","d","e","f"/) + ")"
pres@gsnPanelFigureStrings=fig_strs
gsn_panel(wks,map,(/2,3/),pres)





exit

; PLOT FRAC
nplots=ncases*2

wks = gsn_open_wks("x11","pl_rad_sens")               ; open workstation
map = new(nplots,"graphic")

res                     = True         ; plot modifications desired
res@gsnDraw=False
res@gsnFrame=False

res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;res@mpOceanFillColor = "White"
;res@cnFillDrawOrder             = "PreDraw"
;res@cnLineDrawOrder             = "PreDraw"
;res@mpFillAreaSpecifiers        = (/"Land"/)
;res@mpSpecifiedFillColors       = (/"transparent"/)
;res@mpOutlineDrawOrder = "Draw"

res@cnFillPalette        = "BkBlAqGrYeOrReViWh200"              ; choose colormap
res@cnSpanFillPalette=True

;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

res@mpMinLatF             = 38.
res@mpMaxLatF             = 48.
res@mpMinLonF             = 279.
res@mpMaxLonF             = 293.
res@mpCenterLonF = 286.

res@lbLabelBarOn        = False 

res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 1.0  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 1.0
res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)

res@gsnStringFontHeightF=0.027

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 20.			; set the minimum contour level
res@cnMaxLevelValF  = 100.			; set the maximum contour level
res@cnLevelSpacingF = 5.0			; set the interval between contours

res@lbLabelStride = 2

resavg=res

resavg@gsnRightString="%"
resavg@gsnLeftString="Snow due to ETCs"
do zz = 0,ncases-1
  resavg@tiMainString=yearsArr(zz)+"deg"
  map(zz) = gsn_csm_contour_map_ce(wks,ensavg(zz,:,:),resavg)
end do

resdouble=res
resdouble@cnFillPalette        = "WhiteBlueGreenYellowRed"              ; choose colormap
resdouble@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
resdouble@cnMinLevelValF  = 0.			; set the minimum contour level
resdouble@cnMaxLevelValF  = 10.			; set the maximum contour level
resdouble@cnLevelSpacingF = 1.0			; set the interval between contours

resdouble@gsnRightString="%"
resdouble@gsnLeftString="Fraction double counted"
do zz = 0,ncases-1
  yy=zz+ncases
  resdouble@tiMainString=yearsArr(zz)+"deg"
  map(yy) = gsn_csm_contour_map_ce(wks,doubleavg(zz,:,:),resdouble)
end do

res_outline=True
res_outline@gsnDraw=False
res_outline@gsnFrame=False
res_outline@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res_outline@cnLevels    = (/ 0.95 /)      ; set levels
res_outline@cnLineLabelsOn       = False
res_outline@cnInfoLabelOn = False
res_outline@cnLineColor="black"
res_outline@cnLineThicknessF = 5.             ; doubles thickness of zero contour
plotzeroline = new(nplots,graphic)

do zz = 0,nplots-1
  plotzeroline(zz) = gsn_csm_contour(wks,RSIOUT,res_outline)
  overlay(map(zz),plotzeroline(zz))
end do

;************************************************
; create panel
;************************************************
  pres                  = True
  pres@gsnMaximize      = True
  pres@gsnFrame         = False
  pres@gsnPanelLabelBar = True
  pres@pmLabelBarWidthF = 0.6

;
; Panel the first set of plots without drawing them, so we
; can retrieve the bounding boxes and calculate the height.
;
  pres@gsnDraw = False
;
; "gsn_panel_return" is an unadvertised function. It behaves
; the same as "gsn_panel", except it returns all the objects 
; being paneled, including the labelbar if there is one.
;
  pplots = gsn_panel_return(wks,map(0:(ncases-1)),(/1,ncases/),pres)

;
; Retrieve bounding boxes of all objects created by gsn_panel call.
;
; max(bb(:,0)) is the topmost location of all combined objects,
; and min(bb(:,1)) is the bottommost.
;
  bb     = NhlGetBB(pplots)
  height = max(bb(0:(ncases-1),0)) - min(bb(0:(ncases-1),1))

;---Using height value, now we can panel all sets of plots.
  pres@gsnDraw                          = True
  pres@gsnPanelTop                      = 0.9   ; leave room for title
  pres@gsnPanelBottom                   = pres@gsnPanelTop - height

;---figure string resources
  pres@gsnPanelFigureStringsPerimOn     = False
  pres@gsnPanelFigureStringsFontHeightF = 0.01
  pres@amJust                           = "TopLeft"

;---Main title, only on first set of plots
  pres@gsnPanelMainString = "Multiple panels on one page, dummy data, 3 different colormaps"

  fig_strs = (/"a","b","c","d","e","f","g","h","i"/) + ")"
  do n=0,(2*ncases)-1,ncases
    pres@gsnPanelFigureStrings = fig_strs(n:n+2)
    gsn_panel(wks,map(n:n+4),(/1,ncases/),pres)

;---Set for the next panel call.
    pres@gsnPanelMainString = ""
    pres@gsnPanelTop        = pres@gsnPanelBottom
    pres@gsnPanelBottom     = pres@gsnPanelTop-height
  end do

  frame(wks)

end
