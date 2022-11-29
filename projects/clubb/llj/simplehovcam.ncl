;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

  yyyy = "2010"
  mm   = "07"

  setfileoption("nc","Format","LargeFile")

  datadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-x003/run/2010061600/"
  allfiles = systemfunc("ls "+datadir+"*.cam.h4.????-0[7]*.nc")
  files = allfiles
  a = addfiles(files,"r")

  zlin = fspan(0.5,5,51)*1000
  nzlin = dimsizes(zlin)
  nf = dimsizes(files)

  vhov = new((/nf*48,nzlin/),float)
  uhov = new((/nf*48,nzlin/),float)
  zhov = new((/nf*48,nzlin/),float)
  t    = new((/nf*48/),double)

  UVAR="U_97.49w_36.61n"
  VVAR="V_97.49w_36.61n"
  ZVAR="Z3_97.49w_36.61n"
  PHISVAR="PHIS_97.49w_36.61n"
  do fi=0,nf-1
    v = a[fi]->$VVAR$(:,::-1,0)
    z = a[fi]->$ZVAR$(:,::-1,0)
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

  vhov@long_name = yyyy+" "+mm+" SGP Meridional Wind (m/s), Free-Running CAM"
  vhov!0 = "t"
  vhov!1 = "z"
  vhov&t = t
  vhov&z = zlin
  tmp = vhov
  delete(vhov)
  vhov = tmp(z|:,t|:)
  
system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->vhov  = vhov                          ; 4D     



  ; we generate plots, but what kind do we prefer?
  type = "x11"
  type@wkPaperHeightF = 11 ; only for ps
  type@wkPaperWidthF = 11 ; only for ps
  wksname = "./plots/vhov_SGP_freecam_"+yyyy+mm
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
