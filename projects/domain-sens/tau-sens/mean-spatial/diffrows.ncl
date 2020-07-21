configs=(/"dtime1800","dtime900","tau3600"/)
nconfig=dimsizes(configs)

plotMinLatF             = 2.
plotMaxLatF             = 35.
plotMinLonF             = -100.
plotMaxLonF             = -12.

; for averaging, not plotting
;MinLatF             = 5.
;MaxLatF             = 35.
;MinLonF             = -90.
;MaxLonF             = -15.
MinLatF=5.
MaxLatF=30.
MinLonF=-65.
MaxLonF=-15.

rad = 4.0*atan(1.0)/180.0
varlist=(/"PRECT","PRECC","PRECL","SHFLX","LHFLX","TMQ","GPI","Chi_m","vort_r","MPI","shear"/)
nvars = dimsizes(varlist)


do zz = 0,nvars-1
  thisvar = varlist(zz) 

  do ii = 0,nconfig-1

    if (thisvar .eq. "PRECL" .or. thisvar .eq. "PRECC" .or. thisvar .eq. "PRECT" .or. thisvar .eq. "SHFLX" .or. thisvar .eq. "TMQ" .or. thisvar .eq. "LHFLX") then
      fdir1:="/glade/scratch/zarzycki/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+configs(ii)+"/atm/hist/"
      fnampattern:="*cam.h0.19??-[0-1][890]*.nc"
      wgt_file:="/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_1.0x1.0_GLOB.nc"

      filelist := systemfunc ("find "+fdir1+" -name '"+fnampattern+"' | grep -v 1984- | grep -v 1994- | grep -v regrid.nc | sort -n")

      f := addfiles(filelist,"r")
      dsizes := getfiledimsizes(f[0])

      if (thisvar .eq. "PRECT") then
        tmp1:=f[:]->PRECC
        tmp2:=f[:]->PRECL
        PRECC=tmp1
        PRECC=tmp1+tmp2
      else
        PRECC=f[:]->$thisvar$
      end if

      if (thisvar .eq. "PRECL" .or. thisvar .eq. "PRECC" .or. thisvar .eq. "PRECT") then
        PRECC=PRECC*8.64e7
      end if



      Opt         = True
      PRECC_rll = ESMF_regrid_with_weights(PRECC,wgt_file,Opt)

      PRECC_avg=dim_avg_n_Wrap(PRECC_rll(:,{plotMinLatF:plotMaxLatF},{plotMinLonF:plotMaxLonF}),0)
      PRECC_avg_sub = PRECC_avg({MinLatF:MaxLatF},{MinLonF:MaxLonF})

      delete(PRECC)
      delete(PRECC_rll)
      delete(Opt)
    else
      f := addfile("../MPI_GPI/GPI_"+configs(ii)+".nc_AVG.nc","r")
      PRECC_avg = f->$thisvar$
      if (thisvar .eq. "GPI") then
        PRECC_avg = PRECC_avg*4.4e16
      end if
      if (thisvar .eq. "vort_r" ) then
        PRECC_avg=PRECC_avg*10^5
      end if
      PRECC_avg_sub = PRECC_avg(0,{MinLatF:MaxLatF},{MinLonF:MaxLonF})
    end if


    PRECC_amean := wgt_areaave_Wrap(PRECC_avg_sub, cos(rad*PRECC_avg_sub&lat), 1.0, 0)
    print(thisvar+" "+configs(ii)+" "+PRECC_amean)

    only_plot_avg=False
    if (only_plot_avg) then
      PRECC_avg := PRECC_avg_sub
    end if

    if (ii .eq. 0) then
      nlat:=dimsizes(PRECC_avg&lat)
      nlon:=dimsizes(PRECC_avg&lon)
      varArray:=new((/nconfig,nlat,nlon/),typeof(PRECC_avg))
    end if

    varArray(ii,:,:) = PRECC_avg

    delete(PRECC_avg_sub)
    delete(PRECC_avg)
  end do

  diffArr:=varArray
  do ii = 0,nconfig-1
    diffArr(ii,:,:)=varArray(ii,:,:)-varArray(0,:,:)
  end do




;**************************************************
; plot
;**************************************************
wks  = gsn_open_wks("png","test_"+thisvar)         ; send graphics to PNG file

res                     = True
res@gsnDraw             = False
res@gsnFrame            = False
res@mpFillOn            = False            ; no need   
res@cnLevelSelectionMode= "ManualLevels"   ; manual set levels
if (thisvar .eq. "MPI")
  res@cnMinLevelValF      = 20.0
  res@cnMaxLevelValF      = 90.0
  res@cnLevelSpacingF     = 5.0
  diffRange = 30.0
  diffGap = 3.0
else if (thisvar .eq. "shear")
  res@cnMinLevelValF      = 0.0
  res@cnMaxLevelValF      = 10.0
  res@cnLevelSpacingF     = 1.0
  diffRange = 3.0
  diffGap = 0.3
else if (thisvar .eq. "Chi_m")
  res@cnMinLevelValF      = 0.0
  res@cnMaxLevelValF      = 1.0
  res@cnLevelSpacingF     = 0.1
  diffRange = 0.3
  diffGap = 0.03
else if (thisvar .eq. "TMQ")
  res@cnMinLevelValF      = 20.0
  res@cnMaxLevelValF      = 60.0
  res@cnLevelSpacingF     = 4.0
  diffRange = 8.
  diffGap = 1.0
else if (thisvar .eq. "GPI")
  res@cnMinLevelValF      = 0.0
  res@cnMaxLevelValF      = 80.0
  res@cnLevelSpacingF     = 8.0
  diffRange = 15.
  diffGap = 1.5
else if (thisvar .eq. "vort_r")
  res@cnMinLevelValF      = -1.0
  res@cnMaxLevelValF      =  1.0
  res@cnLevelSpacingF     = 0.1
  diffRange = 0.5
  diffGap = 0.05
else
  res@cnMinLevelValF      = 1.0
  res@cnMaxLevelValF      = 15.0
  res@cnLevelSpacingF     = 1.0
  diffRange = 5.0
  diffGap = 0.5
end if    
end if
end if
end if
end if
end if

res@cnFillOn            = True             ; color fill plot
res@cnFillPalette       = "WhiteBlueGreenYellowRed"
res@cnLinesOn           = False
res@cnLineLabelsOn      = False
res@cnInfoLabelOn       = False
res@lbLabelBarOn        = False            ; turn off individual label bars



res@mpMinLatF             = plotMinLatF
res@mpMaxLatF             = plotMaxLatF
res@mpMinLonF             = plotMinLonF
res@mpMaxLonF             = plotMaxLonF
res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2
res@gsnAddCyclic = False

res@gsnLeftString=""
res@gsnRightString=""

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

res@gsnCenterString     = ""

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


netcdf_name="simple.nc"
if (zz .eq. 0) then
  system("/bin/rm -f "+netcdf_name)   ; remove any pre-existing file
  ncdf = addfile(netcdf_name ,"c")  ; open output netCDF file

  fAtt               = True            ; assign file attributes
  fAtt@creation_date = systemfunc ("date")
  fileattdef( ncdf, fAtt )            ; copy file attributes
else
  ncdf = addfile(netcdf_name,"w")
end if

varArray!0="config"
ncdf->$thisvar$  = varArray(:,{plotMinLatF:plotMaxLatF},{plotMinLonF:plotMaxLonF})

end do


