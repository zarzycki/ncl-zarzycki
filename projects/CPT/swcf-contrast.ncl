begin

dir = "/glade/derecho/scratch/stepheba/archive/"

cases = (/"flthist134_outofbox","flthist134.000f_ztest2","b1850.054.f_outofbox","b1850.054.f_ztest2"/)
colors = (/"blue","red","blue","red"/)
dashes = (/0,0,1,1/)
labels = (/"F_Lscale","F_taus","B_Lscale","B_taus"/)

var="TMQ"
out_type = "x11"

ncases = dimsizes(cases)

do ii = 0,ncases-1
  print(dir+"/"+cases(ii))

   fils := systemfunc ("ls "+dir+"/"+cases(ii)+"/atm/hist/*h0*.nc")
   print(fils)
   f    := addfiles (fils, "r")

   ListSetType (f, "cat")

   if (var .eq. "PRECT") then
     tmp1 := f[:]->PRECL
     tmp2 := f[:]->PRECC
     myvar := tmp1
     myvar = tmp1 + tmp2
     delete(tmp1)
     delete(tmp2)
   else
     myvar := f[:]->$var$
   end if
   printVarSummary (myvar)

   if (var .eq. "PRECT" .or. var .eq. "PRECC" .or. var .eq. "PRECL")
     myvar = myvar * 86400000.
   end if

   if (ii .eq. 0) then
     lat = f[0]->lat
     lon = f[0]->lon
     lev = f[0]->lev
     nlat = dimsizes(lat)
     nlon = dimsizes(lon)
     nlev = dimsizes(lev)
     mean_store = new((/4,nlat,nlon/),typeof(myvar))
     myvarunits = myvar@units
   else
     print("hi")
   end if

   mean_store(ii,:,:) = dim_avg_n_Wrap(myvar,0)

end do

do ii = 0,ncases-1

  leftlat  =  20.0
  leftlon  =  195.0

  rightlat =  30.0
  rightlon =  235.0

  npts     =   100

  dist     = gc_latlon(leftlat,leftlon,rightlat,rightlon,npts,2)
  points   = ispan(0,npts-1,1)*1.0

  print(dist)

  trans   = linint2_points(lon,lat,mean_store(ii,:,:),True,dist@gclon,dist@gclat,2)

  printVarSummary(trans)
  if (ii .eq. 0)
    merge_trans = new((/4,npts/),typeof(trans))
  end if

  merge_trans(ii,:) = trans

end do

;print(dist@gclon+" "+dist@gclat)
;
;newlat=dist@gclat
;newlon=dist@gclon
;
;do jj = 0,99
;  print(""+(newlat(jj+1)-newlat(jj)))
;end do



wks   = gsn_open_wks (out_type,"xy_transect_"+var)                 ; send graphics to PNG file


res                   = True                      ; plot mods desired

res@xyLineColors      =   colors        ; change line color
res@xyDashPatterns = dashes


res@pmLegendDisplayMode    = "Always"              ; turn on legend
res@pmLegendSide           = "Top"                 ; Change location of
res@pmLegendParallelPosF   = 0.8                   ; move units right (more pos)
res@pmLegendOrthogonalPosF = -0.3                  ; more neg = down
res@pmLegendWidthF         = 0.08                  ; Change width and
res@pmLegendHeightF        = 0.12                  ; height of legend.
res@lgLabelFontHeightF     = .02                   ; change font height
res@lgPerimOn              = False                 ; no box around
res@xyExplicitLegendLabels = labels

res@tmXBMode        = "Explicit"
res@tmXBValues      = (/0,100/)
res@tmXBLabels      = (/leftlat+"/"+leftlon,rightlat+"/"+rightlon/)

res@tiYAxisString       = var + " ("+myvarunits+")"

plot  = gsn_csm_xy (wks,points,merge_trans,res) ; create plot

delete(plot)
delete(res)
delete(wks)

  wks = gsn_open_wks(out_type,"panel_"+var)              ; send graphics to PNG file

  cmap = read_colormap_file("cmocean_dense")

  plot = new(4,graphic)                          ; create a plot array
  polys = new(100,graphic)
  polyit = 0

  res                     = True
  res@gsnDraw             = False           ; don't draw
  res@gsnFrame            = False           ; don't advance frame
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnFillOn            = True            ; turn on color
  res@cnFillPalette       = cmap(:,:)
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@cnInfoLabelOn     = False
  res@cnFillMode = "RasterFill"

  res@gsnLeftString=""
  res@gsnCenterString=""
  res@gsnRightString=""

  res@mpCenterLonF = 180.

  if (var .eq. "SWCF") then
    res@cnLevelSelectionMode =  "ManualLevels"
    res@cnMinLevelValF       = -80.
    res@cnMaxLevelValF       =   0.
    res@cnLevelSpacingF      =   5.
  end if
  if (var .eq. "TMQ") then
    res@cnLevelSelectionMode =  "ManualLevels"
    res@cnMinLevelValF       = 0.
    res@cnMaxLevelValF       = 65.
    res@cnLevelSpacingF      = 5.
  end if
  if (var .eq. "PRECC") then
    res@cnLevelSelectionMode =  "ManualLevels"
    res@cnMinLevelValF       = 0.
    res@cnMaxLevelValF       = 10.
    res@cnLevelSpacingF      = 0.5
  end if

  res@cnFillOn    = True                        ; turn on color fill
  res@cnLinesOn   = False                       ; turn off the contour lines
  res@cnLineLabelsOn = False                    ; turn the line labels off

  respm = True
  respm@gsMarkerColor = "yellow"
  respm@gsMarkerIndex = 16

  respl = True
  respl@gsLineColor = "yellow"
  respl@gsLineDashPattern = 5
  respl@gsLineThicknessF = 5.0

  do ii = 0,ncases-1
    res@gsnCenterString = labels(ii)
    plot(ii) = gsn_csm_contour_map(wks,mean_store(ii,:,:),res)
    ; draw transect location
    polys(polyit) = gsn_add_polymarker(wks,plot(ii),leftlon,leftlat,respm)
    polyit = polyit + 1
    polys(polyit) = gsn_add_polymarker(wks,plot(ii),rightlon,rightlat,respm)
    polyit = polyit + 1
    polys(polyit) = gsn_add_polyline(wks,plot(ii),(/rightlon,leftlon/),(/rightlat,leftlat/),respl)
    polyit = polyit + 1
  end do

  resP                     = True                ; modify the panel plot
  resP@gsnPanelMainString = var
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot

end
