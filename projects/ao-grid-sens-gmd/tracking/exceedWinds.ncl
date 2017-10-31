load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"

begin 

styr=1980
enyr=2004
thresholding="cat3"
wind_factor = "log"
out_type="pdf"
thresh=17.5

if thresholding .eq. "cat3" then
  thresh=50.
  plotTitle="Cat. 3 (50 m s~S~-1~N~) exceedances per year"
  panelLabel="a."
end if
if thresholding .eq. "cat4" then
  thresh=59.
  plotTitle="Cat. 4 (59 m s~S~-1~N~) exceedances per year"
  panelLabel="b."
end if

; Get wind factor to correct from UBOT to U10
factor = surfaceWindCorrFactor(-1,-1,wind_factor)

nyears=enyr-styr+1
fq1arr=new((/2,nyears/),"integer")
fq1arr=0
legLabels=(/"ne120_gx1v6","ne120_ne120"/)  


do z = 0,1
  if z .eq. 0 then             
    f1=addfile("FAMIPC5_ne120_79to05_03_omp2_10m_tracfile.nc","r")
  else
    f1=addfile("f.e13.FAMIPC5.ne120_ne120.1979_2012.002_tracfile.nc","r")
  end if
  wind1=f1->wind*factor
  windSize=dimsizes(wind1)
  nstorms=windSize(0)
  ntimes=windSize(1)
  delete(windSize)

  time1=f1->source_time
  utctime1=cd_calendar(time1,0)
  yyyy1=utctime1(:,:,0)

  do i = 0,nstorms-1
  do j = 0,ntimes-1
    if (.not.ismissing(wind1(i,j)) .and. wind1(i,j) .ge. thresh) then
      thisYear=toint(yyyy1(i,j))
      if (thisYear .ge. styr .AND. thisYear .le. enyr) then
        fq1arr(z,thisYear-styr) = fq1arr(z,thisYear-styr)+1
      end if
    end if
  end do
  end do

  delete([/wind1,nstorms,ntimes,time1,utctime1,yyyy1/])

end do

  print("avg of index 0: "+dim_avg_Wrap(fq1arr(0,:)))
  print("avg of index 1: "+dim_avg_Wrap(fq1arr(1,:)))

;************************************************
; plotting parameters
;************************************************
 wks   = gsn_open_wks (out_type,"fig_u10exceed_"+thresholding)                  ; open workstation

 res                   = True                      ; plot mods desired
 res@gsnDraw=False
 res@gsnFrame=False

 res@xyLineThicknesses = (/6.0,6.0/)               ; make 2nd lines thicker
 res@xyLineColors      = (/"blue","red"/)          ; change line color
 res@xyMarkerColors      = res@xyLineColors          ; change line color
 res@xyDashPattern = 0               ; Make curves all solid
 res@xyMarkLineMode = "MarkLines"    ; Markers *and* lines
 res@xyMarkers      = (/4,16/)    ; 3 different markers
 res@xyMarkerSizes = (/0.018,0.018/)

;;; LEGEND
  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of

  res@pmLegendWidthF         = 0.13                ; Change width and
  res@pmLegendHeightF        = 0.08                ; height of legend.
  res@lgPerimOn              = False               ; turn off box around
  res@lgLabelFontHeightF     = .018                 ; label font height
  res@xyExplicitLegendLabels = legLabels
  res@pmLegendParallelPosF   = res@pmLegendWidthF + 0.15   ; pos coeff moves right, neg moves left
  res@pmLegendOrthogonalPosF = -0.13 - (2.0*res@pmLegendHeightF) ;neg coeff moves down, pos moves up

  res@tiMainString     = plotTitle
  res@tiXAxisString    = "Year"    ; y-axis label      
  res@tiYAxisString    = "Occurrences"    ; y-axis label      
  
 plot  = gsn_csm_xy (wks,ispan(styr,enyr,1),fq1arr,res) ; create plot

  amres = True
  txres=True
  txres@txBackgroundFillColor = -1
  txres@txFontHeightF = .035
  txres@txFontColor = "Black"
  txres@txPerimOn = True
  txid1 = gsn_create_text(wks,panelLabel,txres)

  amres@amParallelPosF   = 0.36    ; This is the right edge of the plot.
  amres@amOrthogonalPosF = 0.48    ; This is the bottom edge of the plot.
  amres@amOrthogonalPosF = amres@amOrthogonalPosF*-1
  amres@amJust           = "TopLeft"

  annoid1 = gsn_add_annotation(plot, txid1, amres)

draw(plot)
frame(wks)

end
