;*************************************************
; panel_18.ncl
;
; Concepts illustrated:
;   - Combining two sets of paneled plots on one page
;   - Maximizing plots after they've been created
;   - Drawing two labelbars in a combined panel plot
;   - Using cnFillPalette to assign a color palette to contours
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;**************************************************
; Read data
;**************************************************
    config1="REF"
    config2="EXT"
    f1  = addfile("~/scratch/avg_"+config1+".nc","r")
    f2  = addfile("~/scratch/avg_"+config2+".nc","r")
    varname="PRECC"
    var1 = f1->$varname$(0,:,:)
    var2 = f2->$varname$(0,:,:)
    if (varname .eq. "PRECT" .or. varname .eq. "PRECC" .or. varname .eq. "PRECL") then
      var1 = var1*8.64e7
      var2 = var2*8.64e7
    end if
    ;var1 = f1->TMQ(0,:,:)
    ;var2 = f2->TMQ(0,:,:)
;**************************************************
; calculate difference
;**************************************************
    diff                    = var1           ; trick to create array with coordinate info
    diff                    = var2 - var1     ; over write values with differences
    print("========================================")
    printVarSummary(diff)   
    print(" min="+min(diff)+"   max="+max(diff))
;**************************************************
; plot
;**************************************************
    wks  = gsn_open_wks("pdf",varname+"_"+config1+"_"+config2)         ; send graphics to PNG file
    
    res                     = True
    res@gsnDraw             = False
    res@gsnFrame            = False
    res@mpFillOn            = False            ; no need   
    res@cnLevelSelectionMode= "ManualLevels"   ; manual set levels
    res@cnMinLevelValF      = 2.0
    res@cnMaxLevelValF      = 22.0
    res@cnLevelSpacingF     = 2.0              ; 20 contour levels      
    res@cnFillOn            = True             ; color fill plot
    res@cnFillPalette       = "WhiteBlueGreenYellowRed"
    res@cnLinesOn           = False
    res@cnLineLabelsOn      = False
    res@cnInfoLabelOn       = False
    res@lbLabelBarOn        = False            ; turn off individual label bars

    res@mpMinLatF             = 0.
    res@mpMaxLatF             = 60.
    res@mpMinLonF             = -105.
    res@mpMaxLonF             = 30.
    res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2

    res@gsnLeftString=""
    res@gsnRightString=""

    plot = new(2,graphic)    
    

    res@gsnCenterString     = varname+"_"+config1
    plot(0) = gsn_csm_contour_map(wks,var1,res)

    res@gsnCenterString     = varname+"_"+config2
    plot(1) = gsn_csm_contour_map(wks,var2,res)
    
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
    
    res@cnMinLevelValF      = -2.5
    res@cnMaxLevelValF      =  2.5
    res@cnLevelSpacingF     =  0.25
    res@cnFillPalette       = "BlueWhiteOrangeRed"    ; select a color map with white in the middle

    res@gsnCenterString     = "Difference: "+config2+"-"+config1
    plot2 = gsn_csm_contour_map(wks, diff ,res)
    
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
end
