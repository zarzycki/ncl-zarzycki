load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "plot_outline_tcforecast.ncl"

begin


  wks  = gsn_open_wks("pdf","tcforecast_outline_only")       ; open a ps file

  gsn_define_colormap(wks,"wh-bl-gr-ye-re") ; choose a colormap

  res                        = True         ; mods desdired

  res@gsnDraw=False
  res@gsnFrame=False

  res@mpOceanFillColor       = 5            ; array index in color map
  res@mpLandFillColor        = 164          ; for land, ocean, and inland h20
  res@mpInlandWaterFillColor = 54
 
  res@mpMinLonF              = -180
  res@mpMaxLonF              = 180
  res@mpCenterLonF           = 0     ; This is necessary to get the correct map
 
  plot = gsn_csm_map_ce(wks,res)        ; draw global map
  plot= plot_outline_fcn(wks,plot,"black",5.0)

  draw(plot)
  frame(wks)

  end

