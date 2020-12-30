configs=(/"dtime1800","dtime900","tau3600","tau900","dtime450tau1800","tau3600_lowdmpdz2"/)
configs_pretty=(/"dt~B~1800~N~ - dt~B~900~N~","dt~B~900~N~","dt~B~450~N~ - dt~B~900~N~"/)

nconfig=dimsizes(configs)

plotMinLatF             = 2.
plotMaxLatF             = 32.
plotMinLonF             = -95.
plotMaxLonF             = -12.

MinLatF=5.
MaxLatF=25.
MinLonF=-70.
MaxLonF=-15.

varlist=(/"PRECT","PRECC","PRECL","OMEGA500","SHFLX","LHFLX","TMQ","GPI","Chi_m","vort_r","MPI","shear"/)
panelrow = new(dimsizes(varlist),integer)
;panelrow = -1
panelrow=(/ 2    ,   1   ,   0   ,  3   ,    -1     ,   -1  ,   -1 , -1  , 5    ,   6   ,  4  ,  7   /)

nvars = dimsizes(varlist)

netcdf_name="climo_avgs.nc"

; constants
rad = 4.0*atan(1.0)/180.0
letters=(/"a.","b.","c.","d.","e.","f.","g.","h.","i.","j.","k.","l.","m.","n.","o.","p.","q.","r.", "s.", "t.","u.","v.","w.","x.","y.","z.","aa.","bb."/)



; get file
f = addfile(netcdf_name,"r")

; read fileconfigs into memory by converting to string
fileconfigs=tostring(f->configs)


do zz = 0,nvars-1
  thisvar = varlist(zz)
  do ii = 0,nconfig-1

    ; find which index of full list of fileconfigs matches the config we want
    ix = ind(fileconfigs.eq.configs(ii))

    ; extract the var of this config
    PRECC_avg=f->$thisvar$(ix,:,:)

    if (thisvar .eq. "Chi_m") then
      PRECC_avg = where(PRECC_avg.gt.1.2,PRECC_avg@_FillValue,PRECC_avg)
    end if

    ; cut out the avg we want as an intermediate step
    PRECC_avg_sub = PRECC_avg({MinLatF:MaxLatF},{MinLonF:MaxLonF})
    ; perform averaging
    PRECC_amean := wgt_areaave_Wrap(PRECC_avg_sub, cos(rad*PRECC_avg_sub&lat), 1.0, 0)
    print(thisvar+" "+configs(ii)+" "+PRECC_amean)

    ; if this is the first config, build an nconfig x nlat x nlon array to store all data
    if (ii .eq. 0) then
      nlat:=dimsizes(PRECC_avg&lat)
      nlon:=dimsizes(PRECC_avg&lon)
      varArray:=new((/nconfig,nlat,nlon/),typeof(PRECC_avg))
    end if

    ; add to varArray
    varArray(ii,:,:) = PRECC_avg

    ; clean up
    delete(PRECC_avg_sub)
    delete(PRECC_avg)
  end do

  ; calculate differences relative to the 0th (first) config in array
  diffArr:=varArray
  do ii = 0,nconfig-1
    diffArr(ii,:,:)=varArray(ii,:,:)-varArray(1,:,:)
  end do

  ;**************************************************
  ; plot
  ;**************************************************
  wks  = gsn_open_wks("pdf","test_"+thisvar)         ; send graphics to PNG file

  res                     = True
  res@gsnDraw             = False
  res@gsnFrame            = False
  res@mpFillOn            = False            ; no need   
  res@cnLevelSelectionMode= "ManualLevels"   ; manual set levels
  if (thisvar .eq. "MPI")
    res@cnMinLevelValF      = 20.0
    res@cnMaxLevelValF      = 90.0
    res@cnLevelSpacingF     = 5.0
    diffRange = 25.0
    diffGap = 2.5
    units="m/s"
    longname="Maximum Potential Intensity"
  else if (thisvar .eq. "shear")
    res@cnMinLevelValF      = 0.0
    res@cnMaxLevelValF      = 10.0
    res@cnLevelSpacingF     = 1.0
    diffRange = 3.0
    diffGap = 0.3
    longname="850-250 hPa wind shear"
    units="m/s"
  else if (thisvar .eq. "Chi_m")
    res@cnMinLevelValF      = 0.0
    res@cnMaxLevelValF      = 1.0
    res@cnLevelSpacingF     = 0.1
    diffRange = 0.3
    diffGap = 0.03
    units=""
    longname="Saturation entropy deficit"
  else if (thisvar .eq. "TMQ")
    res@cnMinLevelValF      = 20.0
    res@cnMaxLevelValF      = 60.0
    res@cnLevelSpacingF     = 4.0
    diffRange = 8.
    diffGap = 1.0
    units="kg/m2"
    longname="TPW"
  else if (thisvar .eq. "GPI")
    res@cnMinLevelValF      = 0.0
    res@cnMaxLevelValF      = 80.0
    res@cnLevelSpacingF     = 8.0
    diffRange = 15.
    diffGap = 1.5
    units=""
    longname=""
  else if (thisvar .eq. "vort_r")
    res@cnMinLevelValF      = -1.0
    res@cnMaxLevelValF      =  1.0
    res@cnLevelSpacingF     = 0.1
    diffRange = 0.5
    diffGap = 0.05
    units="10~S~-5~N~ s~S~-1~N~"
    longname="Relative vorticity"
  else if (thisvar .eq. "OMEGA500")
    res@cnMinLevelValF      = -0.1
    res@cnMaxLevelValF      =  0.1
    res@cnLevelSpacingF     = 0.02
    diffRange = 0.04
    diffGap = 0.004*2.
    units="Pa/s"
    longname="500 hPa pressure velocity"
  else
    res@cnMinLevelValF      = 1.0
    res@cnMaxLevelValF      = 12.0
    res@cnLevelSpacingF     = 1.0
    diffRange = 3.0
    diffGap = 0.3*2.
    units="mm/day"
    if (thisvar .eq. "PRECC") then
      longname="Convective precip. rate"
    else if (thisvar .eq. "PRECL") then
      longname="Large-scale precip. rate"
    else
      longname="Total precip. rate"
    end if
    end if
  end if    
  end if
  end if
  end if
  end if
  end if
  end if

  ; contour stuff
  if (thisvar .eq. "PRECC" .or. thisvar .eq. "PRECL" .or.  thisvar .eq. "PRECT") then
    res@cnFillPalette       = "precip3_16lev"
  else if (thisvar .eq. "OMEGA500" .or. thisvar .eq. "vort_r") then
    res@cnFillPalette = "MPL_PiYG"
  else
    res@cnFillPalette       = "spread_15lev"
  end if
  end if
  res@cnFillOn            = True             ; color fill plot
  res@cnLinesOn           = False
  res@cnLineLabelsOn      = False
  res@cnInfoLabelOn       = False

  ; label bar stuff
  res@lbLabelFontHeightF=0.02
  res@pmLabelBarOrthogonalPosF = 0.18
  ;res@lbBoxEndCapStyle="TriangleBothEnds"

  ; tick mark stuff
  res@tmXBLabelFontHeightF=0.02
  res@tmYLLabelFontHeightF=0.02

  ; domain size stuff
  res@mpMinLatF             = plotMinLatF
  res@mpMaxLatF             = plotMaxLatF
  res@mpMinLonF             = plotMinLonF
  res@mpMaxLonF             = plotMaxLonF
  res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2
  res@gsnAddCyclic = False

  ; strings
  res@gsnLeftString=""
  res@gsnRightString=units
  res@gsnCenterString=longname

  plot_old = False
  if (plot_old) then

    res@lbLabelBarOn        = False            ; turn off individual label bars


    plot = new(1,graphic)
    lnid = plot
 
    plot(0) = gsn_csm_contour_map(wks,varArray(0,:,:),res)

    lnres=True
    lnres@gsLineThicknessF = 4.0
    lnid(0) = gsn_add_polyline(wks,plot(0),(/MaxLonF,MaxLonF,MinLonF,MinLonF,MaxLonF/),(/MinLatF,MaxLatF,MaxLatF,MinLatF,MinLatF/),lnres)

    panres1                   = True                   ; modify the panel plot

    panres1@mpMinLatF             = res@mpMinLatF
    panres1@mpMaxLatF             = res@mpMaxLatF
    panres1@mpMinLonF             = res@mpMinLonF
    panres1@mpMaxLonF             = res@mpMaxLonF
    panres1@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2

    panres1@gsnFrame          = False                  ; don't advance frame yet
    panres1@gsnPanelLabelBar  = True                   ; add common colorbar
    panres1@gsnPanelLeft       = 1.0-0.95                   ; Make sure not too close to 
    panres1@gsnPanelRight    = 1.0-0.65                   ; edge, so it maximizes better.
    ;panres1@lbOrientation     = "vertical"
    panres1@pmLabelBarHeightF  = 0.035                 ; make thinner
    panres1@pmLabelBarWidthF = 0.25  

    MAXIMIZE_OUTPUT           = True                  ; if maximization of plots is desired.

    if(MAXIMIZE_OUTPUT) then
      panres1@gsnDraw = False                           ; draw later, in maximize mode
    ;
    ; It is necessary to return the id of the paneled plots,
    ; so they can "live" for the rest of this script, for
    ; when we maximize them later.
    ; 
      panelid1 = gsn_panel_return(wks,plot,(/1,1/),panres1) 
    else
      panres1@gsnDraw = True
      gsn_panel(wks,plot,(/1,1/),panres1)               ; now draw as one 
    end if

    res@cnMinLevelValF      =  -1 * diffRange
    res@cnMaxLevelValF      =  diffRange
    res@cnLevelSpacingF     =  diffGap
    res@cnFillPalette       = "BlueWhiteOrangeRed"    ; select a color map with white in the middle

    plot2 = new(2,graphic)    
    lnid2 = plot2

    plot2(0) = gsn_csm_contour_map(wks,diffArr(1,:,:),res)
    plot2(1) = gsn_csm_contour_map(wks,diffArr(2,:,:),res)

    lnid2(0) = gsn_add_polyline(wks,plot2(0),(/MaxLonF,MaxLonF,MinLonF,MinLonF,MaxLonF/),(/MinLatF,MaxLatF,MaxLatF,MinLatF,MinLatF/),lnres)
    lnid2(1) = gsn_add_polyline(wks,plot2(1),(/MaxLonF,MaxLonF,MinLonF,MinLonF,MaxLonF/),(/MinLatF,MaxLatF,MaxLatF,MinLatF,MinLatF/),lnres)


    panres1@gsnPanelLeft    = 1.0-0.65
    panres1@gsnPanelRight = 1.0-0.05
    panres1@pmLabelBarWidthF = 0.5 

    if(MAXIMIZE_OUTPUT) then
      panres1@gsnDraw = False                           ; draw later, in maximize mode
    ;
    ; It is necessary to return the id of the paneled plots,
    ; so they can "live" for the rest of this script, for
    ; when we maximize them later.
    ; 
      panelid2 = gsn_panel_return(wks,plot2,(/1,2/),panres1)

    ;---If maximization is desired, used this
      mres = True
      maximize_output(wks,mres)
    else
      panres1@gsnDraw = True
      gsn_panel(wks,plot2,(/2,1/),panres1)
      frame(wks)
    end if
  else

    plot = new(3,graphic)
    lnid = plot

    res@gsnLeftString=configs_pretty(1)
    plot(1) = gsn_csm_contour_map(wks,varArray(1,:,:),res)

    res@cnMinLevelValF      =  -1 * diffRange
    res@cnMaxLevelValF      =  diffRange
    res@cnLevelSpacingF     =  diffGap
    res@cnFillPalette       = "BlueWhiteOrangeRed"    ; select a color map with white in the middle

    res@gsnLeftString=configs_pretty(0)
    plot(0) = gsn_csm_contour_map(wks,diffArr(0,:,:),res)
    res@gsnLeftString=configs_pretty(2)
    plot(2) = gsn_csm_contour_map(wks,diffArr(2,:,:),res)


    lnres=True
    lnres@gsLineThicknessF = 4.0
    lnid(0) = gsn_add_polyline(wks,plot(0),(/MaxLonF,MaxLonF,MinLonF,MinLonF,MaxLonF/),(/MinLatF,MaxLatF,MaxLatF,MinLatF,MinLatF/),lnres)
    lnid(1) = gsn_add_polyline(wks,plot(1),(/MaxLonF,MaxLonF,MinLonF,MinLonF,MaxLonF/),(/MinLatF,MaxLatF,MaxLatF,MinLatF,MinLatF/),lnres)
    lnid(2) = gsn_add_polyline(wks,plot(2),(/MaxLonF,MaxLonF,MinLonF,MinLonF,MaxLonF/),(/MinLatF,MaxLatF,MaxLatF,MinLatF,MinLatF/),lnres)

    resP=True
    if (panelrow(zz) .ge. 0) then
      resP@gsnPanelFigureStringsFontHeightF = 0.016
      resP@gsnPanelFigureStrings=letters((panelrow(zz)*3):(panelrow(zz)*3)+2)
      resP@amJust           = "TopLeft"
    end if

    gsn_panel(wks,plot,(/1,3/),resP)

  end if






end do


