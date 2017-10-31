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
load "~/ncl/functions/mask_tc.ncl"
;========================================================
begin

output_type="pdf"

maskBasin=1  ;if <=0, don't mask, otherwise pick basin
; 1 = ATL, 2 = EPAC, 3 = CPAC, 4 = WPAC, 5 = NIO, 6 = SIO, 7 = SPAC, 8 = SATL
maskGenesis=False ; if True, pick start pt, if False, pick most intense

;RIthresh=35. ;kts/24 hours
nbins=40
dosmooth=True
outStrHead="slab2_dtime900s_nhemi30x4"
factor = surfaceWindCorrFactor(-1,-1,"log")
ms_to_kts = 1.94384

thefile="/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/NOWIND/cat_traj_slab2_900.txt"
ncols = 12                     ; assign number of columns
maxLines = -1
traj_data = getTrajectories(thefile,ncols,maxLines)

lon = traj_data(:,3,:)
lat = traj_data(:,4,:)
wind = traj_data(:,5,:)*factor
wind = wind*ms_to_kts
pres = traj_data(:,7,:)/100.

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

intenseRate=new((/nstorms,ntimes/),"float")


if (maskBasin .gt. 0) then
  tcMask=mask_tc(0,-999.,-999.,1.0,360)
  do ii = 0,nstorms-1
    ; Find index we need to mask by
    if (maskGenesis) then
      ix=0   ; if genesis, just pick first traj pt
    else
      ix=maxind(wind(ii,:))   ; otherwise, find index of max intensity
    end if
    ; if mask is NOT equal to mask index, set all values to missing
    if (tcMask({lat(ii,ix)},{lon(ii,ix)}) .ne. maskBasin)
      lat(ii,:)=lat@_FillValue
      lon(ii,:)=lon@_FillValue
      wind(ii,:)=wind@_FillValue
    end if
  end do

  ;Should probably wrap this into mask_tc at some point
  if (maskBasin .eq. 1) then
    basinStr="NATL"
  else if (maskBasin .eq. 2) then
    basinStr="EPAC"
  else if (maskBasin .eq. 3) then
    basinStr="CPAC"
  else if (maskBasin .eq. 4) then
    basinStr="WPAC"
  else if (maskBasin .eq. 5) then
    basinStr="NIO"
  else if (maskBasin .eq. 6) then
    basinStr="SIO"
  else if (maskBasin .eq. 7) then
    basinStr="SPAC"
  else if (maskBasin .eq. 8) then
    basinStr="SATL"
  else
    basinStr="NHEMI"
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
else
  basinStr="NHEMI"
end if

isRI=new(nstorms,"logical")
isRI=False

LMI=new(nstorms,"float")

stormCount=0
do ii = 0,nstorms-1
  if (.not.ismissing(lat(ii,0)))
  stormCount=stormCount+1
  do jj = 4,ntimes-1
    intenseRate(ii,jj)=wind(ii,jj)-wind(ii,jj-4)    ; calculate backward diff over 24 hours (5 steps)
  end do
  isRI(ii)=any(intenseRate(ii,:).ge.RIthresh)
  LMI(ii)=max(wind(ii,:))
  print(isRI(ii)+" "+LMI(ii))
  end if
end do

LMI_RI=where(isRI.eq.True,LMI,LMI@_FillValue)
LMI_noRI=where(isRI.eq.False,LMI,LMI@_FillValue)


perc_RI = tofloat(num(LMI_RI))/stormCount
print(perc_RI)

binSettings=True
binSettings@bin_min=0.0
binSettings@bin_max=200.0

ap  = pdfx(LMI, nbins, binSettings)
bp  = pdfx(LMI_noRI, nbins, binSettings)
bp  = bp*(1-perc_RI)
cp  = pdfx(LMI_RI, nbins, binSettings)
cp  = cp*(perc_RI)

if (dosmooth) then
  nave = 3
  opt = 1
  ap = runave_Wrap(ap,nave,opt)
  bp = runave_Wrap(bp,nave,opt)
  cp = runave_Wrap(cp,nave,opt)
end if

nVar    = 3
nBin    = ap@nbins          ; retrieve the number of bins

xx      = new ( (/nVar, nBin/), typeof(ap))
xx(0,:) = ap@bin_center
xx(1,:) = bp@bin_center
xx(2,:) = cp@bin_center

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap /)
yy(1,:) = (/ bp /)
yy(2,:) = (/ cp /)

wks  = gsn_open_wks (output_type,"pdf/"+outStrHead+"_"+basinStr+"_RIvNORI_thres_"+toint(RIthresh))
plot = new(1,graphic)

res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/6.0,6.0,6.0,6.0/)
res@xyLineColors             = (/"black","blue","red"/)
res@xyMonoDashPattern        = True              ; all solid
res@tiYAxisString            = "PDF (%)"

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of

res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height

res@xyExplicitLegendLabels = (/"ALL ("+stormCount+")","NON-RI ("+num(LMI_noRI)+")","RI ("+num(LMI_RI)+")"/)  ; create explicit labels

res@tmXBPrecision = 2 ; Precision on x-axis always 2 (XX m/s)

res@pmLegendParallelPosF   = .75                 ; move units right
res@pmLegendOrthogonalPosF = -0.6                ; move units down
res@tiXAxisString ="Max intensity (kts)"
res@tiMainString  = "PDF: RI thresh="+toint(RIthresh)+" kts/24hr_"+basinStr   ; title

res@trXMinF           = 0.
res@trXMaxF           = 200.
plot(0) = gsn_csm_xy (wks, xx, yy, res)

res@tiYAxisString = "Frequency (%)"     ; y axis title

resP=True

resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.025

gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot

end