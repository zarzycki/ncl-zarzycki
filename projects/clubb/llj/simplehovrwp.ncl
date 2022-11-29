;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

  setfileoption("nc","Format","LargeFile")

  power = 1

  yyyy = "2010"
  mm   = "07"

  datadir = "/glade/u/home/zarzycki/scratch/ARM-RWP"
  allfiles = systemfunc("ls "+datadir+"/sgp915rwpwindconC1.a1."+yyyy+mm+"*.cdf")
  files = allfiles
  a = addfiles(files,"r")

  zmax = 5
  zlin = fspan(0,zmax,101)
  nzlin = dimsizes(zlin)
  nf = dimsizes(files)

  dt = 10./60 ; in hr
  ndays = nf
  tperday = tointeger(24/dt)
  nt = tperday*ndays+1
  tlin = fspan(0.,ndays,nt)
  vhov = new((/nt,nzlin/),float)
  uhov = new((/nt,nzlin/),float)

  do fi=0,nf-1
    if dimsizes(a[fi]->power).eq.2 then
      powind = power
    else
      powind = 0
    end if
    v = a[fi]->v_wind(:,:,powind)
    v = where(abs(v).ge.200,v@_FillValue,v)
    z = a[fi]->height_p(:,powind)
    t = a[fi]->time/3600./24.
    ttmp = ispan(0,tperday-1,1)*10./60/24
    
    maxzind = maxind(z)
    vzinterp = linint1_n(z(0:maxzind),v(:,0:maxzind),False,zlin,0,1)
    if dimsizes(t).ge.2 then
      vtzinterp = linint1_n(t,vzinterp,False,ttmp,0,0)
    end if
    vhov(fi*tperday:(fi+1)*tperday-1,:) = vtzinterp
    delete(v)
    delete(vzinterp)
    delete(z)
    delete(t)
    print("Done with file "+files(fi))
  end do

  zlin@long_name = "Height AGL (km)"
  tlin@long_name = "Time (days)"

  if power.eq.0 then
    addtxt = "Low Power"
  else
    addtxt = "High Power"
  end if
  vhov@long_name = yyyy+" "+mm+" SGP Meridional Wind (m/s), RWP "+addtxt
  vhov!0 = "t"
  vhov!1 = "z"
  vhov&t = tlin
  vhov&z = zlin
  tmp = vhov
  delete(vhov)
  vhov = tmp(z|:,t|:)

  ; we generate plots, but what kind do we prefer?
  type = "x11"
  type@wkPaperHeightF = 11 ; only for ps
  type@wkPaperWidthF = 11 ; only for ps
  wksname = "./plots/vhov_SGP_rwp_"+yyyy+mm+"_pow"+power
  wks = gsn_open_wks(type,wksname)

  gsn_define_colormap(wks,"testcmap")

  res = True
  ;res@gsnFrame = False
  ;res@gsnDraw  = False
  res@vpWidthF  = 0.60
  res@vpHeightF = 0.30
  res@vpXF      = 0.21
  res@cnFillOn = True
  res@cnLinesOn = False
  res@lbLabelBarOn = True
  res@lbOrientation = "vertical"
  res@lbLabelPosition = "left"
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF = -15
  res@cnMaxLevelValF =  15
  res@cnLevelSpacingF = 0.5
  ;res@trYMinF = 0
  ;res@trYMaxF = 3
  res@gsnYAxisIrregular2Linear = True
  res@gsnXAxisIrregular2Linear = True
  res@cnFillMode = "RasterFill"
  
  plot = gsn_csm_contour(wks,vhov,res)
end
