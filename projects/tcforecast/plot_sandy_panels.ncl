; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

iniyear=2012
inimon=10
iniday=29
inihour=12
inisec=00000
filename="/glade/u/home/zarzycki/scratch/sewx/_2012/"+iniyear+inimon+iniday+inihour+"/tcforecast_60_x4.cam.h0.2012-10-30-00000.nc"
thefile = addfile(filename,"r")
time = thefile->time

iniyearstr = sprinti("%04d",iniyear)
inimonstr = sprinti("%02d",inimon)
inidaystr = sprinti("%02d",iniday)
inisecstr = sprinti("%05d",inisec)
inihourstr = sprinti("%02d",toint(inisec)/3600)
inihoursince = cd_inv_calendar(toint(iniyearstr),toint(inimonstr),toint(inidaystr),toint(inihourstr),0,0,"hours", 0)

date = ut_inv_calendar(toint(iniyearstr),toint(inimonstr),toint(inidaystr),toint(inihourstr),0,0,time@units, 0)

;
print(date)

u850 = thefile->U850
v850 = thefile->V850
mslp = thefile->PSL/100

copy_VarCoords(u850,mslp)
printVarSummary(u850)
printVarSummary(mslp)

wind = u850
wind = sqrt(u850^2 + v850^2)

out_type = "pdf"
wks = gsn_open_wks(out_type,"sandy_"+iniyear+inimon+iniday+inihour)
gsn_define_colormap(wks,"WhBlGrYeRe")

maxlat = 55.           ; choose subregion           
minlat = 20.
maxlon = 310. 
minlon = 275.

;maxlat = 90.           ; choose subregion           
;minlat = -90.
;maxlon = 360. 
;minlon = 0

;----------- Global resources -----------------------------------------

res                 = True

res@gsnDraw      = False                        ; don't draw yet
res@gsnFrame     = False                        ; don't advance frame yet
res@gsnMaximize = True

res@gsnAddCyclic = False                    ; Don't add a cyclic point.

res@cnFillOn		  = True
res@cnLinesOn   = False 

res@mpFillOn                    = False        ; turn off gray fill
res@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
res@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
res@mpGeophysicalLineThicknessF = 3            ; thickness of outlines

res@mpMaxLatF                   = maxlat           ; choose subregion           
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon 
res@mpMaxLonF = maxlon 
res@mpCenterLonF = (res@mpMinLonF+res@mpMaxLonF)/2.

res@tmXBLabelFontHeightF = 0.010
res@tmYLLabelFontHeightF = 0.010

res@lbLabelBarOn = False

res@gsnSpreadColors      = True
res@gsnLeftString = "Init: "+iniyear+" "+inimon+" "+iniday
res@gsnLeftString=""

res_wind = res

res_wind@cnLevelSelectionMode = "ManualLevels"
res_wind@cnLevelSpacingF      =  4.0 
res_wind@cnMinLevelValF       =  4.0
res_wind@cnMaxLevelValF       =  52.0 
res_wind@lbLabelStride = 2

res_wind@gsnRightString = ""

res_wind@cnLineLabelsOn = False
plotwind = gsn_csm_contour_map(wks,wind(0,:,:),res_wind)

res_mslp = True
res_mslp@gsnDraw          = False           ; don't draw
res_mslp@gsnFrame         = False           ; don't advance frame
res_mslp@cnFillOn		  = False
res_mslp@cnLinesOn   = True
;res_mslp@cnLowLabelsOn = True
res_mslp@cnLowLabelBackgroundColor = -1
res_mslp@cnLabelMasking = False
;res_mslp@cnLowLabelFontColor = "red"
res_mslp@cnLineLabelsOn = False
res_mslp@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res_mslp@cnLevelSpacingF      =  4.0                ;
res_mslp@cnMinLevelValF       =  900.0           ;
res_mslp@cnMaxLevelValF       =  1060.0 ; Use 80.0 -> 60 for this
res_mslp@gsnRightString   = ""    
res_mslp@gsnLeftString    = ""
res_mslp@gsnCenterString  = ""
res_mslp@cnInfoLabelOn = False
res_mslp@cnLineThicknessF = 1.5

;res@tiMainString = "CAM-SE Isaac Init: 00Z 08 21 2012"





plotmslp = gsn_csm_contour(wks,mslp(0,:,:),res_mslp)
overlay(plotwind,plotmslp)

draw(plotwind)

;395N,  745W
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 16            ; choose circle as polymarker
  polyres@gsMarkerSizeF = 12.0           ; select size to avoid streaking
  polyres@gsMarkerColor = (/"black"/)   ; choose color
gsn_polymarker(wks,plotwind,285.5,39.5,polyres)  ; draw polymarkers
  polyres@gsMarkerSizeF = 8.0           ; select size to avoid streaking
  polyres@gsMarkerColor = (/"white"/)   ; choose color
gsn_polymarker(wks,plotwind,285.5,39.5,polyres)  ; draw polymarkers

frame(wks)

;delete(wks)
;delete(res_wind)

end
