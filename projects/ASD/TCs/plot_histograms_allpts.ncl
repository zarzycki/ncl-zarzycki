;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"

;========================================================
begin

out_type="png"

files=(/"trajectories.txt.NE0CONUS30X8-EXP211","trajectories.txt.NE30"/)

cutpres=9999.0
factor = surfaceWindCorrFactor(-1,-1,"log")

basinfilt = 1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

do_obs=True

;----------------Constants-----------------------------------

nEntries=5000000
ms_to_kts = 1.94384449

ntempest=dimsizes(files)

if (do_obs) then
  nfiles=ntempest+1
else
  nfiles=ntempest
end if

do ii = 0,ntempest-1

  thefile=files(ii)

  ncols = 9                     ; assign number of columns
  maxLines = -1
  headerDelimStr = "start"
  delimStr="tab"
  isHeader=False
  traj_data = getTrajectories(thefile,ncols,maxLines,headerDelimStr,delimStr,isHeader)

  lon = traj_data(:,1,:)
  lat = traj_data(:,2,:)
  wind = traj_data(:,4,:)*factor
  pres = round(traj_data(:,3,:)/100.,0)

  dpdt = pres

  print("mean lat: "+avg(lat))

  ndims = dimsizes(lon)
  nstorms = ndims(0)
  ntimes = ndims(1)

  pres=where(pres.gt.cutpres,pres@_FillValue,pres)

  do kk = 0,nstorms-1
    orilat=lat(kk,0)
    orilon=min((/lon(kk,0),359.0/))
    if (tcMask({orilat},{orilon}) .ne. basinfilt) then
      lat(kk,:)=lat@_FillValue
      lon(kk,:)=lon@_FillValue
      wind(kk,:)=wind@_FillValue
      pres(kk,:)=pres@_FillValue
    end if
    dpdt(kk,:)=dpdt@_FillValue
    dpdt(kk,1:ntimes-1)=pres(kk,1:ntimes-1)-pres(kk,0:ntimes-2)
    if (.not.(all(ismissing(dpdt(kk,:)))))
      if (any(dpdt(kk,:) .lt. -20.)) then
        print(dpdt(kk,:)+" "+pres(kk,:)+" "+lat(kk,:)+" "+lon(kk,:))
      end if
    end if
  end do

  onedlat=ndtooned(lat)
  onedlon=ndtooned(lon)
  onedwind=ndtooned(wind)
  onedpres=ndtooned(dpdt)

  if (ii .eq. 0)
    traj_lon = new((/nfiles,nEntries/),"float")
    traj_lat = new((/nfiles,nEntries/),"float")
    traj_wind = new((/nfiles,nEntries/),"float")
    traj_pres = new((/nfiles,nEntries/),"float")
  end if

  do jj = 0,dimsizes(onedlat)-1
    traj_lon(ii,jj) = onedlon(jj)
    traj_lat(ii,jj) = onedlat(jj)
    traj_wind(ii,jj) = onedwind(jj)
    traj_pres(ii,jj) = onedpres(jj)
  end do

  opt = True
  opt@PrintStat = True
  statb = stat_dispersion(onedpres, opt )

  delete([/traj_data,lat,lon,wind,pres,dpdt,ndims,nstorms,ntimes/])
  delete([/onedlat,onedlon,onedwind,onedpres/])

end do

if (do_obs) then

  ;=================== Get ibtracs data ================================
  ibstyr=1984
  ibenyr=2014
  print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
  ibdir="/glade/u/home/zarzycki/work/ibtracs/"
  ibfilename="Allstorms.ibtracs_wmo.v03r08.nc"
  ibfile = addfile(ibdir+ibfilename,"r")
  ;=============================================================================
  ; Here we'll find the storm # bounds so we don't have to load full dataset
  ;=============================================================================
  ibyear = toint(ibfile->season)
  print("num storms "+dimsizes(ibyear))
  print("Figuring out what storms we need to take")
  ibyear = where(ibyear .lt. ibstyr,-1,ibyear)
  ibyear = where(ibyear .gt. ibenyr,-1,ibyear)
  ; loop forwards to find first instance of valid year
  do i = 0,dimsizes(ibyear)-1
    if(ibyear(i).gt.0) then
      stix = i
      break
    end if
  end do
  ; loop backwards to find last instance of valid year
  do i = dimsizes(ibyear)-1,0,1
    if(ibyear(i).gt.0) then
      enix = i
      break
    end if
  end do
  print("Starting index: "+stix+"     end index: "+enix)
  delete(ibyear)
  ;=============================================================================

  xlat = ibfile->lat_wmo(stix:enix,:)*.01
  xlon = ibfile->lon_wmo(stix:enix,:)*.01
  xlon = where(xlon.lt.0,xlon+360.,xlon)
  xwind = ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts
  xpres = ibfile->pres_wmo(stix:enix,:)*.1
  xtype = toint(ibfile->nature_wmo(stix:enix,:))
  dpdt = xpres

  xpres=where(xpres.gt.cutpres,xpres@_FillValue,xpres)
  xpres=where(xtype.ne.0,xpres@_FillValue,xpres)

  ;print(xpres)

  ndims = dimsizes(xlon)
  nstorms = ndims(0)
  ntimes = ndims(1)

  do kk = 0,nstorms-1
    ;print(xlat(kk,:)+" "+xpres(kk,:))
    orilat=xlat(kk,0)
    orilon=min((/xlon(kk,0),359.0/))
    if (tcMask({orilat},{orilon}) .ne. basinfilt) then
      xlat(kk,:)=xlat@_FillValue
      xlon(kk,:)=xlon@_FillValue
      xwind(kk,:)=xwind@_FillValue
      xpres(kk,:)=xpres@_FillValue
    end if
    dpdt(kk,:)=dpdt@_FillValue
    dpdt(kk,1:ntimes-1)=xpres(kk,1:ntimes-1)-xpres(kk,0:ntimes-2)
    ;print(xpres(kk,1:ntimes-1)+" "+xpres(kk,0:ntimes-2))
    ;print(dpdt(kk,:))
  end do

  cwind = ndtooned(xwind)
  cpres = ndtooned(dpdt)
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)

  do jj = 0,dimsizes(clat)-1
    traj_lon(ii,jj) = clon(jj)
    traj_lat(ii,jj) = clat(jj)
    traj_wind(ii,jj) = cwind(jj)
    traj_pres(ii,jj) = cpres(jj)
  end do

  opt = True
  opt@PrintStat = True
  statb = stat_dispersion(cpres, opt )

  delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,dpdt/])

end if



binSettings=True
binSettings@bin_min=-25.0
binSettings@bin_max=25.0
nbins = 17
ap  = pdfx(traj_pres(0,:), nbins, binSettings)
bp  = pdfx(traj_pres(1,:), nbins, binSettings)
cp  = pdfx(traj_pres(2,:), nbins, binSettings)


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


plotName="pdf-mslp-6hrly"
wks  = gsn_open_wks (out_type,plotName)
plot = new(1,graphic)

res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/6.0,6.0,6.0/)
res@xyLineColors             = (/"blue","red","black"/)
res@xyMonoDashPattern        = False              ; all solid
res@xyDashPatterns = (/1,2,0/)
res@tiYAxisString            = "PDF (%)"

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of

res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height

res@xyExplicitLegendLabels = files

res@tmXBPrecision = 4 ; Precision on x-axis always 4 (XXXX hPa)

res@pmLegendParallelPosF   = .25                 ; move units right
res@pmLegendOrthogonalPosF = -0.4                ; move units down
res@tiXAxisString = "Sea level pressure (hPa)"
res@tiMainString  = "Minimum SLP PDF" ; title

res@trYMinF           = 0.   ; use for tuning to fix panel label issue
res@trYMaxF           = 50.  ; use for tuning to fix panel label issue
res@trXMinF           = -30.
res@trXMaxF           = 30.
plot(0) = gsn_csm_xy (wks, xx, yy, res)


res@tiYAxisString = "Frequency (%)"     ; y axis title

resP=True

gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot

delete(res)



end
