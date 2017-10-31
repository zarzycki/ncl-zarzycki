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
whichpanel = "abc"
var = "U"
out_type = "pdf"
region = "refined" ; options are "refined", "refinedplus", "Caribbean", "SierraMadre", "global", "refinedplus"

if region .eq. "refined" then
  MinLatF   = 0.                 
  MaxLatF   = 55.
  MinLonF   = 280.
  MaxLonF   = 340.
  
;  minlat=8
;maxlat=43
;minlon=280
;maxlon=340
else if region .eq. "refinedplus" then
  MinLatF   = -25.
  MaxLatF   = 80.
  MinLonF   = -130.
  MaxLonF   = 30.
else if region .eq. "Caribbean" then
  MinLatF   = 0.
  MaxLatF   = 30.
  MinLonF   = -100.
  MaxLonF   = -65.
else if region .eq. "SierraMadre" then
  MinLatF   = 7.
  MaxLatF   = 23.
  MinLonF   = -102.
  MaxLonF   = -88.
else
  MinLatF   = -90.
  MaxLatF   = 90.
  MinLonF   = -180.
  MaxLonF   = 180.
end if
end if
end if
end if

reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_all_climo_3D.nc","r")
unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_all_climo_3D.nc_regrid.nc","r")
refvar_full = reffile->$var$(0,:,{MinLatF:MaxLatF},{MinLonF:MaxLonF})
univar_full = unifile->$var$(0,:,{MinLatF:MaxLatF},{MinLonF:MaxLonF})
refvar = dim_avg_n_Wrap(refvar_full,2)
univar = dim_avg_n_Wrap(univar_full,2)


print("Calculating differences")
diffvar = refvar
diffvar = refvar - univar
varmax = max(refvar)
varmin = min(refvar)

if (add_obs) then
  if (var .eq. "U") then
    MERRAfile = addfile("/glade/u/home/zarzycki/scratch/ncep/uwnd.mon.ltm.nc","r")
    MERRAvar_full = MERRAfile->uwnd(:,:,{MinLatF:MaxLatF},{MinLonF:MaxLonF})
    MERRAvar_sub = dim_avg_n_Wrap(MERRAvar_full,0)
    MERRAvar = dim_avg_n_Wrap(MERRAvar_sub,2)
    MERRAvar@units = "m/s"
    obsString = "NCEP"
  else
    print("That variable is not MERRA-supported")
    print("Please fix or turn off MERRA plot")
    exit
  end if
end if

if (add_obs .and. add_diff) then
  wks  = gsn_open_wks(out_type,"diffcx_"+var+"_quad_"+region)
else
  wks  = gsn_open_wks(out_type,"diffcx_"+var+"_"+whichpanel+"_"+region)
end if

if (add_obs .and. add_diff) then
  plot = new(4,graphic)
else
  plot = new(3,graphic)
end if

res                             = True
res@gsnFrame = False
res@gsnDraw = False

  res@trYMinF = 100
  res@trYMaxF = 1000
  res@tmYRMode             = "Automatic"          ; turn off special labels on right axis
  
res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels
res@cnFillOn=True
res@gsnSpreadColors = True

res@cnLevelSelectionMode = "ManualLevels"

res_diff = res
if (var .eq. "U") then
  res@cnLevelSpacingF      =  3.
  res@cnMinLevelValF       =  -5.
  res@cnMaxLevelValF       =  25.
  res_diff@cnLevelSpacingF      =  0.5
  res_diff@cnMinLevelValF       =  -3.
  res_diff@cnMaxLevelValF       =  3.
end if

if (.not. add_obs .and. .not. add_diff) then
  res@gsnLeftString=""
  res@gsnRightString=""
  res@lbLabelBarOn        = False
else if (add_obs .and. add_diff) then
  res@gsnLeftString=""
  res_diff@gsnLeftString=""
else
end if
end if




;print("Adding outline")
;plot(0) = plot_outline_fcn(wks,plot(0),"black",2.0)
;if (add_diff) then
;  plot(2) = plot_outline_fcn(wks,plot(2),"black",2.0)
;end if
  


refvar&lev@units = "hPa" 
refvar&lev@long_name = "Pressure (hPa)" 
univar&lev@units = "hPa"
univar&lev@long_name = "Pressure (hPa)" 
plot(0)  = gsn_csm_pres_hgt(wks, refvar, res )
plot(1)  = gsn_csm_pres_hgt(wks, univar, res )

plres                  = True
plres@gsLineColor      = "black"
plres@gsLineThicknessF = 2.5
pgy = (/ 0.1, 10000. /) ;needs to be small number if on log scale
pgx1 = (/ 8., 8. /)
pgx3 = (/ 43., 43. /)
dum1 = gsn_add_polyline(wks, plot(0), pgx1, pgy, plres)
dum2 = gsn_add_polyline(wks, plot(0), pgx3, pgy, plres)

;plot(0) = gsn_csm_contour_map(wks,refvar,res)
  print("V-R average is :"+avg(refvar))
;plot(1) = gsn_csm_contour_map(wks,univar,res)
  print("Uni average is :"+avg(univar))
lastPlotIndex = 2
if (add_diff) then
  diffvar&lev@units = "hPa" 
  diffvar&lev@long_name = "Pressure (hPa)" 
  plot(2) = gsn_csm_pres_hgt(wks,diffvar,res_diff)
  dum3 = gsn_add_polyline(wks, plot(2), pgx1, pgy, plres)
  dum4 = gsn_add_polyline(wks, plot(2), pgx3, pgy, plres)
  lastPlotIndex = lastPlotIndex + 1
end if
if (add_obs) then
  print("Obs average is :"+avg(MERRAvar))
  MERRAvar&level@units = "hPa" 
  MERRAvar&level@long_name = "Pressure (hPa)" 
  plot(lastPlotIndex) = gsn_csm_pres_hgt(wks,MERRAvar,res)
end if

; Modify panel plots and whatnot
resP                     = True                ; modify the panel plot
;resP@txString            = var

if isvar("obsString")
else
  obsString = "Obs"
end if
print("obsString is: "+obsString)

resP@amJust = "TopLeft"
if (add_obs .and. add_diff) then
  resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni","c.) VR-Uni","d.) "+obsString/)
  gsn_panel(wks,plot,(/2,2/),resP)
else
  if (add_obs) then
    if (whichpanel .eq. "def")
      resP@gsnPanelFigureStrings= (/"d.) VR","e.) Uni","f.) "+obsString/)
    else
      resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni","c.) "+obsString/)
    end if
    gsn_panel(wks,plot,(/1,3/),resP)
  else if (add_diff) then
    resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni","c.) VR-Uni"/)
    gsn_panel(wks,plot,(/1,3/),resP)
  else
    resP@gsnPanelLabelBar    = True
    resP@gsnPanelFigureStrings= (/"a.) VR","b.) Uni"/)
    resP@lbTitleString = refvar@units
    resP@lbTitlePosition  = "Right"              ; title position
    resP@lbTitleFontHeightF= .02                ; make title smaller
    resP@lbTitleDirection = "Across"             ; title direction
    resP@lbTitleExtentF = 0.05
    ;resP@lbTitleJust = "TopCenter"
    gsn_panel(wks,plot,(/2,1/),resP)
  end if
  end if
  
end if

end


