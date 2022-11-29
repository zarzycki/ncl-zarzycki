;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

  setfileoption("nc","Format","LargeFile")

  a = addfile("2010.nc","r")
  b = addfile("2012.nc","r")

  vrwp = dim_avg_n_Wrap(a->v,1)
  vcam = dim_avg_n_Wrap(b->v,1)
  z    = b->z


  v = (/vrwp,vcam/)

  wks   = gsn_open_wks("x11","lljcomp")                 ; send graphics to PNG file

  res = True
  res@vpXF = 0.21
  res@vpWidthF = 0.3
  res@vpHeightF = 0.6
  res@xyDashPattern  = 0                         ; Make curves all solid
  res@xyMarkLineMode = "MarkLines"               ; Markers *and* lines
  res@xyMarkers      = (/16,16,16/)               ; 3 different markers
  res@xyMarkerColors = (/"black","red","green"/) ; 3 different colors
  res@xyLineColors = (/"black","red"/)

  res@pmLegendDisplayMode    = "Always"              ; turn on legend
  res@pmLegendSide           = "Top"                 ; Change location of 
  res@pmLegendParallelPosF   = .75                   ; move units right
  res@pmLegendOrthogonalPosF = -0.20                 ; more neg = down
  res@pmLegendWidthF         = 0.10                  ; Change width and
  res@pmLegendHeightF        = 0.10                  ; height of legend.
  res@lgLabelFontHeightF     = .02                   ; change font height
  res@lgPerimOn              = False                 ; no box around
  res@xyExplicitLegendLabels = (/"RWP","CAM6","40N","50N"/)
  res@trYMaxF = 2500
  res@trYMinF = 0
  res@trXMaxF = 8.5
  res@trXMinF = 1.5

  z@long_name = "Height AGL (m)"

  plot = gsn_csm_xy(wks,v,z,res)
 
  vlevs = (/a->v(1,:),b->v(1,:),a->v(3,:),b->v(3,:),a->v(5,:),b->v(5,:)/)
  do shifti=0,4
    tmp = new(dimsizes(vlevs),typeof(vlevs))
    tmp(:,0:22) = vlevs(:,1:23)
    tmp(:,23) = vlevs(:,0)
    vlevs = tmp
  end do
  t = a->Time
  t@long_name = "Time of Day, Local (hr)"

  vlevs@long_name = "Meridional Wind (m/s)"

  res@vpWidthF = 0.6
  res@vpHeightF = 0.6
  res@trYMaxF = 11
  res@trYMinF = 3
  res@trXMaxF = 24
  res@trXMinF = 0
  delete(res@xyExplicitLegendLabels)
  delete(res@xyMarkers)
  delete(res@xyMarkerColors)
  delete(res@xyLineColors)
  res@xyLineColors = (/"black","black","red","red","blue","blue"/)
  res@xyMarkers = (/"16","14","16","14","16","14"/)
  res@xyMarkerColors = (/"black","black","red","red","blue","blue"/)
  res@xyExplicitLegendLabels = (/"RWP 200 m","CAM 200m","RWP 400 m","CAM 400m","RWP 600 m","CAM 600m"/)
  res@pmLegendParallelPosF   = .60                   ; move units right
  res@pmLegendOrthogonalPosF = -0.30                 ; more neg = down
  res@pmLegendHeightF        = 0.15                  ; height of legend.
  plot = gsn_csm_xy(wks,t,vlevs,res)

  
  res2 = True
  res2@vpXF = 0.21
  res2@vpWidthF = 0.6
  res2@vpHeightF = 0.6
  res2@cnFillOn = True
  res2@cnLinesOn = True
  res2@lbLabelBarOn = True
  res2@cnLevelSelectionMode = "ManualLevels"
  res2@cnMinLevelValF =  1 
  res2@cnMaxLevelValF = 12 
  res2@cnLevelSpacingF = 0.5

  vhovrwp = a->v
  vhovcam = b->v

  gsn_define_colormap(wks,"wh-bl-gr-ye-re")

  delete(tmp)
  do shifti=0,4
    tmp = new(dimsizes(vhovrwp),typeof(vhovrwp))
    tmp(:,0:22) = vhovrwp(:,1:23)
    tmp(:,23) = vhovrwp(:,0)
    vhovrwp = tmp
    tmp(:,0:22) = vhovcam(:,1:23)
    tmp(:,23) = vhovcam(:,0)
    vhovcam = tmp
  end do

  vhovrwp&Time = t
  vhovcam&Time = t

  plot = gsn_csm_contour(wks,vhovrwp,res2)
  plot = gsn_csm_contour(wks,vhovcam,res2)

  minsrwp = dim_min_n(vhovrwp,1)
  minscam = dim_min_n(vhovcam,1)
  maxsrwp = dim_max_n(vhovrwp,1)
  maxscam = dim_max_n(vhovcam,1)
  spans = (/maxsrwp-minsrwp,maxscam-minscam/)
  spans@long_name = "Diurnal Span (m/s)"

  res@vpWidthF = 0.3
  res@vpHeightF = 0.6
  res@trYMaxF = 2500
  res@trYMinF = 0
  res@trXMaxF = 10
  res@trXMinF = 0
  delete(res@xyExplicitLegendLabels)
  delete(res@xyMarkers)
  delete(res@xyMarkerColors)
  delete(res@xyLineColors)
  res@xyLineColors = (/"black","red","red","red","blue","blue"/)
  res@xyMarkers = (/"16","16","16","14","16","14"/)
  res@xyMarkerColors = (/"black","red","red","red","blue","blue"/)
  res@xyExplicitLegendLabels = (/"RWP","CAM","RWP 400 m","CAM 400m","RWP 600 m","CAM 600m"/)
  res@pmLegendParallelPosF   = .80                   ; move units right
  res@pmLegendOrthogonalPosF = -0.30                 ; more neg = down
  res@pmLegendHeightF        = 0.10                  ; height of legend.
  plot = gsn_csm_xy(wks,spans,z,res)


end
