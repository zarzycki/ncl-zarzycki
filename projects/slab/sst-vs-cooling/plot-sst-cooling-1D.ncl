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
load "/glade/u/home/zarzycki/ncl/functions/lib.percentiles.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

ncuts=7
minSST=293.
maxSST=307.
mindSST=-6.0
maxdSST=0.0
dateix=1   ; 0 = right under TC, 1 = 1d follow, 2 = 2d follow
boxes = (/1,2/)
nboxes = dimsizes(boxes)
percentiles = (/5.,95./)
npercentiles = dimsizes(percentiles)

arrdiff=new((/nboxes,ncuts/),"float",9.9e-36)
percdiff=new((/nboxes,ncuts,npercentiles/),"float",9.9e-36)

arr1=new((/ncuts,ncuts,50000/),"float",9.9e-36)
arrdSST1=new((/ncuts,50000/),"float",9.9e-36)

SSTarr=fspan(minSST,maxSST,ncuts)
dSSTarr=fspan(mindSST,maxdSST,ncuts)

arr1!0="SST"
arr1!1="dSST"
arr1!2="Storms"
arr1&SST=SSTarr
arr1&dSST=dSSTarr
arrdSST1!0="dSST"
arrdSST1!1="Storms"
arrdSST1&dSST=dSSTarr

do ii = 0,nboxes-1
  boxix=boxes(ii)

  arr1=arr1@_FillValue
  arrdSST1=arrdSST1@_FillValue

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

  avg11=dim_avg_n_Wrap(arr1,0)

  ; calculate mean
  avg21=dim_avg_n_Wrap(avg11,1)

  ; calculate percentiles
  percent_tmp_21 = new((/nboxes,ncuts,npercentiles/),"float",9.9e-36)
  do jj = 0,ncuts-1
    if(.not. all(ismissing(avg11(jj,:)))) then
      percent_tmp_21(ii,jj,:)=percent_to_value(avg11(jj,:),percentiles)
    end if
  end do




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

  avg12=dim_avg_n_Wrap(arr2,0)
  avg22=dim_avg_n_Wrap(avg12,1)

  ; calculate percentiles
  percent_tmp_22 = new((/nboxes,ncuts,npercentiles/),"float",9.9e-36)
  do jj = 0,ncuts-1
    if(.not. all(ismissing(avg12(jj,:)))) then
      percent_tmp_22(ii,jj,:)=percent_to_value(avg12(jj,:),percentiles)
    end if
  end do


 ; ===============================================

  arrdiff(ii,:) = avg21-avg22
  percdiff(ii,:,:) = percent_tmp_21(ii,:,:)-percent_tmp_22(ii,:,:)



  delete(percent_tmp_21)
  delete(percent_tmp_22)
  delete(avg12)
  delete(avg22)
  delete(avg11)
  delete(avg21)



end do

print(arrdiff(0,:))
print(percdiff(0,:,0))
print(percdiff(0,:,1))


plotArray=new((/nboxes*(1+npercentiles),ncuts/),"float",9.9e-36)
do zz = 0,nboxes-1
  plotArray((zz*3),:)=arrdiff(zz,:)
  plotArray((zz*3)+1,:)=percdiff(zz,:,0)
  plotArray((zz*3)+2,:)=percdiff(zz,:,1)
end do

xp    = new( (/nboxes,2*ncuts/), float )
yp    = new( (/2*ncuts/), float )

do k=0,ncuts-1
  yp(k)          = dSSTarr(k)
  yp(2*ncuts-1-k) = dSSTarr(k)
  do yy=0,nboxes-1
    xp(yy,k)          = percdiff(yy,k,0)
    xp(yy,2*ncuts-1-k) = percdiff(yy,k,1)
  end do
end do

wks   = gsn_open_wks ("pdf", "pdf/sst-delPSA-1D")        ; send graphics to PNG file

res                 = True                    ; plot mods desired
res@gsnDraw = False
res@gsnFrame=False

res@xyDashPattern  = 0                         ; Make curves all solid
res@xyMarkLineMode = "Lines"               ; Markers *and* lines
res@xyLineThicknesses = (/  8.0,0.1,0.1,8.0,0.1,0.1/)          ; make second line thicker
res@xyLineColors      = (/"blue","LightBlue","LightBlue","red","Pink","Pink"/)          ; change line color

res@tiMainString  = ""     ; title
res@tiYAxisString = "~F33~D~F21~SLP (hPa)"  ; xaxis
res@tiXAxisString = "SSTA (K)"                  ; yaxis

;res@trXReverse            = True

res@trYMaxF = 6.0
res@trYMinF = -41.0

plot  = gsn_csm_xy (wks,dSSTarr,plotArray,res)                    ; create plot

gsres                   = True                        ; poly res
gsres@gsFillOpacityF = 0.25
gsres@tfPolyDrawOrder   = "Predraw"                   ; draw this first
gsres@gsFillColor       = "LightBlue"                 ; color chosen
dummy1 = gsn_add_polygon (wks,plot,yp,xp(0,:),gsres)
gsres@gsFillColor       = "Pink"                 ; color chosen
dummy2 = gsn_add_polygon (wks,plot,yp,xp(1,:),gsres)



lgres                    = True
lgres@lgLineColors       = (/"blue","red"/)    ; reverse color order in legend
lgres@lgDashIndexes      = (/0,0/)    ; all solid lines
lgres@lgMonoLineThickness = False
lgres@lgLineThicknesses   = (/8.0,8.0/)
lgres@lgLabelFontHeightF = .10           ; legend label font thickness
lgres@lgBoxMinorExtentF  = 0.60          ; adjust legend size
lgres@vpWidthF           = 0.18           ; width of legend (NDC)
lgres@vpHeightF          = 0.12           ; height of legend (NDC)
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
labels = (/"~F33~D~F21~X=1~S~o~N~","~F33~D~F21~X=5~S~o~N~"/)          ; reverse dycore order in legend
legend = gsn_create_legend (wks, 2, labels,lgres)
amres                  = True
amres@amJust           = "BottomLeft"    ; Use bottom right corner of box
amres@amParallelPosF   = -0.32            ; More negative is left
amres@amOrthogonalPosF = 0.46             ; More negative is up
annoid = gsn_add_annotation(plot,legend,amres)  ; add legend to plot

txres                       = True
txres@txPerimOn             = True
txres@txFontHeightF         = 0.04
amres_tr                  = True
amres_tr@amParallelPosF   =  0.48    ; This is the right edge of the plot.
amres_tr@amOrthogonalPosF = 0.48    ; This is the top edge of the plot.
amres_tr@amJust           = "BottomRight"
txres@txBackgroundFillColor = "White"
txid = gsn_create_text(wks, "b.", txres)
amid = gsn_add_annotation(plot, txid, amres_tr)

draw(plot)
frame(wks)
wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

