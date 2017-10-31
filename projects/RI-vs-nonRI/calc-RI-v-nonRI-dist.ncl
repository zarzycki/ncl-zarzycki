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

; cat 1994/traj_out.txt 1995/traj_out.txt 1996/traj_out.txt 1997/traj_out.txt 1998/traj_out.txt 1999/traj_out.txt 2000/traj_out.txt 2001/traj_out.txt 2002/traj_out.txt 2003/traj_out.txt 2004/traj_out.txt 2005/traj_out.txt > ~/cam5_1_amip_run9.ens.txt

begin

output_type="pdf"

maskBasin=-9  ;if <=0, don't mask, otherwise pick basin
; 1 = ATL, 2 = EPAC, 3 = CPAC, 4 = WPAC, 5 = NIO, 6 = SIO, 7 = SPAC, 8 = SATL
maskGenesis=False ; if True, pick start pt, if False, pick most intense

RIthresh=35. ;kts/24 hours
nbins=40
dosmooth=True
outStrHead="cam5_1_amip_ens"
factor = surfaceWindCorrFactor(-1,-1,"log")
ms_to_kts = 1.94384

;joint pdf settings
doLog=True
doBefore=False

thefile="cam5_1_amip_run9.ens.txt"
outStrHead=thefile
ncols = 12                     ; assign number of columns
maxLines = -1
traj_data = getTrajectories(thefile,ncols,maxLines)

lon = traj_data(:,0,:)
lat = traj_data(:,1,:)
wind = traj_data(:,2,:)*factor
wind = wind*ms_to_kts
windori = traj_data(:,2,:)
pres = traj_data(:,7,:)
yyyy = traj_data(:,8,:)
mm = traj_data(:,9,:)
dd = traj_data(:,10,:)
hh = traj_data(:,11,:)

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

intenseRate06=new((/nstorms,ntimes/),"float")
intenseRate12=new((/nstorms,ntimes/),"float")
intenseRate24=new((/nstorms,ntimes/),"float")


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
  do jj = 0,ntimes-1
    if (jj .ge. 1) then
      intenseRate06(ii,jj)=(wind(ii,jj)-wind(ii,jj-1))*4    ; calculate backward diff over 6 hours (1 steps)
    end if    
    if (jj .ge. 2) then
      intenseRate12(ii,jj)=(wind(ii,jj)-wind(ii,jj-2))*2    ; calculate backward diff over 12 hours (3 steps)
    end if
    if (jj .ge. 4) then
      intenseRate24(ii,jj)=wind(ii,jj)-wind(ii,jj-4)        ; calculate backward diff over 24 hours (5 steps)
    end if
  end do
  isRI(ii)=any(intenseRate24(ii,:).ge.RIthresh)
  LMI(ii)=max(wind(ii,:))
  end if
end do

; Filter LMI by isRI
LMI_RI=where(isRI.eq.True,LMI,LMI@_FillValue)
LMI_noRI=where(isRI.eq.False,LMI,LMI@_FillValue)

; Calculate percentage of total storms that undergo RI at least once
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


; Generate joint pdf

if(doBefore) then
  pdf2 = pdfxy(ndtooned(wind)-ndtooned(intenseRate24),ndtooned(intenseRate24), 40, 40, False)
else
  pdf2 = pdfxy(ndtooned(wind),ndtooned(intenseRate24), 40, 40, False)
end if

pdf2 = where(pdf2.eq.0,pdf2@_FillValue,pdf2)
printVarSummary(pdf2)

delim="     "
outName="RItraj_"+thefile
system("rm "+outName)
quote = inttochar(34)
do ii = 0,nstorms-1
;do ii = 0,3
 system("echo "+quote+ "start"+delim+yyyy(ii,0)+delim+mm(ii,0)+delim+dd(ii,0)+delim+hh(ii,0)+quote+">> "+outName)
 do jj = 0,ntimes-1
   if (.not.ismissing(lat(ii,jj)))
     system("echo "+quote+ lon(ii,jj)+delim+lat(ii,jj)+delim+wind(ii,jj)+delim+windori(ii,jj)+delim+pres(ii,jj)+delim+intenseRate24(ii,jj)+delim+intenseRate12(ii,jj)+delim+intenseRate06(ii,jj)+delim+yyyy(ii,jj)+delim+mm(ii,jj)+delim+dd(ii,jj)+delim+hh(ii,jj)+quote+" >> "+outName)
   end if
 end do
end do

exit

if(doLog) then
  logstr="log"
else
  logstr="lin"
end if

if(doBefore) then
  intenseTimeStr="before"
else
  intenseTimeStr="after"
end if

wks  = gsn_open_wks ("pdf","joint_"+intenseTimeStr+"inten_dintens_"+logstr)
colorMap1="MPL_GnBu"
res  = True
res@gsnDraw=False
res@gsnFrame=False

if(doLog) then
  linArr = fspan(min(pdf2),max(pdf2),20)
  res@cnLevelSelectionMode = "ExplicitLevels" 
  res@cnLevels = log(linArr)
end if

res@cnFillPalette=colorMap1
res@gsnCenterString = ""
res@cnFillOn              = True     ; turn on color fill
res@cnFillMode            = "RasterFill"       ; Raster Mode
res@cnLinesOn             = False    ; turn of contour lines
res@cnLineLabelsOn  = False
res@tiYAxisString = "Intens. rate (kts/24 hr)"     ; y axis title
res@tiXAxisString = "Wind speed (kts)"     ; y axis title
res@lbOrientation =   "vertical"          ; vertical label bar

plot = gsn_csm_contour (wks, pdf2, res)
draw(plot)
frame(wks)

delete(plot)
delete(res)
delete(wks)

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