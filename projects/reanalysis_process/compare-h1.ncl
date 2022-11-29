begin

products = (/"ERA5","MERRA2","CFSR","JRA","CR20"/)
nprod = dimsizes(products)
mydate = "19860102"
yyyy = "1986"
whichvar = "Z500"

do ii = 0,nprod-1
  filename="/glade/u/home/zarzycki/scratch/h1files/"+products(ii)+"/"+yyyy+"/"+products(ii)+".h1."+mydate+".nc"
  f = addfile(filename,"r")
  var = f->$whichvar$(2,:,:)
  
  if (ii .eq. 0)
    reflat=f->lat
    reflon=f->lon
    nlat = dimsizes(reflat)
    nlon = dimsizes(reflon)
    bigvar = new((/nprod,nlat,nlon/),"float")
    bigvar(ii,:,:) = var
  else
    modlat=f->lat
    modlon=f->lon
    bigvar(ii,:,:) = linint2 (modlon,modlat,var, True, reflon,reflat, 0)
    delete(modlat)
    delete(modlon)
  end if
  
  delete(f)
  delete(var)
end do

;************************************************
; create plots
;************************************************
wks = gsn_open_wks("x11","panel")              ; open a png file
plot = new(nprod*2,graphic)                          ; create a plot array

stringlabels = new(nprod*2,string)

res          = True
res@gsnDraw             = False           ; don't draw
res@gsnFrame            = False           ; don't advance frame
res@cnInfoLabelOn       = False           ; turn off cn info label
res@cnFillOn            = True            ; turn on color
res@cnLinesOn            = False
res@cnFillMode = "RasterFill"

res@mpLimitMode    = "LatLon"          ; use lat/lon coordinates to limit area
res@mpMinLatF      = 20.
res@mpMaxLatF      = 70.
res@mpMinLonF      = 210.
res@mpMaxLonF      = 310.
  
res@cnLevelSelectionMode =  "ManualLevels"
if (whichvar .eq. "Z500")
  res@cnMinLevelValF       = 4700.
  res@cnMaxLevelValF       = 6000.
  res@cnLevelSpacingF      =  100. 
else
  res@cnMinLevelValF       =  94000.
  res@cnMaxLevelValF       = 103000.
  res@cnLevelSpacingF      =   1000. 
end if

res@cnFillPalette        = "BlGrYeOrReVi200"              ; choose colormap

do ii = 0,nprod-1
  plot(2*ii) = gsn_csm_contour_map(wks,bigvar(ii,:,:),res) 
  stringlabels(2*ii) = products(ii)
end do

if (whichvar .eq. "Z500")
  res@cnMinLevelValF       = -100.
  res@cnMaxLevelValF       =  100.
  res@cnLevelSpacingF      =   10. 
else
  res@cnMinLevelValF       =  -3000.
  res@cnMaxLevelValF       =   3000.
  res@cnLevelSpacingF      =    300. 
end if

res@cnFillPalette        = "BlWhRe"              ; choose colormap
do ii = 0,nprod-1
  bias = bigvar(0,:,:)
  bias = bigvar(ii,:,:) - bigvar(0,:,:)
  plot(2*ii+1) = gsn_csm_contour_map(wks,bias,res) 
  stringlabels(2*ii+1) = "ERA5-"+products(ii)
end do
;************************************************
; create panel
;************************************************
resP                     = True                ; modify the panel plot
resP@gsnPanelMainString = mydate
resP@gsnPanelLabelBar    = False
resP@gsnPanelFigureStrings=stringlabels
resP@gsnPanelFigureStringsFontHeightF  = 0.008

gsn_panel(wks,plot,(/nprod,2/),resP)             ; now draw as one plot

end
