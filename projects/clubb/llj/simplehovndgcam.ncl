;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

  yyyy = "2010"
  mm   = "06"

  setfileoption("nc","Format","LargeFile")

  allfiles = systemfunc("ls *.h2."+yyyy+"-"+mm+"*.nc")
  files = allfiles
  a = addfiles(files,"r")

  zlin = fspan(0,5,51)
  nzlin = dimsizes(zlin)
  nf = dimsizes(files)

  vhov = new((/nf*48,nzlin/),float)
  uhov = new((/nf*48,nzlin/),float)
  zhov = new((/nf*48,nzlin/),float)
  t    = new((/nf*48/),double)

  do fi=0,nf-1
    v = a[fi]->V_97w_37n(:,::-1,0,0)
    z = (a[fi]->Z3_97w_37n(:,::-1,0,0)-310.)/1000.
    vhov(fi*48:(fi+1)*48-1,:) = linint1_n_Wrap(z,v,False,zlin,0,1)
    time = a[fi]->time
    if fi.eq.0 then
      tunits = cd_string(time(0),"days since %Y-%N-%D %H:%M:%S")
    end if
    t(fi*48:(fi+1)*48-1) = cd_convert(time,tunits)
    print("Read in file "+(fi+1)+" of " + nf)
  end do

  zlin@long_name = "Height AGL (km)"
  t@long_name = "Time (days)"

  vhov@long_name = yyyy+" "+mm+" SGP Meridional Wind (m/s), CAM ndgnotllj"
  vhov!0 = "t"
  vhov!1 = "z"
  vhov&t = t
  vhov&z = zlin
  tmp = vhov
  delete(vhov)
  vhov = tmp(z|:,t|:)

  ; we generate plots, but what kind do we prefer?
  type = "pdf"
  type@wkPaperHeightF = 11 ; only for ps
  type@wkPaperWidthF = 11 ; only for ps
  wksname = "./plots/vhov_SGP_ndgnotllj_"+yyyy+mm
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
  
  delete(vhov@units)
  plot = gsn_csm_contour(wks,vhov,res)
end
