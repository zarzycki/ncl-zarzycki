;========================================================
; Reads a trajectory file and calculates the fraction of CW
; under TC center due to new parameterization and due to fluxes
; outputs a NetCDF file which contains these fractions to be plotted
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

nboxes=10
minSST=295.
maxSST=305.
mindSST=-6.0    ; use -6 for 0.25 or 1.0 box, -3-4 for 5.0 box
maxdSST=0.0
dateix=1
dateix=1   ; 0 = right under TC, 1 = 1d follow, 2 = 2d follow
boxix=1   ; 0 = 0.25, 1 = 1.0, 2 = 5.0

arr1=new((/nboxes,nboxes,50000/),"float")
arrdSST1=new((/nboxes,50000/),"float")

SSTarr=fspan(minSST,maxSST,nboxes)
dSSTarr=fspan(mindSST,maxdSST,nboxes)

arr1!0="SST"
arr1!1="dSST"
arr1!2="Storms"
arr1&SST=SSTarr
arr1&dSST=dSSTarr

arrdSST1!0="dSST"
arrdSST1!1="Storms"
arrdSST1&dSST=dSSTarr

arr2=arr1
arrdSST2=arrdSST1
; =========================================================
af=addfile("dSST_offline_SSTA_fixedSST_.nc","r")

a_pres=af->traj_pres
a_wind=af->traj_wind
a_SST=af->SST(:,dateix,boxix)
a_dSST=af->dSST(:,dateix,boxix)
a_SST=a_SST-a_dSST
a_SST=where(a_SST.le.minSST,minSST,a_SST)
a_SST=where(a_SST.ge.maxSST,maxSST,a_SST)
a_dSST=where(a_dSST.le.mindSST,mindSST,a_dSST)
a_dSST=where(a_dSST.ge.maxdSST,maxdSST,a_dSST)

;counter=0
do i = 0,dimsizes(a_pres)-1
  if(.not.ismissing(a_pres(i)) .and. .not.ismissing(a_SST(i)) .and. .not.ismissing(a_dSST(i))) then
    ;print("SST "+a_SST(i)+"  dSST "+a_dSST(i))
    arr1({a_SST(i)},{a_dSST(i)},i)=(/a_pres(i)/)
    arrdSST1({a_dSST(i)},i)=(/a_pres(i)/)
    ;counter=counter+1
    ;print(counter+"")
  end if
end do

arr1avg=dim_avg_n_Wrap(arr1,2)
;avg11=dim_avg_n_Wrap(arr1,0)
;avg21=dim_avg_n_Wrap(avg11,1)

;arr1avg=dim_avg_n_Wrap(arrdSST1,1)
; =========================================================
bf=addfile("dSST_offline_SSTA_slab_.nc","r")

b_pres=bf->traj_pres
b_wind=bf->traj_wind
b_SST=bf->SST(:,dateix,boxix)
b_dSST=bf->dSST(:,dateix,boxix)
b_SST=b_SST-b_dSST
b_SST=where(b_SST.le.minSST,minSST,b_SST)
b_SST=where(b_SST.ge.maxSST,maxSST,b_SST)
b_dSST=where(b_dSST.le.mindSST,mindSST,b_dSST)
b_dSST=where(b_dSST.ge.maxdSST,maxdSST,b_dSST)

do i = 0,dimsizes(b_pres)-1
  if(.not.ismissing(b_pres(i)) .and. .not.ismissing(b_SST(i)) .and. .not.ismissing(b_dSST(i))) then
    arr2({b_SST(i)},{b_dSST(i)},i)=(/b_pres(i)/)
    arrdSST2({b_dSST(i)},i)=(/b_pres(i)/)
  end if
end do

arr2avg=dim_avg_n_Wrap(arr2,2)
;avg12=dim_avg_n_Wrap(arr2,0)
;avg22=dim_avg_n_Wrap(avg12,1)

;arr2avg=dim_avg_n_Wrap(arrdSST2,1)

; =========================================================

arrdiff = arr1avg
arrdiff = arr1avg-arr2avg

;arrdiff = avg22
;arrdiff = avg21-avg22


wks   = gsn_open_wks ("pdf", "pdf/sst-delPSA-2D")        ; send graphics to PNG file

res                 = True                    ; plot mods desired
res@gsnDraw=False
res@gsnFrame=False

res@cnFillOn        = True                    ; turn on color


res@tiMainString  = ""     ; title
res@tiYAxisString = "SST~B~climo~N~ (K)"  ; xaxis
res@tiXAxisString = "SSTA (K)"                  ; yaxis


res@cnFillMode = "RasterFill"
res@cnLinesOn = False

res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -20.
res@cnMaxLevelValF = 0.
res@cnLevelSpacingF = 2.

res@lbOrientation = "vertical"
res@lbTitleString        = "~F33~D~F21~SLP (hPa)" ; bar title
res@lbTitlePosition      = "Left"                           ; title location
res@lbTitleDirection     = "Across"                          ; letter angle
res@lbTitleAngleF        = 90.                               ; title angle
res@lbTitleFontHeightF   = 0.02                              ; font height

res@tmYLPrecision = 3

cmap = read_colormap_file("MPL_YlOrRd")
res@cnSpanFillPalette=True
res@cnFillPalette = cmap(::-1,:)    ; Skips the first two colors

res@trXMinF = -6.4
res@trXMaxF = 0.0
res@trYMinF = 295.6
res@trYMaxF = 304.4

;symMinMaxPlt (arrdiff,20,False,res) 
plot = gsn_csm_contour(wks, arrdiff, res)


txres                       = True
txres@txPerimOn             = True
txres@txFontHeightF         = 0.04
amres_tr                  = True
amres_tr@amParallelPosF   =  -0.48    ; This is the right edge of the plot.
amres_tr@amOrthogonalPosF = 0.48    ; This is the top edge of the plot.
amres_tr@amJust           = "BottomLeft"
txres@txBackgroundFillColor = "White"
txid = gsn_create_text(wks, "a.", txres)
amid = gsn_add_annotation(plot, txid, amres_tr)

draw(plot)
frame(wks)

;plot  = gsn_csm_xy (wks,arrdiff,dSSTarr,res)                    ; create plot
wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

