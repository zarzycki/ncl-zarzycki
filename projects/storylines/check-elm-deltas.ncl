load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

var="TBOT"
month="12"
wgt_file="/global/homes/c/czarzyck/m2637/betacast/sewx/maps/map_conus_30_x8_to_1x1glob_patch.nc"

f_lens = addfile("/global/homes/c/czarzyck/scratch/DATM_FORCING/ANOM_LENS/ens_TBOT_anom.nc","r")
timestamp=11 + toint(month)
T12 = f_lens->T(timestamp,:,:)
T11 = f_lens->T(timestamp-1,:,:)
T11 = (T12 + T11) / 2.

f_ref = addfile("/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/Y-RoS-ICLM45-ne0conus30x8-004_19960113_0012/run/Y-RoS-ICLM45-ne0conus30x8-004_19960113_0012.elm.h0.1995-"+month+".nc","r")
f_ref_var = f_ref->$var$(0,:)
lon1d=f_ref->lon
lat1d=f_ref->lat
landfrac=f_ref->landfrac

Opt         = True
landfrac_regrid = ESMF_regrid_with_weights(landfrac,wgt_file,Opt)

f1=addfile("/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/RoS-ICLM45-ne0conus30x8-004_1921/run/no_offset/RoS-ICLM45-ne0conus30x8-004_1921.elm.h0.1995-"+month+".nc","r")
f1_var=f1->$var$(0,:)
f1_anom = f1_var
f1_anom = f1_var - f_ref_var
f1_anom_regrid = ESMF_regrid_with_weights(f1_anom,wgt_file,Opt)
f1_anom_regrid=where(landfrac_regrid.lt.0.1,f1_anom_regrid@_FillValue,f1_anom_regrid)
f1_anom_str="DATM +00 d"

f2=addfile("/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/RoS-ICLM45-ne0conus30x8-004_1921/run/with_offset/RoS-ICLM45-ne0conus30x8-004_1921.elm.h0.1995-"+month+".nc","r")
f2_var=f2->$var$(0,:)
f2_anom = f2_var
f2_anom = f2_var - f_ref_var
f2_anom_regrid = ESMF_regrid_with_weights(f2_anom,wgt_file,Opt)
f2_anom_regrid=where(landfrac_regrid.lt.0.1,f2_anom_regrid@_FillValue,f2_anom_regrid)
f2_anom_str="DATM -15 d"

f3=addfile("/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/RoS-ICLM45-ne0conus30x8-004_1921/run/RoS-ICLM45-ne0conus30x8-004_1921.elm.h0.1995-"+month+".nc","r")
f3_var=f3->$var$(0,:)
f3_anom = f3_var
f3_anom = f3_var - f_ref_var
f3_anom_regrid = ESMF_regrid_with_weights(f3_anom,wgt_file,Opt)
f3_anom_regrid=where(landfrac_regrid.lt.0.1,f3_anom_regrid@_FillValue,f3_anom_regrid)
f3_anom_str="DATM -0.2 d"

f4=addfile("/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/RoS-ICLM45-ne0conus30x8-ERA5/run/RoS-ICLM45-ne0conus30x8-ERA5.elm.h0.1995-"+month+".nc","r")
f4_var=f4->$var$(0,:)
f4_anom = f4_var
f4_anom = f4_var - f_ref_var
f4_anom_regrid = ESMF_regrid_with_weights(f4_anom,wgt_file,Opt)
f4_anom_regrid=where(landfrac_regrid.lt.0.1,f4_anom_regrid@_FillValue,f4_anom_regrid)
f4_anom_str="Hard files"


print(""+escorc(f_ref_var,f1_var))
print(""+escorc(f_ref_var,f2_var))
print(""+escorc(f_ref_var,f3_var))
print(""+escorc(f_ref_var,f4_var))

print("=========")
print(""+escorc(f4_var,f1_var)+" "+dim_rmsd(f4_var,f1_var)+" "+avg(f4_var-f1_var))
print(""+escorc(f4_var,f2_var)+" "+dim_rmsd(f4_var,f2_var)+" "+avg(f4_var-f2_var))
print(""+escorc(f4_var,f3_var)+" "+dim_rmsd(f4_var,f3_var)+" "+avg(f4_var-f3_var))



T12_regrid = linint2_Wrap (T12&lon,T12&lat,T12, True, f1_anom_regrid&lon,f1_anom_regrid&lat, 0)
T11_regrid = linint2_Wrap (T11&lon,T11&lat,T11, True, f1_anom_regrid&lon,f1_anom_regrid&lat, 0)
T12_regrid = where(ismissing(f1_anom_regrid),T12_regrid@_FillValue,T12_regrid)
T11_regrid = where(ismissing(f1_anom_regrid),T11_regrid@_FillValue,T11_regrid)

print("********* 12 average")
clat = cos(0.01745329*f1_anom_regrid&lat) 
print(f1_anom_str+" "+pattern_cor(T12_regrid,f1_anom_regrid,clat,0)+" "+wgt_arearmse(T12_regrid,f1_anom_regrid,clat,1.0,0))
print(f2_anom_str+" "+pattern_cor(T12_regrid,f2_anom_regrid,clat,0)+" "+wgt_arearmse(T12_regrid,f2_anom_regrid,clat,1.0,0))
print(f3_anom_str+" "+pattern_cor(T12_regrid,f3_anom_regrid,clat,0)+" "+wgt_arearmse(T12_regrid,f3_anom_regrid,clat,1.0,0))
print(f4_anom_str+" "+pattern_cor(T12_regrid,f4_anom_regrid,clat,0)+" "+wgt_arearmse(T12_regrid,f4_anom_regrid,clat,1.0,0))
print("********* 11/12 average")
clat = cos(0.01745329*f1_anom_regrid&lat) 
print(f1_anom_str+" "+pattern_cor(T11_regrid,f1_anom_regrid,clat,0)+" "+wgt_arearmse(T11_regrid,f1_anom_regrid,clat,1.0,0))
print(f2_anom_str+" "+pattern_cor(T11_regrid,f2_anom_regrid,clat,0)+" "+wgt_arearmse(T11_regrid,f2_anom_regrid,clat,1.0,0))
print(f3_anom_str+" "+pattern_cor(T11_regrid,f3_anom_regrid,clat,0)+" "+wgt_arearmse(T11_regrid,f3_anom_regrid,clat,1.0,0))
print(f4_anom_str+" "+pattern_cor(T11_regrid,f4_anom_regrid,clat,0)+" "+wgt_arearmse(T11_regrid,f4_anom_regrid,clat,1.0,0))

wks = gsn_open_wks("png",var+"_1921-"+month)               ; send graphics to PNG file
plot = new(6,graphic)                           ; create a plot array

res                     = True
res@gsnDraw             = False           ; don't draw
res@gsnFrame            = False           ; don't advance frame
res@cnFillOn            = True            ; turn on color
res@cnFillPalette       = "BlueWhiteOrangeRed"   ; set color map
res@cnLinesOn           = False           ; no contour lines
res@cnInfoLabelOn=False
res@mpFillOn            = False           ; no map fill
res@lbLabelBarOn        = False           ; turn off individual cb's
res@cnLineLabelsOn =False
res@cnLevelSelectionMode = "ManualLevels"
if (var .eq. "H2OSNO") then
;res@cnMinLevelValF       =  -20.
;res@cnMaxLevelValF       =   20.
;res@cnLevelSpacingF      =  1.
end if
if (var .eq. "TBOT") then
  res@cnMinLevelValF       =  -1.5
  res@cnMaxLevelValF       =   1.5
  res@cnLevelSpacingF      =  0.1
end if

res@mpMinLatF = 25.
res@mpMaxLatF = 55.
res@mpMinLonF = 230.
res@mpMaxLonF = 295.

res@gsnLeftString=f1_anom_str
plot(2) = gsn_csm_contour_map(wks,f1_anom_regrid,res)

res@gsnLeftString=f2_anom_str
plot(3) = gsn_csm_contour_map(wks,f2_anom_regrid,res)

res@gsnLeftString=f3_anom_str
plot(4) = gsn_csm_contour_map(wks,f3_anom_regrid,res)

res@gsnLeftString=f4_anom_str
plot(5) = gsn_csm_contour_map(wks,f4_anom_regrid,res)

res@gsnLeftString="1921-"+(toint(month)-1)+"/"+month+" avg anomaly from LENS"
plot(1) = gsn_csm_contour_map(wks,T11_regrid,res)

res@gsnLeftString="1921-"+month+" anomaly from LENS"
plot(0) = gsn_csm_contour_map(wks,T12_regrid,res)

resP                = True                ; panel only resources
resP@gsnMaximize    = True                ; maximize plots
resP@gsnPanelLabelBar    = True                ; add common colorbar
resP@gsnPanelMainString = var+" 1921-"+month     ; set main title
gsn_panel(wks,plot,(/3,2/),resP)          ; now draw as one plot



end
