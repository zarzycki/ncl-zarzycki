; This routine takes a uniform grid, var-res grid (both interpolated to same
; lat/lon) and generates a panel plot of a specific variable from both grids
; as well as the absolute difference between the two grids. There is an option
; to download MERRA data (does not need to be on same grid) and plot that as a
; fourth panel.

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"

begin

add_obs=True
add_diff = True
whichpanel = "def"
wherepanel = "TopRight" ; TopLeft or TopRight
var = "TMQ"
region = "refined" ; options are "refined", "refinedplus", "Caribbean", "SierraMadre", "global", "refinedplus","ZoomCaribbean"
out_type = "x11"
reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_climo_h0.all.nc","r")
unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_climo_h0.all.nc_regrid.nc","r")
oneLabelBar = True

print("Get GW")
gw = reffile->gw

print("Reading data")
if (var .eq. "PRECT") then
  refvar2 = reffile->$var$(0,:,:)
  univar2 = unifile->$var$(0,:,:)
  refvar = refvar2
  univar = univar2
  univar = univar2*3.6e6
  refvar = refvar2*3.6e6
  univar@long_name = "Total precipitation rate"
  refvar@long_name = univar@long_name
  refvar@units = "mm hr~S~-1~N~"
  univar@units = "mm hr~S~-1~N~"
else if (var .eq. "VBOT") then
  delete(reffile)
  delete(unifile)
  reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/atl30x4_monthlyavg_climo_01_3D.nc","r")
  unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/ne30_monthlyavg_climo_01_3D.nc_regrid.nc","r")
  refvar = reffile->V(0,29,:,:)
  univar = unifile->V(0,29,:,:)
  a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
  lsdata = a->LSMASK
  lsm  = landsea_mask(lsdata,refvar&lat,refvar&lon)
  refvar = mask(refvar,lsm.gt.0,False)
  univar = mask(univar,lsm.gt.0,False)
  oneLabelBar = False
else if (var .eq. "U200") then
  delete(reffile)
  delete(unifile)
  reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_all_climo_3D.nc","r")
  unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_all_climo_3D.nc_regrid.nc","r")
  refvar_native = reffile->U(0,:,:,:)
  univar_native = unifile->U(0,:,:,:)
  
  linlog = 2
  lev = reffile->lev
  refvar_int = int2p_n_Wrap(lev,refvar_native,(/200./),linlog,0)
  univar_int = int2p_n_Wrap(lev,univar_native,(/200./),linlog,0)
  
  refvar = refvar_int(0,:,:)
  univar = univar_int(0,:,:)
  
  delete([/refvar_int,univar_int,refvar_native,univar_native/])
  
else if (var .eq. "T500") then
  delete(reffile)
  delete(unifile)
  reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_all_climo_3D.nc","r")
  unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_all_climo_3D.nc_regrid.nc","r")
  refvar = reffile->T(0,{500},:,:)
  univar = unifile->T(0,{500},:,:)
else if (var .eq. "PHIS") then
  delete(reffile)
  delete(unifile)
  unifile = addfile("/glade/u/home/zarzycki/work/toposmooth/SEtopo/USGS-gtopo30_0.9x1.25_smooth2000-100_ne30np4_c051027.nc","r")
  reffile = addfile("/glade/u/home/zarzycki/work/toposmooth/SEtopo/topo_atlantic_30_x4.zarzycki_new_smoothing_consistentSGH.nc","r")
  uni_wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_ne30np4_TO_AMIP_ref_latlon_patc.130523.nc"
  ;uni_wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_ne30np4_TO_1x1_patc.131122.nc"
  ref_wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_atl30x4_TO_AMIP_ref_latlon_patc.131202.nc"
  refvar_se = reffile->$var$
  univar_se = unifile->$var$
  print("Regridding the data")
  Opt         = True
  Opt@CopyVarCoords = True
  refvar  = ESMF_regrid_with_weights(refvar_se,ref_wgt_file,Opt)
  univar  = ESMF_regrid_with_weights(univar_se,uni_wgt_file,Opt)
  ;lat = refvar&lat
  ;lon = refvar&lon
  refvar = where(refvar.lt.0,0,refvar)
  univar = where(univar.lt.0,0,univar)
  refvar@long_name = "Surface Geopotential"
  univar@long_name = "Surface Geopotential"
  refvar@units = "m~S~2~N~ s~S~-2~N~"
  univar@units = "m~S~2~N~ s~S~-2~N~"
else
  refvar = reffile->$var$(0,:,:)
  univar = unifile->$var$(0,:,:)
end if
end if
end if
end if
end if

print("Calculating differences")
diffvar = refvar
diffvar = refvar - univar
varmax = max(refvar)
varmin = min(refvar)

if (add_obs) then
  if (var .eq. "TMQ") then
    MERRAfile = addfile("/glade/u/home/zarzycki/scratch/MERRA/MERRA100.prod.assim.instM_2d_int_Nx.AVG.nc","r")
    MERRAvar = MERRAfile->tqv(0,:,:)
    MERRAlat = MERRAfile->latitude
    MERRAlon = MERRAfile->longitude
    MERRAvar@units = "kg/m2"
    obsString = "MERRA"
  else if (var .eq. "CLDTOT") then
    MERRAfile = addfile("/glade/u/home/zarzycki/scratch/MERRA/fluxes/avg.nc","r")
    MERRAvar = MERRAfile->cldtot(0,:,:)
    MERRAlat = MERRAfile->lat
    MERRAlon = MERRAfile->lon
  else if (var .eq. "FLUT") then
    MERRAfile = addfile("/glade/u/home/zarzycki/scratch/MERRA/fluxes/avg.nc","r")
    MERRAvar = MERRAfile->lwtup(0,:,:)
    MERRAlat = MERRAfile->lat
    MERRAlon = MERRAfile->lon
    MERRAvar@units = "W/m2"
  else if (var .eq. "LHFLX") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/MERRA/sfc_flx/climo_avg.nc","r")
    MERRAvar = MERRAfile->eflux(0,:,:)
    MERRAlat = MERRAfile->lat
    MERRAlon = MERRAfile->lon
    MERRAvar@units = "W/m2"
  else if (var .eq. "SHFLX") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/MERRA/sfc_flx/climo_avg.nc","r")
    MERRAvar = MERRAfile->hflux(0,:,:)  
    MERRAlat = MERRAfile->lat
    MERRAlon = MERRAfile->lon
    MERRAvar@units = "W/m2"
  else if (var .eq. "PRECT") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/ncep_climo.nc","r")
    MERRAvar2 = dim_avg_n_Wrap(MERRAfile->PRECT(:,:,:),0)
    MERRAvar = MERRAvar2
    MERRAvar = MERRAvar2*3.6e6
    delete(MERRAvar2)
    MERRAlat = MERRAfile->lat
    MERRAlon = MERRAfile->lon
    MERRAvar@units = "mm hr~S~-1~N~"
    obsString = "TRMM"
  else if (var .eq. "VBOT") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/uvclm95to05.nc","r")
    MERRAvar = MERRAfile->v(0,0,:,:)  
    MERRAlat = MERRAfile->lat
    MERRAlon = MERRAfile->lon
    MERRAvar@units = "m/s"
    obsString = "SEAWIND"
  else if (var .eq. "U200") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/uwnd.mon.ltm.nc","r")
    MERRAvar_full = MERRAfile->uwnd(:,{200},::-1,:)
    MERRAlat = MERRAfile->lat(::-1)
    MERRAlon = MERRAfile->lon
    MERRAvar = dim_avg_n_Wrap(MERRAvar_full,0)
    MERRAvar@units = "m/s"
    obsString = "NCEP"
  else if (var .eq. "T500") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/air.mon.ltm.nc","r")
    MERRAvar_full = MERRAfile->air(:,{500},::-1,:)
    MERRAlat = MERRAfile->lat(::-1)
    MERRAlon = MERRAfile->lon
    MERRAvar = dim_avg_n_Wrap(MERRAvar_full,0)
    MERRAvar@units = "K"
    obsString = "NCEP"
  else if (var .eq. "PHIS") then
    MERRAfile = addfile("/glade/u/home/zarzycki/scratch/hires-topo/2deg_cesm_topo_latlon.nc","r")
    horizStride = 4
    MERRAvar = MERRAfile->PHIS(::horizStride,::horizStride)
    MERRAlat = MERRAfile->lat(::horizStride)
    MERRAlon = MERRAfile->lon(::horizStride)
    MERRAvar = where(MERRAvar.lt.0,0,MERRAvar)
    MERRAvar&lat@units="degrees_north"
    MERRAvar&lon@units="degrees_east"
    MERRAvar@units = "m~S~2~N~ s~S~-2~N~"
    obsString = "NGDC"
  else
    print("That variable is not MERRA-supported")
    print("Please fix or turn off MERRA plot")
    exit
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
end if

print("Calculating RMSE")
model_rmse = wgt_arearmse(refvar,univar,gw,1.0,0)
print("RMSE between models is :"+model_rmse)
if (add_obs) then
  obsVar_CAMgrid = area_conserve_remap_Wrap(MERRAlon,MERRAlat,MERRAvar,refvar&lon,refvar&lat,False)
  ref_to_obs_rmse = wgt_arearmse(refvar,obsVar_CAMgrid,gw,1.0,0)
  uni_to_obs_rmse = wgt_arearmse(univar,obsVar_CAMgrid,gw,1.0,0)
  print("RMSE between refined and obs is :"+ref_to_obs_rmse)
  print("RMSE between uniform and obs is :"+uni_to_obs_rmse)
end if

if (add_obs .and. add_diff) then
  outputName = "diffplots_"+var+"_quad_"+region
  wks  = gsn_open_wks(out_type,outputName)
else
  outputName = "diffplots_"+var+"_"+whichpanel+"_"+region
  wks  = gsn_open_wks(out_type,outputName)
end if
if (var .eq. "PRECT") then
;gsn_define_colormap(wks,"WhBlGrYeRe")
  ;gsn_merge_colormaps(wks,"WhViBlGrYeOrRe","temp_19lev")
  gsn_merge_colormaps(wks,"precip2_15lev","temp_19lev")
;gsn_draw_colormap(wks)
end if
if (var .eq. "PHIS")
  gsn_define_colormap(wks,"MPL_terrain")  
end if

if (add_obs .and. add_diff) then
  plot = new(4,graphic)
else
  plot = new(3,graphic)
end if


res                             = True
res@mpFillOn                    = True        ; turn off gray fill
res@gsnFrame = False
res@gsnDraw = False
res@mpGreatCircleLinesOn=True

if region .eq. "refined" then
  res@mpMinLatF   = -20.                 
  res@mpMaxLatF   = 75.
  res@mpMinLonF   = -120.
  res@mpMaxLonF   = 20.
else if region .eq. "refinedplus" then
  res@mpMinLatF   = -25.
  res@mpMaxLatF   = 80.
  res@mpMinLonF   = -130.
  res@mpMaxLonF   = 30.
else if region .eq. "Caribbean" then
  res@mpMinLatF   = 0.
  res@mpMaxLatF   = 30.
  res@mpMinLonF   = -100.
  res@mpMaxLonF   = -65.
else if region .eq. "ZoomCaribbean" then
  res@mpMinLatF   = 2.
  res@mpMaxLatF   = 23.
  res@mpMinLonF   = -90.
  res@mpMaxLonF   = -65.
else if region .eq. "SierraMadre" then
  res@mpMinLatF   = 7.
  res@mpMaxLatF   = 23.
  res@mpMinLonF   = -102.
  res@mpMaxLonF   = -88.
else
  res@mpMinLatF   = -90.
  res@mpMaxLatF   = 90.
  res@mpMinLonF   = -180.
  res@mpMaxLonF   = 180.
end if
end if
end if
end if
end if


res@gsnSpreadColors = True

if (var .eq. "PHIS")
  if (region .eq. "Caribbean" .or. region .eq. "SierraMadre") then
  else
    res@cnFillMode = "RasterFill"
  end if
end if

res@cnLevelSelectionMode = "ManualLevels"

contOutlineColor = "Black"
contOutlineWidth = 3.0
refinedOutlineColor = "Black"
refinedOutlineWidth = 5.0

res@mpOutlineOn            = True
res@mpGeophysicalLineColor = contOutlineColor
res@mpGeophysicalLineThicknessF = contOutlineWidth
res@mpPerimOn              = False
res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels
res@cnFillOn=True

res_diff = res
if (var .eq. "TMQ") then
  res@cnLevelSpacingF      =  4.
  res@cnMinLevelValF       =  0.0
  res@cnMaxLevelValF       =  56.0
  res_diff@cnLevelSpacingF      =  2.
  res_diff@cnMinLevelValF       =  -12.
  res_diff@cnMaxLevelValF       =  12.
end if
if (var .eq. "PRECT") then
  ;res@cnFillMode = "RasterFill"
;  res@cnLevelSpacingF      =  .1
;  res@cnMinLevelValF       =  0.1
;  res@cnMaxLevelValF       =  1.2
  
  ; This is what I used to use
  ;res@cnLevelSpacingF      =  0.1
  ;res@cnMinLevelValF       =  0.0
  ;res@cnMaxLevelValF       =  1.3
  ;;;;;;;;;
  res@gsnSpreadColorStart = 2
  res@gsnSpreadColorEnd = 18
  
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels    = (/0.01,.1,.2,.3,.4,.5,.6,.7,.8,.9,1.0,1.2/)
  
  res_diff@cnLevelSpacingF      =  .08
  res_diff@cnMinLevelValF       =  -.4
  res_diff@cnMaxLevelValF       =  .4
  res_diff@gsnSpreadColorStart = 102
  res_diff@gsnSpreadColorEnd = 121
  
  contOutlineColor = "White"
  refinedOutlineColor = "Black"
end if
if (var .eq. "CLDTOT") then
  res@cnLevelSpacingF      =  0.1
  res@cnMinLevelValF       =  0.1
  res@cnMaxLevelValF       =  1.0
  res_diff@cnLevelSpacingF      =  .04
  res_diff@cnMinLevelValF       =  -0.20
  res_diff@cnMaxLevelValF       =  0.20
end if
if (var .eq. "OMEGA500") then
  res@cnLevelSpacingF      =  .02
  res@cnMinLevelValF       =  -0.2
  res@cnMaxLevelValF       =  0.1
  res_diff@cnLevelSpacingF      =  0.005
  res_diff@cnMinLevelValF       =  -0.05
  res_diff@cnMaxLevelValF       =  0.05
end if
if (var .eq. "FLUT") then
  res@cnLevelSpacingF      =  20
  res@cnMinLevelValF       =  120
  res@cnMaxLevelValF       =  300
  res_diff@cnLevelSpacingF      =  10
  res_diff@cnMinLevelValF       =  -40
  res_diff@cnMaxLevelValF       =  40
end if
if (var .eq. "PSL") then
  res@cnLevelSpacingF      =  400
  res@cnMinLevelValF       =  100000
  res@cnMaxLevelValF       =  102400
  res_diff@cnLevelSpacingF      =  40
  res_diff@cnMinLevelValF       =  -400
  res_diff@cnMaxLevelValF       =  400
end if
if (var .eq. "LHFLX") then
  res@cnLevelSpacingF      =  15
  res@cnMinLevelValF       =  -50
  res@cnMaxLevelValF       =  250
  res_diff@cnLevelSpacingF      =  5
  res_diff@cnMinLevelValF       =  -60
  res_diff@cnMaxLevelValF       =  60
end if
if (var .eq. "SHFLX") then
  res@cnLevelSpacingF      =  10
  res@cnMinLevelValF       =  -20
  res@cnMaxLevelValF       =  90
  res_diff@cnLevelSpacingF      =  8
  res_diff@cnMinLevelValF       =  -40
  res_diff@cnMaxLevelValF       =  40
end if
if (var .eq. "VBOT") then
  res@cnLevelSpacingF      =  2.
  res@cnMinLevelValF       =  -14.
  res@cnMaxLevelValF       =  14.
  res_diff@cnLevelSpacingF      =  1.
  res_diff@cnMinLevelValF       =  -10.
  res_diff@cnMaxLevelValF       =  10.
end if
if (var .eq. "U200") then
  res@cnLevelSpacingF      =  5.
  res@cnMinLevelValF       =  -10.
  res@cnMaxLevelValF       =  50.
  res_diff@cnLevelSpacingF      =  1.
  res_diff@cnMinLevelValF       =  -8.
  res_diff@cnMaxLevelValF       =  8.
end if
if (var .eq. "PHIS") then
  contOutlineColor = "White"
  refinedOutlineColor = "Red"
  if (region .eq. "refined" .or. region .eq. "refinedplus") then
    res@cnLevelSpacingF      =  500.
    res@cnMinLevelValF       =  0.
    res@cnMaxLevelValF       =  24000.
  else if (region .eq. "global") then
    res@cnLevelSpacingF      =  2000.
    res@cnMinLevelValF       =  0.
    res@cnMaxLevelValF       =  32000.
  else
    res@cnLevelSpacingF      =  1500.
    res@cnMinLevelValF       =  0.
    res@cnMaxLevelValF       =  24000.
  end if
  end if
  res_diff@cnLevelSpacingF      =  1.
  res_diff@cnMinLevelValF       =  -10.
  res_diff@cnMaxLevelValF       =  10.
end if

if (var .eq. "VBOT" .and. region .eq. "SierraMadre") then
  contOutlineWidth = 2.0
end if


;res@gsnLeftString=""

if (.not. add_obs .and. .not. add_diff) then
  res@gsnLeftString=""
  res@gsnRightString=""
else if (add_obs .and. add_diff) then
  res@gsnLeftString=""
  res_diff@gsnLeftString=""
  oneLabelBar = False
else if (add_obs .and. .not. add_diff) then
  res@gsnLeftString=""
  res@gsnRightString=""
else
end if
end if
end if

if (var .eq. "VBOT") then
  res@gsnRightString="m s~S~-1~N~"
  res@lbLabelStride = 2
end if

if (oneLabelBar) then
  res@lbLabelBarOn = False
end if


plot(0) = gsn_csm_contour_map(wks,refvar,res)
  print("V-R average is :"+avg(refvar))
plot(1) = gsn_csm_contour_map(wks,univar,res)
  print("Uni average is :"+avg(univar))
lastPlotIndex = 2
if (add_diff) then
  plot(2) = gsn_csm_contour_map(wks,diffvar,res_diff)
  lastPlotIndex = lastPlotIndex + 1
end if
if (add_obs) then
  if (var .eq. "VBOT") then
    print("We are changing range for "+var)
    res@cnLevelSpacingF      =  1
    res@cnMinLevelValF       =  -7
    res@cnMaxLevelValF       =  7
  end if
  print("Obs average is :"+avg(MERRAvar))
  plot(lastPlotIndex) = gsn_csm_contour_map(wks,MERRAvar,res)
end if

print("Adding outline")
plot(0) = plot_outline_fcn(wks,plot(0),refinedOutlineColor,5.0)
if (add_diff) then
  plot(2) = plot_outline_fcn(wks,plot(2),refinedOutlineColor,5.0)
end if

; Modify panel plots and whatnot
resP                     = True                ; modify the panel plot
;resP@txString            = var

if isvar("obsString")
else
  obsString = "Obs"
end if
print("obsString is: "+obsString)

resP@amJust = wherepanel

if (oneLabelBar) then
  resP@gsnPanelLabelBar    = True
  resP@lbTitleString = refvar@units
  resP@lbTitlePosition  = "Right"              ; title position
  resP@lbLabelFontHeightF = .012
  resP@lbTitleFontHeightF= .015                ; make title smaller
  resP@lbTitleDirection = "Across"             ; title direction
  resP@lbTitleExtentF = 0.02
  resP@lbTitleOffsetF = 0.05
  ;resP@lbTitleJust = "TopCenter"
end if

if (var .eq. "PHIS") then
  res@gsnRightString="m s~S~-1~N~"
  resP@lbLabelStride = 8
end if

if (add_obs .and. add_diff) then
  resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni","c.) VR-Uni","d.) "+obsString/)
  gsn_panel(wks,plot,(/2,2/),resP)
else
  if (add_obs) then
    if (whichpanel .eq. "def")
      resP@gsnPanelFigureStrings= (/"d.) VR","e.) Uni","f.) "+obsString/)
    else if (whichpanel .eq. "ghi")
      resP@gsnPanelFigureStrings= (/"g.) VR","h.) Uni","i.) "+obsString/)
    else
      resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni","c.) "+obsString/)
    end if
    end if
    gsn_panel(wks,plot,(/1,3/),resP)
  else if (add_diff) then
    if (whichpanel .eq. "def")
      resP@gsnPanelFigureStrings= (/"d.) VR","e.) Uni","f.) VR-Uni"/)
    else if (whichpanel .eq. "ghi")
      resP@gsnPanelFigureStrings= (/"g.) VR","h.) Uni","i.) VR-Uni"/)
    else
      resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni","c.) VR-Uni"/)
    end if
    end if
    gsn_panel(wks,plot,(/1,3/),resP)
  else
    resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni"/)
    gsn_panel(wks,plot,(/2,1/),resP)
  end if
  end if
  
end if

end
