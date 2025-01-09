load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;var = "PRECZF" ; PRECZF
wgt_file="/glade/u/home/zarzycki/scratch/map_ne30pg3_to_1x1glob_patch.nc"
cases = (/"FHIST-ne30-free-x021","FHIST-ne30-free-x222"/)

do ii = 0,1

  filename="/glade/u/home/zarzycki/scratch/archive/"+cases(ii)+"/atm/hist/avg.nc"
  f = addfile(filename,"r")
  
  if (var .eq. "PRECZF") then
    v = f->PRECZ
    v1 = f->PRECL
    v2 = f->PRECC
    v = v / (v2 + v1)
    delete(v1)
    v@long_name = "Fraction of precip. from ZM"
    v@units="-"
  else
    v = f->$var$
  end if
  
  Opt=True
  v := ESMF_regrid_with_weights(v,wgt_file,Opt)
    
  if (ii .eq. 0) then
    nlat = dimsizes(v&lat)
    nlon = dimsizes(v&lon)
    arr = new((/2,nlat,nlon/),typeof(v))
  end if
  
  arr(ii,:,:) = v(0,:,:)
  
  ; final cleanup
  delete(v)

end do

  if (var .eq. "PRECZF") then
    minvar = 0.0
    maxvar = 1.0
    minmaxscaling=0.0
  else
    minvar = min(arr)
    maxvar = max(arr)
    minmaxscaling=0.05
  end if
  vardiff = maxvar-minvar

  diff = arr(0,:,:)
  diff = arr(1,:,:) - arr(0,:,:)

  if (var .eq. "PRECZF") then
    maxdiff = 0.5
  else
    maxdiff = max(abs(diff))
  end if  

  wks   = gsn_open_wks ("png", "panels_"+var)        ; send graphics to PNG file

  plot = new(3,graphic)

  res                 = True                    ; plot mods desired
  res@gsnDraw         = False                   ; don't draw yet
  res@gsnFrame        = False                   ; don't advance frame yet
  res@gsnAddCyclic = False
  res@cnLineLabelsOn  = False

  res@cnFillMode="RasterFill"
  res@cnFillOn              = True
  res@cnLinesOn   = False
  ;res@cnRasterSmoothingOn = True

  cmap = read_colormap_file("MPL_gnuplot2")
  res@cnFillPalette=cmap

  res@cnLevelSelectionMode = "ManualLevels"   ; manually set the contour levels with the following 3 resources
  
  nlevels=20
  res@cnMinLevelValF  = minvar+minmaxscaling*vardiff
  res@cnMaxLevelValF  = maxvar-minmaxscaling*vardiff
  res@cnLevelSpacingF = vardiff/nlevels

  res@pmTickMarkDisplayMode = "Always"
  res@mpOutlineOn           = True

  ;res@gsnLeftString=""

  plot(0) = gsn_csm_contour_map(wks,arr(0,:,:), res)
  plot(1) = gsn_csm_contour_map(wks,arr(1,:,:), res)
  
  cmap := read_colormap_file("NCV_blu_red")
  res@cnFillPalette := cmap
  nlevels=20
  res@cnMinLevelValF  = -1*maxdiff+minmaxscaling*vardiff
  res@cnMaxLevelValF  = maxdiff-minmaxscaling*vardiff
  res@cnLevelSpacingF = 2*maxdiff / nlevels
  
  plot(2) = gsn_csm_contour_map(wks,diff, res)

  panres                     = True
  panres@gsnPanelFigureStringsFontHeightF = 0.009
  panres@gsnPanelFigureStrings=(/cases(0),cases(1),cases(1)+"-"+cases(0)/)
  panres@amJust           = "TopLeft"
  ;panres@gsnMaximize         = True             ; maximize the plots
  ;panres@gsnPanelLabelBar    = True             ; turn on the panel label bar
  panres@gsnPanelMainString = var
  gsn_panel(wks,plot,(/3,1/),panres)

end