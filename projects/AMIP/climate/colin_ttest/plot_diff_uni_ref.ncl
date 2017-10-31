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

add_obs  = True
add_diff = True
whichpanel = "def"
wherepanel = "TopRight" ; TopLeft or TopRight
var = "Q600"
region = "refinedplus" ; options are "refined", "refinedplus", "Caribbean", "SierraMadre", "global", "refinedplus","ZoomCaribbean"
out_type = "pdf"
oneLabelBar = True

refin = systemfunc("ls /glade/scratch/zarzycki/AMIPmonthly/????/atl30x4_monthlyavg_??????_3D.nc")
reffile = addfiles(refin,"r")
  ListSetType(reffile,"cat")
uniin = systemfunc("ls /glade/scratch/zarzycki/AMIPmonthly/????/ne30_monthlyavg_??????_3D.nc")
unifile = addfiles(uniin,"r")
  ListSetType(unifile,"cat")

print("Reading data")
if (var .eq. "U200") then  
  refvar_se = reffile[:]->U
    reflon = refvar_se&lon
    reflat = refvar_se&lat
  univar_native = unifile[:]->U
    unilon = univar_native&lon
    unilat = univar_native&lat
  
; 2 deg lon
coarselon = unilon(::2)
coarselat = unilat(::2)

  print("Regridding the data")
  refvar_native  = area_conserve_remap_Wrap(reflon,reflat,refvar_se,coarselon,coarselat,False)
  univar_native2 = area_conserve_remap_Wrap(unilon,unilat,univar_native,coarselon,coarselat,False)

  delete(univar_native)
  univar_native = univar_native2
  delete(univar_native2)

  linlog = 2
  lev = refvar_native&lev
  refvar_int = int2p_n_Wrap(lev,refvar_native,(/200./),linlog,1)
  univar_int = int2p_n_Wrap(lev,univar_native,(/200./),linlog,1)
  
  refvar_all = refvar_int(:,0,:,:)
  univar_all = univar_int(:,0,:,:)
  
  refvar = dim_avg_n_Wrap(refvar_all,0)
  univar = dim_avg_n_Wrap(univar_all,0)
  
  delete([/refin,reffile,uniin,unifile,refvar_int,univar_int,refvar_native,refvar_se/])

else if (var .eq. "Q600") then
  refvar_se = reffile[:]->Q
    reflon = refvar_se&lon
    reflat = refvar_se&lat
  univar_native = unifile[:]->Q
    unilon = univar_native&lon
    unilat = univar_native&lat

; 2 deg lon
coarselon = unilon(::2)
coarselat = unilat(::2)
  
  print("Regridding the data")
  refvar_native  = area_conserve_remap_Wrap(reflon,reflat,refvar_se,coarselon,coarselat,False)
  univar_native2 = area_conserve_remap_Wrap(unilon,unilat,univar_native,coarselon,coarselat,False)

  delete(univar_native)
  univar_native = univar_native2
  delete(univar_native2)

  linlog = 2
  lev = refvar_native&lev
  refvar_int = int2p_n_Wrap(lev,refvar_native,(/600./),linlog,1)
  univar_int = int2p_n_Wrap(lev,univar_native,(/600./),linlog,1)
  
  refvar_all = refvar_int(:,0,:,:)
  univar_all = univar_int(:,0,:,:)
  
  refvar = dim_avg_n_Wrap(refvar_all,0)
  univar = dim_avg_n_Wrap(univar_all,0)
  
  delete([/refin,reffile,uniin,unifile,refvar_int,univar_int,refvar_native,refvar_se/])
else if (var .eq. "T850") then
  refvar_se = reffile[:]->T
    reflon = refvar_se&lon
    reflat = refvar_se&lat
  univar_native = unifile[:]->T
    unilon = univar_native&lon
    unilat = univar_native&lat

; 2 deg lon
coarselon = unilon(::2)
coarselat = unilat(::2)
  
  print("Regridding the data")
  refvar_native  = area_conserve_remap_Wrap(reflon,reflat,refvar_se,coarselon,coarselat,False)
  univar_native2 = area_conserve_remap_Wrap(unilon,unilat,univar_native,coarselon,coarselat,False)

  delete(univar_native)
  univar_native = univar_native2
  delete(univar_native2)

  linlog = 2
  lev = refvar_native&lev
  refvar_int = int2p_n_Wrap(lev,refvar_native,(/850./),linlog,1)
  univar_int = int2p_n_Wrap(lev,univar_native,(/850./),linlog,1)
  
  refvar_all = refvar_int(:,0,:,:)
  univar_all = univar_int(:,0,:,:)
  
  refvar = dim_avg_n_Wrap(refvar_all,0)
  univar = dim_avg_n_Wrap(univar_all,0)
  
  delete([/refin,reffile,uniin,unifile,refvar_int,univar_int,refvar_native,refvar_se/])
end if
end if  
end if

print("Calculating differences")
diffvar = refvar
diffvar = refvar - univar
varmax = max(refvar)
varmin = min(refvar)

if (add_obs) then
  if (var .eq. "U200") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/uwnd.mon.ltm.nc","r")
    MERRAvar_full = MERRAfile->uwnd(:,{200},::-1,:)
    MERRAlat = MERRAfile->lat(::-1)
    MERRAlon = MERRAfile->lon
    MERRAvar = dim_avg_n_Wrap(MERRAvar_full,0)
    MERRAvar@units = "m/s"
    obsString = "NCEP"
  else if (var .eq. "Q600") then
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/uwnd.mon.ltm.nc","r")
    MERRAvar_full = MERRAfile->uwnd(:,{200},::-1,:)
    MERRAlat = MERRAfile->lat(::-1)
    MERRAlon = MERRAfile->lon
    MERRAvar = dim_avg_n_Wrap(MERRAvar_full,0)
    MERRAvar@units = "kg/kg"
    obsString = "NCEP"
  else if (var .eq. "T850") then    
    MERRAfile = addfile("/glade/u/home/zarzycki/work/ncep/air.mon.ltm.nc","r")
    MERRAvar_full = MERRAfile->air(:,{850},::-1,:)
    MERRAlat = MERRAfile->lat(::-1)
    MERRAlon = MERRAfile->lon
    MERRAtmp = dim_avg_n_Wrap(MERRAvar_full,0)
    MERRAvar = MERRAtmp + 273.15   ; convert to K
      copy_VarMeta(MERRAtmp,MERRAvar)
    MERRAvar@units = "K"
    obsString = "NCEP"
  else
    print("That variable is not MERRA-supported")
    print("Please fix or turn off MERRA plot")
    exit
  end if
  end if
  end if
end if

if (add_obs .and. add_diff) then
  outputName = "diffplots_"+var+"_quad_"+region
  wks  = gsn_open_wks(out_type,outputName)
else
  outputName = "diffplots_"+var+"_"+whichpanel+"_"+region
  wks  = gsn_open_wks(out_type,outputName)
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
if (var .eq. "U200") then
  res@cnLevelSpacingF      =  5.
  res@cnMinLevelValF       =  -10.
  res@cnMaxLevelValF       =  50.
  res_diff@cnLevelSpacingF      =  1.
  res_diff@cnMinLevelValF       =  -8.
  res_diff@cnMaxLevelValF       =  8.
else if (var .eq. "Q600") then
  res@cnLevelSpacingF      =  0.0005
  res@cnMinLevelValF       =  0.0
  res@cnMaxLevelValF       =  0.005
  res_diff@cnLevelSpacingF      =  0.0002
  res_diff@cnMinLevelValF       =  -0.001
  res_diff@cnMaxLevelValF       =  0.001
else if (var .eq. "T850") then
  res@cnLevelSpacingF      =  5.
  res@cnMinLevelValF       =  235.
  res@cnMaxLevelValF       =  300.
  res_diff@cnLevelSpacingF      =  1.
  res_diff@cnMinLevelValF       =  -8.
  res_diff@cnMaxLevelValF       =  8.
end if
end if
end if

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

if (oneLabelBar) then
  res@lbLabelBarOn = False
end if

;=========================
; Student t test
; one sided, sig level = 0.1

  sig = 0.10

  avg_ref = dim_avg_n(refvar_all,0)
  var_ref = dim_variance_n(refvar_all,0)
  dims_ref = dimsizes(refvar_all)
  size_ref = dims_ref(0)

  avg_uni = dim_avg_n(univar_all,0)
  var_uni = dim_variance_n(univar_all,0)
  dims_uni = dimsizes(univar_all)
  size_uni = dims_uni(0)

  prob = ttest(avg_ref,var_ref,size_ref,avg_uni,var_uni,size_uni,False,False)
  ;prob = prob*0.5    ; make one sided
	 copy_VarCoords(refvar,prob)

;==========================

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
  print("Obs average is :"+avg(MERRAvar))
  plot(lastPlotIndex) = gsn_csm_contour_map(wks,MERRAvar,res)
end if

print("Adding ttest pattern")
; resources for ttest probability
  res2 = True
  res2@gsnFrame = False
  res2@gsnDraw = False
  
  res2@cnLevelSelectionMode = "ExplicitLevels"
  res2@cnLevels       = (/sig/)  ; one contour level (for line around pattern)
  res2@cnLinesOn      = True     ; turn on contour lines
  res2@cnLineLabelsOn = False    ; turn off line labels
  res2@cnInfoLabelOn  = False    ; turn off label box
;  res2@lbLabelBarOn   = False    ; turn off label bar


; options for fill pattern
  opt = True
  opt@gsnShadeFillType = "pattern"
  opt@gsnShadeLow = 4

; repeat four times otherwise ncl gets mad
  plot0 = gsn_csm_contour(wks,prob,res2)
    plot0 = gsn_contour_shade(plot0,sig,999,opt)
  plot1 = gsn_csm_contour(wks,prob,res2)
    plot1 = gsn_contour_shade(plot1,sig,999,opt)
  plot2 = gsn_csm_contour(wks,prob,res2)
    plot2 = gsn_contour_shade(plot2,sig,999,opt)
  plot3 = gsn_csm_contour(wks,prob,res2)
    plot3 = gsn_contour_shade(plot3,sig,999,opt)  

; overlay ttest pattern onto plots  
  overlay(plot(0),plot0)
  overlay(plot(1),plot1)
if (add_diff) then
  overlay(plot(2),plot2)
end if
if (add_obs) then
  overlay(plot(3),plot3)
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
