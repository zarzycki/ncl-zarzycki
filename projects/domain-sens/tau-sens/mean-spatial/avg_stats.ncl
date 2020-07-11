fdir1="./MPI_GPI/"
fnampattern="GPI_tau3600_lowdmpdz2.nc_AVG.nc"

f = addfile(fdir1+"/"+fnampattern,"r")

varlist=(/"MPI","GPI","shear","Chi_m","vort_r"/)

do ii = 0,dimsizes(varlist)-1

  thisvar = varlist(ii)

  var=f->$thisvar$

  MinLatF             = 5.
  MaxLatF             = 35.
  MinLonF             = -90.
  MaxLonF             = -15.

  rad = 4.0*atan(1.0)/180.0
  var_amean = wgt_areaave_Wrap(var, cos(rad*var&lat), 1.0, 0)

  print(thisvar+" "+var_amean+" ")

end do
exit

;**************************************************
; plot
;**************************************************
wks  = gsn_open_wks("x11","test")         ; send graphics to PNG file

res                     = True
res@gsnDraw             = False
res@gsnFrame            = False
res@mpFillOn            = False            ; no need   
res@cnLevelSelectionMode= "ManualLevels"   ; manual set levels
res@cnMinLevelValF      = 1.0
res@cnMaxLevelValF      = 12.0
res@cnLevelSpacingF     = 1.0              ; 20 contour levels      
res@cnFillOn            = True             ; color fill plot
res@cnFillPalette       = "WhiteBlueGreenYellowRed"
res@cnLinesOn           = False
res@cnLineLabelsOn      = False
res@cnInfoLabelOn       = False
res@lbLabelBarOn        = False            ; turn off individual label bars

res@mpMinLatF             = MinLatF
res@mpMaxLatF             = MaxLatF
res@mpMinLonF             = MinLonF
res@mpMaxLonF             = MaxLonF
res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2
res@gsnAddCyclic = False

res@gsnLeftString=""
res@gsnRightString=""

plot = new(2,graphic)    


plot(0) = gsn_csm_contour_map(wks,PRECC_avg,res)

plot(1) = gsn_csm_contour_map(wks,PRECL_avg,res)

panres1                   = True                   ; modify the panel plot

panres1@mpMinLatF             = res@mpMinLatF
panres1@mpMaxLatF             = res@mpMaxLatF
panres1@mpMinLonF             = res@mpMinLonF
panres1@mpMaxLonF             = res@mpMaxLonF
panres1@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2

panres1@gsnFrame          = False                  ; don't advance frame yet
panres1@gsnPanelLabelBar  = True                   ; add common colorbar
panres1@gsnPanelTop       = 0.95                   ; Make sure not too close to 
panres1@gsnPanelBottom    = 0.35                   ; edge, so it maximizes better.
panres1@lbOrientation     = "vertical"
panres1@pmLabelBarWidthF  = 0.075                 ; make thinner
panres1@pmLabelBarHeightF = 0.25  

MAXIMIZE_OUTPUT           = True                  ; if maximization of plots is desired.

if(MAXIMIZE_OUTPUT) then
  panres1@gsnDraw = False                           ; draw later, in maximize mode
;
; It is necessary to return the id of the paneled plots,
; so they can "live" for the rest of this script, for
; when we maximize them later.
; 
  panelid1 = gsn_panel_return(wks,plot,(/2,1/),panres1) 
else
  panres1@gsnDraw = True
  gsn_panel(wks,plot,(/2,1/),panres1)               ; now draw as one 
end if

res@cnMinLevelValF      =  0.5
res@cnMaxLevelValF      =  1.0
res@cnLevelSpacingF     =  0.05
res@cnFillPalette       = "WhiteYellowOrangeRed"    ; select a color map with white in the middle

res@gsnCenterString     = ""
plot2 = gsn_csm_contour_map(wks, RATIO_avg ,res)

panres1@gsnPanelTop    = 0.35
panres1@gsnPanelBottom = .05

if(MAXIMIZE_OUTPUT) then
  panres1@gsnDraw = False                           ; draw later, in maximize mode
;
; It is necessary to return the id of the paneled plots,
; so they can "live" for the rest of this script, for
; when we maximize them later.
; 
  panelid2 = gsn_panel_return(wks,plot2,(/1,1/),panres1)

;---If maximization is desired, used this
  mres = True
  maximize_output(wks,mres)
else
  panres1@gsnDraw = True
  gsn_panel(wks,plot2,(/1,1/),panres1)
  frame(wks)
end if


