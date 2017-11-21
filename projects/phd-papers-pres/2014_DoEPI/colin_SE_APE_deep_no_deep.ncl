;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
; ================================================;
begin

  if (isvar("pfmt")) then            ; plot format specified on command line?
      pltType = pfmt                 ; command line
  else
      pltType = "pdf"                ; default, others: X11, pdf
  end if

;=================================================;
; open file and read in data
;=================================================;

; File Paths and names ---------------------------------------------------
  file1 = (/"/glade/scratch/dtatch/aqua_se_ne30np4L30/aqua_se_ne30np4L30.cam.h0.0000-09-01-00000.nc",\
            "/glade/scratch/dtatch/aqua_se_ne30np4L30_noDeep/aqua_se_ne30np4L30_noDeep.cam.h0.0000-09-01-00000.nc",\
;            "/glade/scratch/dtatch/moistHS_se_ne30np4_bm/moistHS_se_ne30np4_bm.cam.h0.0000-09-01-00000.nc",\
;            "/glade/scratch/cjablono/se_ne30L30_moistHS/BM_8h/se_ne30L30_moistHS.cam.h0.0000-09-01-00000.nc",\
            "/glade/scratch/cjablono/se_ne30L30_moistHS/BM_12h/se_ne30L30_moistHS.cam.h0.0000-09-01-00000.nc",\
;            "/glade/scratch/cjablono/se_ne30L30_moistHS/BM_16h/se_ne30L30_moistHS.cam.h0.0000-09-01-00000.nc",\
            "/glade/scratch/dtatch/moistHS_se_ne30np4/moistHS_se_ne30np4.cam.h0.0000-09-01-00000.nc"/)

; Input settings from shell script -----------------------------
  start_month = 7
  end_month = (/42,36,15,42/)

  cases= (/"SE Aqua-planet, ZM / UW",\
           "SE Aqua-planet, no ZM deep / UW",\
           "SE Moist idealized, with BM convection",\
           "SE Moist idealized, no convection"/)
            
  letter = (/"a","b","c","d","e","f","g","h","i",\
             "j","k","l","m","n","o","p","q","r",\
             "s","t","u","v","w","x","y","z","aa",\
             "bb","cc","dd","ee","ff","gg","hh","ii","jj","kk"/)

; Options ------------------------------------------------------
  variables = (/"OMEGA"/)

  scale     = (/ 1./)

  units     = (/"Pa/s"/)

  cn_min    = (/-0.22/)

  cn_max    = (/ 0.02/)

  cn_space =  (/  0.02/)

  cn_lines = (/ "False"/)

  var_num = dimsizes(variables)

; Case specific settings ----------------------------------------
  nfiles = dimsizes(cases)             ; number of files
;  panelSize = (/2,3/)    ; panel dimensions
  panelSize = (/1,3/)    ; panel dimensions

  color = "WhBlGrYeRe"
  wks  = gsn_open_wks(pltType,"colin_SE_APE_deep_no_deep")
;=================================================================
; Loop over all files --------------------------------------
;=================================================================
 do i = 0,var_num-1       ; variable loop

  print("Variable "+variables(i))
;  panels = new(6,graphic)   ; allocate array for panel plot
  panels = new(3,graphic)   ; allocate array for panel plot
  gsn_define_colormap(wks,color)

  prect = new((/4,257/), float)
  nplot = 0
;  do file_step = 0, nfiles-1
  do file_step = 0, 1

;   Input Files --------------------------------------------
    print(file1(file_step))
    f1 = addfile(file1(file_step),"r")

    lat = f1->lat
    if (isfilevar(f1,"gw")) then
      gw  = f1->gw
    else
      gw = new((/dimsizes(lat)/),double)
      gw = cos(lat)
    end if
    lev = f1->lev
    hya = f1->hyai
    hyb = f1->hybi
    p0  = f1->P0
    ps  = f1->PS(start_month:end_month(file_step),:,:)
    dp  = dpres_hybrid_ccm(ps,p0,hya,hyb)

    res = True
    res@tmXBMode             = "Explicit"
    res@tmXBValues           = (/-90,-60,-30,0,30,60,90/)
    res@tmXBLabels           = (/" ","60S","30S","EQ","30N","60N"," "/)

    res@cnFillOn             = True
    res@trYReverse           = True
    res@gsnLeftString        = "~F33~w "
    res@gsnRightString       = " "
    res@tiYAxisString        = "Pressure (hPa)"
    res@tmYLLabelsOn         = True
 ;   res@tiMainString         = cases(file_step)
    res@gsnContourZeroLineThicknessF = 2
    res@gsnContourNegLineDashPattern = 1

    res@cnLineLabelsOn       = False
    res@cnInfoLabelOn        = False
    res@lbLabelBarOn         = False
    res@cnLinesOn            = cn_lines(i)

    res@gsnYAxisIrregular2Linear = True
    res@vpWidthF             = 0.24
    res@vpHeightF            = 0.12
    res@gsnDraw              = False
    res@gsnFrame             = False

    prec_total = f1->PRECT(start_month:end_month(file_step),:,:)
    prec_total = prec_total *  8.64e7
    printVarSummary (prec_total)
    prect_tm = dim_avg_n_Wrap(prec_total,0)
    prect(file_step,:) = dim_avg_Wrap(prect_tm)
    prect@long_name = "Total precipitation rate"

    if (i.le.5 .or. i.ge. 15) then
      if (variables(i).eq."VD01") then
        if (isfilevar(f1,"VD01")) then
          var_in  = f1->$variables(i)$(start_month:end_month(file_step),:,:,:)
        else
          var_in  = f1->DQV(start_month:end_month(file_step),:,:,:)
        end if
      else
          var_in  = f1->$variables(i)$(start_month:end_month(file_step),:,:,:)
      end if
      if (variables(i).eq."RELHUM" .and. max(var_in).lt.1.1) then
        var_in = var_in * 100.
      end if
    end if 

;   scale
    var_in              = var_in*scale(i)

;   Compute averages -------------------------------------
    if (variables(i).ne."KVH" .and. variables(i).ne."KVM") then
      glob                = wgt_volave_ccm(var_in,dp,gw,1.0,0) ; global mean
      glob_time_ave       = dim_avg_n_Wrap(glob,0)
    else
      glob                = 0.
      glob_time_ave       = 0. ; no mean computed
    end if

;   Compute zonal mean -------------------------------------
    var_avg             = dim_avg_n_Wrap(var_in,0)
    var_zonal           = dim_avg_Wrap(var_avg)
    var_zonal@long_name = variables(i)
    var_zonal@units     = units(i)
 
    printMinMax (var_zonal,True)

    res@gsnCenterString = cases(file_step)
    res@gsnRightString = "Pa/s"

    if (variables(i) .eq. "Q") then
      res@cnLevelSelectionMode = "ExplicitLevels" 
      res@cnLevels = (/0.2,0.4,0.6,0.8,1.,2.,4.,6.,8.,10.,12.,14.,16.,18.,20./)
    else if (variables(i) .eq. "KVH") then
      res@cnLevelSelectionMode = "ExplicitLevels"
      res@cnLevels = (/1.,2.,3.,4.,6.,10., 50., 100., 150., 200./)
    else
      res@cnLevelSelectionMode = "ManualLevels"
      res@cnMinLevelValF       = cn_min(i)
      res@cnMaxLevelValF       = cn_max(i)
      res@cnLevelSpacingF      = cn_space(i)
    end if
    end if

    if (variables(i) .eq. "OMEGA" .or. variables(i).eq."OMEGAQ") then
      res@trXMinF = -30
      res@trXMaxF = 30
      res@tmXBMode = "Explicit"
      res@tmXBValues = (/-30,-20,-10,0,10,20,30/)
      res@tmXBLabels = (/" ","20S","10S","EQ","10N","20N"," "/)
    end if

    resxy = True
    resxy@xyLineThicknesses = (/2.0,2.0/)               ; 
    resxy@xyLineColors      = (/"red","black"/)          ; change line color
    resxy@vpWidthF             = 0.24
    resxy@vpHeightF            = 0.12
    resxy@gsnDraw              = False
    resxy@gsnFrame             = False
    resxy@trYMaxF              = 30.
    resxy@gsnRightString       = "mm/day"
    resxy@pmLegendDisplayMode    = "Always"            ; turn on legend
    resxy@pmLegendSide           = "Top"               ; Change location of 
    resxy@pmLegendParallelPosF   = .25                ; move units right
    resxy@pmLegendOrthogonalPosF = -0.4                ; move units down
    resxy@pmLegendWidthF         = 0.05                ; Change width and
    resxy@pmLegendHeightF        = 0.03                ; height of legend.
    resxy@lgPerimOn              = False               ; turn off box around
    resxy@lgLabelFontHeightF     = .007                 ; label font height
    resxy@xyExplicitLegendLabels = (/"with ZM deep conv.","no ZM deep conv."/)         ; create explicit labels

    res_text                    = True                  ; text mods desired
    res_text@txFontHeightF      = 0.015                 ; change text size
    res_text@txJust             = "CenterLeft"          ; text justification

    res_lines                   = True                  ; polyline mods desired
    res_lines@gsLineDashPattern = 0.                    ; solid line
    res_lines@gsLineThicknessF  = 2.                    ; line thicker
  
;   PLOTS ------------------------------

    if (nplot.eq.1) then
      panels(nplot) = gsn_csm_contour(wks,var_zonal,res) 
      nplot = nplot + 1
      resxy@gsnCenterString = "SE Aqua-planet"
      panels(nplot) = gsn_csm_xy (wks,lat,prect(0:1,:),resxy)
    else if (nplot.eq.4) then
      panels(nplot) = gsn_csm_contour(wks,var_zonal,res) 
      nplot = nplot + 1
      resxy@gsnCenterString = "SE Moist idealized"
    resxy@pmLegendParallelPosF   = .43                ; move units right
    resxy@xyExplicitLegendLabels = (/" with Betts-Miller-type (BM) convection"," no convection"/)         ; create explicit labels
      panels(nplot) = gsn_csm_xy (wks,lat,prect(2:3,:),resxy)
    else 
      panels(nplot) = gsn_csm_contour(wks,var_zonal,res) 
      print (nplot)
    end if
    end if
    nplot =nplot + 1

    delete([/prec_total,var_in,var_avg,var_zonal,glob_time_ave,ps,dp,glob,res,lat,gw,f1,hya,hyb,lev/])

  end do     ; variables loop

  resP = True
 ; resP@txString                   = letter(i)+") "+variables(i)+" ("+units(i)+")"
  resP@gsnPanelYWhiteSpacePercent = 4
  resP@gsnPanelXWhiteSpacePercent = 3
  resP@gsnPaperOrientation = "portrait"
  resP@gsnMaximize                = True
  resP@lbLabelFontHeightF         = 0.012
  resP@pmLabelBarWidthF           = 0.8
  ;resP@lbTitleString             = units(i)
  resP@lbTitlePosition            = "Right"
  resP@lbTitleFontHeightF         = 0.012
  resP@lbTitleDirection           = "Across"
  ;resP@pmLabelBarParallelPosF    = 0.08
  resP@gsnPanelFigureStringsFontHeightF = 0.014
  resP@gsnPanelFigureStrings= (/"a)","b)","c)","d)","e)","f)","g)","h)"/) ; add strings to panel
  resP@amJust           = "TopRight"
  resP@gsnPanelLabelBar           = True

  gsn_panel(wks,panels,panelSize,resP)

  delete([/panels/])

end do

end

