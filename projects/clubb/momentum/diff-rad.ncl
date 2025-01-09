load "./panel_two_sets.ncl"

begin

f0 = addfile("netcdf/RCE.QPC6.ne0np4tcfplane.ne15x16.exp901.001_02.nc","r")
f1 = addfile("netcdf/RCE.QPC6.ne0np4tcfplane.ne15x16.exp902.001_02.nc","r")
output_type="png"

;varstr = "PRCIO"

var = f0->$varstr$

vardims = dimsizes(var)

arr = new((/3,vardims(0),vardims(1)/),typeof(var))

arr(0,:,:) = f0->$varstr$
arr(1,:,:) = f1->$varstr$
arr(2,:,:) = arr(1,:,:) - arr(0,:,:)

arr!0="dataset"
arr!1="lev"
arr!2="radius"
arr&lev = var&lev
arr&radius = var&radius

maxarr = max(arr(0:1,:,:))
minarr = min(arr(0:1,:,:))

diffmax = max((/abs(maxarr),abs(minarr)/))

print("maxarr: "+maxarr+"  minarr: "+minarr+"  diffmax: "+diffmax)



;---Plot
system("mkdir -p pngs")
wks  = gsn_open_wks(output_type,"./pngs/diff_"+varstr)             ; send graphics to PNG file

res                     = True
res@gsnDraw             = False
res@gsnFrame            = False
res@cnFillMode = "RasterFill"
res@cnLevelSelectionMode= "ExplicitLevels"   ; manual set levels
res@cnLevels            = fspan(minarr,maxarr,15)
;res@lbLabelStrings      = sprintf("%5.1f",res@cnLevels)
res@cnFillOn            = True             ; color fill plot
res@cnFillPalette       = "BlAqGrYeOrRe"
res@cnLinesOn           = False
res@cnLineLabelsOn      = False
res@cnInfoLabelOn       = False
res@lbLabelBarOn        = False            ; turn off individual label bars
plot = new(2,graphic)

res@gsnLeftString       = varstr
;res@gsnRightString      = "~S~o~N~C"

res@lbBoxEndCapStyle    = "TriangleBothEnds"    ; Added in NCL V6.4.0

res@gsnCenterString     = "microp_uniform=False"
plot(0) = gsn_csm_contour(wks,arr(0,:,:),res)

res@gsnCenterString     = "microp_uniform=True"
plot(1) = gsn_csm_contour(wks,arr(1,:,:),res)

res@cnLevels            := fspan(-0.5*diffmax,0.5*diffmax,15)
;res@lbLabelStrings      := sprintf("%5.1f",res@cnLevels)
res@cnFillPalette       = "BlueWhiteOrangeRed"    ; select a color map with white in the middle

res@gsnCenterString     = "Diff: T - F"
plot2 = gsn_csm_contour(wks, arr(2,:,:) ,res)

;---Panel the two sets of plots. Note no special resources need to be set.
pres1 = True
pres2 = True
pres  = True
pres1@lbLabelFontHeightF = 0.01
pres2@lbLabelFontHeightF = 0.01
pres1@gsnPanelMainString = varstr+": "+var@long_name
pres@gsnPanelTop          = 0.95    ; must set to make room for title
panel_two_sets(wks,plot,plot2,(/1,2/),(/1,1/),pres1,pres2,pres)




end
