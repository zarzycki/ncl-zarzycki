 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;fnames = (/"/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc",\
; "/glade/scratch/zarzycki/APE_levy/CAM5_MAM/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc"/)
 
fnames = (/"/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h0avg.nc",\
 "/glade/scratch/zarzycki/APE_levy/CAM5_MAM/quadrant_15_x8/h0avg.nc"/)
 	
wnames = (/"/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc",\
 "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"/)
 
 if_regrid = True

output_format = "x11"
run_names = (/"quadrant_15_x8_BAM", "quadrant_15_x8_MAM"/)
varNames = (/"PRECT","CLDTOT","ICIMR"/)
nclVarNames = (/"bamdata","mamdata"/)

m = 2
wgt = wnames(0)

bamfile = addfile(fnames(0),"r")
mamfile = addfile(fnames(1),"r")

wks = gsn_open_wks( output_format , "MAMBAMdiff_"+varNames(m) )
plot = new(3,graphic)

; Load BULK
if (if_regrid .eq. True)
  ps_se = bamfile->$varNames(m)$(0,{200},:)
  ps = ESMF_regrid_with_weights(ps_se,wgt,False)
  delete(ps_se)
  lon = ps&lon
else
  ps = bamfile->$varNames(m)$(0,{200},:,:)
end if

bamdata = ps
delete(ps)

if (if_regrid .eq. True)
  ps_se = mamfile->$varNames(m)$(0,{200},:)
  ps = ESMF_regrid_with_weights(ps_se,wgt,False)
  delete(ps_se)
  lon = ps&lon
else
  ps = mamfile->$varNames(m)$(0,{200},:,:)
end if

mamdata = ps
delete(ps)

res = True
resdiff = True
res@gsnDraw = False
res@gsnFrame = False
res@cnFillOn             = True               ; turn on color fill
res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels
res@mpOutlineOn = False

gsn_define_colormap(wks,"BlWhRe")             ; choose colormap

if (varNames(m).eq."PRECT" ) then
  ; convert to mm/day
  bamdata=bamdata*1000*24*3600
  bamdata@units="mm/day"
  mamdata=mamdata*1000*24*3600
  mamdata@units="mm/day"
  res@cnLevelSelectionMode = "ManualLevels"
  resdiff = res  
  res@cnMinLevelValF = 0.
  res@cnMaxLevelValF = 33.
  res@cnLevelSpacingF = 3.
  resdiff@cnMinLevelValF = -8.
  resdiff@cnMaxLevelValF = 8.
  resdiff@cnLevelSpacingF = 1.
end if
if (varNames(m).eq."CLDTOT" ) then
  res@cnLevelSelectionMode = "ManualLevels"
  resdiff = res  
  res@cnMinLevelValF = 0.5
  res@cnMaxLevelValF = 1.
  res@cnLevelSpacingF = .05
  resdiff@cnMinLevelValF = -.2
  resdiff@cnMaxLevelValF = .2
  resdiff@cnLevelSpacingF = .02
end if
if (varNames(m).eq."TGCLDCWP" ) then
  res@cnLevelSelectionMode = "ManualLevels"
  resdiff = res  
  res@cnMinLevelValF = 0
  res@cnMaxLevelValF = .20
  res@cnLevelSpacingF = .02
  resdiff@cnMinLevelValF = -.04
  resdiff@cnMaxLevelValF = .04
  resdiff@cnLevelSpacingF = .005
end if
if (varNames(m).eq."PBLH" ) then
  res@cnLevelSelectionMode = "ManualLevels"
  resdiff = res  
  res@cnMinLevelValF = 200.
  res@cnMaxLevelValF = 1000.
  res@cnLevelSpacingF = 50.
  resdiff@cnMinLevelValF = -100.
  resdiff@cnMaxLevelValF = 100.
  resdiff@cnLevelSpacingF = 10.
end if
if (varNames(m).eq."TMQ" ) then
  res@cnLevelSelectionMode = "ManualLevels"
  resdiff = res  
  res@cnMinLevelValF = 0.
  res@cnMaxLevelValF = 60.
  res@cnLevelSpacingF = 5.
  resdiff@cnMinLevelValF = -9.
  resdiff@cnMaxLevelValF = 9.
  resdiff@cnLevelSpacingF = 3.
end if

  print((/min(bamdata),max(bamdata)/))
  print((/min(mamdata),max(mamdata)/))


diff = mamdata
diff = mamdata - bamdata

plot(0) = gsn_csm_contour_map(wks,bamdata,res)
plot(1) = gsn_csm_contour_map(wks,mamdata,res)
plot(2) = gsn_csm_contour_map(wks,diff,resdiff)

resP                  = True                   ; modify the panel plot
;resP@gsnPanelLabelBar = True                   ; add common colorbar
;resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
;resP@lbLabelStride    = 4
;resP@pmLabelBarWidthF = 0.7
amres = True
amres@amJust           = "TopLeft"
resP@gsnPanelFigureStrings= (/"a.","b.","c."/)
resP@gsnPanelFigureStringsFontHeightF = 0.02
  
gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot

print( "Thank you, come again." + systemfunc("date") )


end