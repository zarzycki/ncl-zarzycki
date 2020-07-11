fdir1="/glade/scratch/zarzycki/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime1800/atm/hist/"
fnampattern="*cam.h0.19??-[0-1][890]*.nc"
wgt_file="/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_1.0x1.0_GLOB.nc"

filelist = systemfunc ("find "+fdir1+" -name '"+fnampattern+"' | grep -v 1984- | grep -v 1994- | grep -v regrid.nc | sort -n")
;print(filelist)

f = addfiles(filelist,"r")
dsizes = getfiledimsizes(f[0])

varlist=(/"PRECL","PRECC","SHFLX","LHFLX","TMQ","PSL","CLDTOT"/)

do ii = 0,dimsizes(varlist)-1

  thisvar = varlist(ii)
  PRECC=f[:]->$thisvar$

  Opt         = True
  PRECC_rll = ESMF_regrid_with_weights(PRECC,wgt_file,Opt)

  MinLatF             = 5.
  MaxLatF             = 35.
  MinLonF             = -90.
  MaxLonF             = -15.


  PRECC_avg=dim_avg_n_Wrap(PRECC_rll(:,{MinLatF:MaxLatF},{MinLonF:MaxLonF}),0)

  rad = 4.0*atan(1.0)/180.0
  PRECC_amean = wgt_areaave_Wrap(PRECC_avg, cos(rad*PRECC_avg&lat), 1.0, 0)

  print(thisvar+" "+PRECC_amean)

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


