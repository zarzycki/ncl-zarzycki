load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "/glade/u/home/abtawfik/my_ncl_library/my_functions.ncl"



begin

    ;---- variable of interest
    variableZ   =  "PRECCDZM"
    variable    =  "PRECT"
    PTOT_LIM    =  0.5
    conversion  =  1.0 * 3600. * 1e3
    hour_2_day  =  24.0

    cmons  =  (/ "Jan", "Feb", "Mar", "Apr", "May",  "Jun",  "Jul", "Aug",  "Sep", "Oct", "Nov",  "Dec" /)
    dpmn   =  (/    31,    28,    31,    30,    31,     30,     31,    31,     30,    31,    30,    31  /)
    bday   =  (/     1,    32,    61,    92,   122,    153,    183,   214,    245,   275,   306,   336  /)
    eday   =  (/    31,    60,    91,   121,   152,    182,    213,   244,    274,   305,   335,   366  /)
    nday   =  eday - bday + 1
    nhrs   =  dpmn * 24
    nhr    =  24
    nhr8   =  8

    byr    =  1979
    eyr    =  2006
    nyr    =  eyr - byr + 1



    ;----  Africa
    ;blat   = (/  -20. /)
    ;elat   = (/   30. /)
    ;blon   = (/    0. /)
    ;elon   = (/   50. /)

    ;----  United States
    blat   = (/   35. /)
    elat   = (/   45. /)
    blon   = (/  -105./)
    elon   = (/  -90. /)
    ; blon   = (/  -105. + 360 /)
    ; elon   = (/  -90.  + 360 /)
    ; blon0  = blon - 360.
    ; elon0  = elon - 360.
    print(blon+"    "+elon)




    ;---This resource not needed in V6.1.0
    res                       =  True
    res@gsnDraw               =  False
    res@gsnFrame              =  False

    res@gsnMaximize           =  True
    res@gsnSpreadColors       =  True     ; use full range of color map
    res@cnFillOn              =  True     ; turn on color fill
    res@cnLinesOn             =  False    ; turn of contour lines
    res@cnLineLabelsOn        =  False    ; turn of contour line labels
    res@lbLabelAutoStride     =  True
    res@cnInfoLabelOn         =  False      ; turn off cn info label new
    res@lbLabelBarOn          =  False

    res@tiYAxisFont           =  "helvetica"
    res@tiXAxisFont           =  "helvetica"
    res@tmXBLabelFont         =  "helvetica"
    res@tmYLLabelFont         =  "helvetica"
    res@lbLabelFont           =  "helvetica"

    res@tmXTOn                =  False
    res@tmXBOn                =  True
    res@tmYROn                =  False
    res@tiYAxisAngleF         =  90.
    res@tiYAxisFontHeightF    =  0.017
    res@tiXAxisFontHeightF    =  0.017    
    res@tiMainFontHeightF     =  0.027
    res@tmXBLabelFontHeightF  =  0.017
    res@tmYLLabelFontHeightF  =  0.013
    res@cnLevelSelectionMode  =  "ExplicitLevels"
    res@txFont                =   "helvetica-bold"

    res@tiXAxisString         =   "~F22~Longitude"
    res@tiYAxisString         =   "~F22~"

    res@trYMinF               =  15
    res@trYMaxF               =  25

    res@vpWidthF              =  0.5
    res@vpHeightF             =  0.8

    resd                      =  res
    res1                      =  res

;   res@cnLevels              =  (/ 0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 7.0 /)  
    res@cnLevels              =  (/ 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 5.0, 8.0, 10.0, 15.0 /)
    colors                    =  tointeger(fspan(2,62,dimsizes(res@cnLevels)+1))
    res@cnFillColors          =  colors

    panelRes                                   = True
    panelRes@gsnFrame                          = False
    panelRes@gsnMaximize                       = True
    panelRes@amJust                            = "TopRight"
    panelRes@txFontColor                       = "black"
    panelRes@txFontHeightF                     = 0.007
    panelRes@gsnPanelFigureStringsPerimOn      = False
    panelRes@gsnPanelFigureStringsFontHeightF  = 0.007
    panelRes@gsnPanelFigureStringsPerimOn      = False
    panelRes@gsnPanelRowSpec                   = True
    panelRes@gsnPanelLabelBar                  = True
    panelRes@lbLabelAutoStride                 = True
    panelRes@gsnPanelFigureStrings             = "~F21~"+(/ "a","b","c","d","e","f","g" /) + ")"
    panelRes@gsnPanelCenter                    = False
    panelRes@lbLabelFont                       =  "helvetica"
    ;    panelRes@gsnPanelRight                = 0.90
    ;    panelRes@gsnPanelLeft                 = 0.10




    ;---XY curve resources
    xyres                              =   True                 ; plot mods desired
    xyres@gsnFrame                     =   False
    xyres@gsnDraw                      =   False
    xyres@tmXBLabelFontHeightF         =   0.013
    xyres@tmYLLabelFontHeightF         =   0.017
    xyres@tiYAxisFontHeightF           =   0.020
    xyres@tiXAxisFontHeightF           =   0.013
    xyres@tiMainFontHeightF            =   0.021
    xyres@tmXTOn                       =   True
    xyres@txFont                       =   "helvetica-bold"
    xyres@tmYLMajorOutwardLengthF      =   0.0               ; draw tickmarks inward
    xyres@tmYLMinorOutwardLengthF      =   0.0
    xyres@tmYLMajorOutwardLengthF      =   0.0               ; draw tickmarks inward
    xyres@tmYLMinorOutwardLengthF      =   0.0
    xyres@tmYLMode                     =   "Automatic"
    xyres@tmYLFormat                   =   "f"
    xyres@tmXBMode                     =   "Automatic"
    xyres@tmXBFormat                   =   "f"
    xyres@tmXTMode                     =   "Automatic"
    xyres@tmXTFormat                   =   "f"
    xyres@tmXUseBottom                 =   True
    xyres@tmXTMajorOutwardLengthF      =   0.0               ; draw tickmarks inward
    xyres@tmXTMinorOutwardLengthF      =   0.0
    xyres@tmXTMajorOutwardLengthF      =   0.0               ; draw tickmarks inward
    xyres@tmXTMinorOutwardLengthF      =   0.0
    xyres@xyMonoMarkLineMode           =   False
    xyres@xyMonoLineThickness          =   True
    xyres@xyLineThicknessF             =   2.5
    xyres@xyMonoMarker                 =   False
    xyres@gsnMaximize                  =   True
    xyres@xyDashPatterns               =   (/     0,     0,     0/)
    xyres@tiXAxisString                =   "~F22~Inc. Solar (W/m2)"

    xyres@xyLineColors                 =  "snow4"
    xyres@xyLineColor                  =  "snow4"

    xyres@tmXTOn                       =  False
    xyres@tmYROn                       =  False

    xyres@trYMinF                      =  15
    xyres@trYMaxF                      =  25
    xyres@trXMinF                      =  0
    xyres@trXMaxF                      =  900
    xyres@vpWidthF                     =  0.15
    xyres@vpHeightF                    =  0.8

    xyres@tmXBMode                     =  "Explicit"
    xyres@tmXBLabels                   =  (/ 50, 500, 900 /)
    xyres@tmXBValues                   =  (/ 50, 500, 900 /)

    xyres@tiYAxisFont                  =  "helvetica"
    xyres@tiXAxisFont                  =  "helvetica"
    xyres@tmXBLabelFont                =  "helvetica"
    xyres@tmYLLabelFont                =  "helvetica"



    typer0  =  "BCL_NOTILE_SE_CAM5_1.00"
    typer1  =  "hcf_only_over_OceanAndLand"
    typer2  =  "hcf_only_over_land"
    typerC  =  "MSWEP"
        
;    in_mons   =  (/5,6,7,8/)
    in_mons   =  (/6/)
    num_mons  =  dimsizes(in_mons)
    plot0     =  new( (/num_mons, 9/), graphic )
    plotX     =  new( (/num_mons, 9/), graphic )
    do mmm = 0,num_mons-1
              
       ;----- Get the month of interest
       mm   =  in_mons(mmm)
       if( mm.lt.10 ) then
           imons = "0"+mm
       else
           imons = ""+mm
       end if

       ;----- Name months and select one of interest
       print("     ------ Beginning Month        =         "+cmons(mm-1))


       CREATE_FILE    = False
       hovmuller_file = "../processed/Hovmuller_Central_Plains.June.nc"

       if( CREATE_FILE ) then


          ;------------------------------------------
          ;----- 
          ;-----      Files and Variables Read in       
          ;----- 
          ;-----    >>> BCL_NOTILE_SE_CAM5_1.00  <<<
          ;----- 
          ;------------------------------------------
          dir0   =  "/glade/p/uges0001/HCF_TRIGGER_SIMS/Control/1deg/"    
          fil0   =  systemfunc("ls "+dir0+typer0+".1deg.????-"+imons+".nc")
          f0     =  addfiles(fil0, "r")

          fil1   =  systemfunc("ls "+dir0+typer0+".clm.1deg.????-"+imons+".nc")
          f1     =  addfiles(fil1, "r")

          ntim   =  dimsizes(f0[:]->$variable$(:,0,0))
          nlat   =  dimsizes(f0[0]->lat({blat:elat}))
          lon0   =           f0[0]->lon({blon:elon})
          nlon   =  dimsizes(lon0)
          nsub   =  ntim/nyr
          print( nlat+"    "+nlon+"      "+ntim+"      "+nyr+"     "+nsub+"     "+nsub/nhr8 ) 
          RAINno =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variable$ (:,{blat:elat},{blon:elon}) * conversion, (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2/) )
          RAINnoZ=  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variableZ$(:,{blat:elat},{blon:elon}) * conversion, (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2/) )
          RAINnoL=  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variable$ (:,{blat:elat},{blon:elon}) - f0[:]->$variableZ$(:,{blat:elat},{blon:elon})    \
                                                                        , (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ) * conversion, 0 ), (/1,2/) )
          FSDSno =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f1[:]->FSDS (:,{blat:elat},{blon:elon}), (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2,3/))
          RAINno =  RAINno * hour_2_day
          RAINnoL=  RAINnoL* hour_2_day
          RAINnoZ=  RAINnoZ* hour_2_day




          ;------------------------------------------
          ;----- 
          ;-----     Files and Variables Read in       
          ;----- 
          ;-----    >>> HCF Trigger Section  <<<
          ;----- 
          ;------------------------------------------
          dir0   =  "/glade/scratch/abtawfik/"+typer1+"/1deg/"     
          fil0   =  systemfunc("ls "+dir0+typer1+".1deg.????-"+imons+".nc")
          f0     =  addfiles(fil0, "r")

          fil1   =  systemfunc("ls "+dir0+typer1+".clm.1deg.????-"+imons+".nc")
          f1     =  addfiles(fil1, "r")


          RAINye =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variable$ (:,{blat:elat},{blon:elon}) * conversion, (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2/) )
          RAINyeZ=  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variableZ$(:,{blat:elat},{blon:elon}) * conversion, (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2/) )
          RAINyeL=  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variable$ (:,{blat:elat},{blon:elon}) - f0[:]->$variableZ$(:,{blat:elat},{blon:elon})    \
                                                                        , (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ) * conversion, 0 ), (/1,2/) )
          FSDSye =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f1[:]->FSDS (:,{blat:elat},{blon:elon}), (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2,3/))

          RAINye =  RAINye * hour_2_day
          RAINyeZ=  RAINyeZ* hour_2_day
          RAINyeL=  RAINyeL* hour_2_day
  






          ;------------------------------------------
          ;----- 
          ;-----     Files and Variables Read in       
          ;----- 
          ;-----    >>> HCF Scaling Section  <<<
          ;----- 
          ;------------------------------------------
          dir0   =  "/glade/scratch/abtawfik/"+typer2+"/1deg/"     
          fil0   =  systemfunc("ls "+dir0+typer2+".1deg.????-"+imons+".nc")
          f0     =  addfiles(fil0, "r")

          fil1   =  systemfunc("ls "+dir0+typer2+".clm.1deg.????-"+imons+".nc")
          f1     =  addfiles(fil1, "r")



          RAINsu =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variable$ (:,{blat:elat},{blon:elon}) * conversion, (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2/) )
          RAINsuZ=  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variableZ$(:,{blat:elat},{blon:elon}) * conversion, (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2/) )
          RAINsuL=  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f0[:]->$variable$ (:,{blat:elat},{blon:elon}) - f0[:]->$variableZ$(:,{blat:elat},{blon:elon})    \
                                                                        , (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ) * conversion, 0 ), (/1,2/) )
          FSDSsu =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape( f1[:]->FSDS (:,{blat:elat},{blon:elon}), (/nyr,nday(mm-1)*nhr8,3,nlat,nlon/) ), 0 ), (/1,2,3/))


          RAINsu =  RAINsu * hour_2_day
          RAINsuZ=  RAINsuZ* hour_2_day
          RAINsuL=  RAINsuL* hour_2_day
  













          ;------------------------------------------
          ;----- 
          ;-----    Files and Variables Read in       
          ;----- 
          ;-----    >>>   MSWEP Sections   <<<
          ;----- 
          ;------------------------------------------
          print("    MSWEP  SECTION   ")
          dir0   =  "/glade/scratch/abtawfik/TRMM/processed/"
          filz   =  systemfunc("ls "+dir0+"TRMM.1deg.3hr.{1998..2013}"+imons+".nc")
          f1     =  addfiles(filz,"r")
          nlatob =  dimsizes(f1[0]->lat({blat:elat}))
          nlonob =  dimsizes(f1[0]->lon({blon:elon}))
          nyr_obs=  dimsizes(filz)
          print(dimsizes(f1[:]->precip))

          RAINob =  dim_avg_n_Wrap(dim_avg_n_Wrap(reshape(f1[:]->precip(:,{blat:elat},{blon:elon}), (/nyr_obs,nday(mm-1)*nhr8,nlatob,nlonob/)), 0), 1 )
          RAINob =  RAINob * hour_2_day



;          RAINye!0     =  "time"
;          RAINye!1     =  "lon"
;          RAINye&time  =  ispan(0,ntim - 1, 1) * 1.
;          RAINye&lon   =  binz
;          copy_VarCoords(RAINye, RAINno)
;          printVarSummary(RAINye)

          ntim         =  nday(mm-1)*nhr8
          RAINsu!0     =  "time"
          RAINye!0     =  "time"
          RAINno!0     =  "time"
          RAINob!0     =  "time"
          RAINsu!1     =  "lon"
          RAINye!1     =  "lon"
          RAINno!1     =  "lon"
          RAINob!1     =  "lon"
          ytime        =  fspan(0,nday(mm-1)-(1./(nhr8*1.)),ntim)

          RAINsu&time  =  ytime
          RAINye&time  =  ytime
          RAINno&time  =  ytime
          RAINob&time  =  ytime
          RAINsu&lon   =  lon0
          RAINye&lon   =  lon0
          RAINno&lon   =  lon0
          RAINob&lon   =  lon0
          delete( [/RAINob@units, RAINob@long_name, RAINob@standard_name, RAINsu@standard_name/] )

          copy_VarCoords( RAINno, RAINsuZ )
          copy_VarCoords( RAINno, RAINsuL )
          copy_VarCoords( RAINno, RAINnoZ )
          copy_VarCoords( RAINno, RAINyeZ )
          copy_VarCoords( RAINno, RAINnoL )
          copy_VarCoords( RAINno, RAINyeL )


          ;------------------------------------------
          ;-----
          ;-----   >>>   Create Output File   <<<
          ;-----
          ;------------------------------------------
          if( isfilepresent(hovmuller_file) ) then
              system("rm "+hovmuller_file)
          end if
          ncout  =  addfile( hovmuller_file, "c" )

          ncout->RAINno   =   RAINno
          ncout->RAINye   =   RAINye
          ncout->RAINsu   =   RAINsu

          ncout->RAINnoL  =   RAINnoL
          ncout->RAINyeL  =   RAINyeL
          ncout->RAINsuL  =   RAINsuL

          ncout->RAINnoZ  =   RAINnoZ
          ncout->RAINyeZ  =   RAINyeZ
          ncout->RAINsuZ  =   RAINsuZ

          ncout->FSDSno   =   FSDSno
          ncout->FSDSye   =   FSDSye
          ncout->FSDSsu   =   FSDSsu

          ncout->RAINob   =   RAINob




       else


          ;------------------------------------------
          ;-----
          ;-----   >>>  Output File   <<<
          ;-----
          ;------------------------------------------
          ncout   =   addfile( hovmuller_file, "r" )

          RAINno  =   ncout->RAINno 
          RAINye  =   ncout->RAINye 
          RAINsu  =   ncout->RAINsu 
                                   
          RAINnoL =   ncout->RAINnoL 
          RAINyeL =   ncout->RAINyeL
          RAINsuL =   ncout->RAINsuL 
                                   
          RAINnoZ =   ncout->RAINnoZ 
          RAINyeZ =   ncout->RAINyeZ 
          RAINsuZ =   ncout->RAINsuZ 
                                   
          FSDSno  =   ncout->FSDSno  
          FSDSye  =   ncout->FSDSye  
          FSDSsu  =   ncout->FSDSsu  
                                   
          RAINob  =   ncout->RAINob  

       end if

 

       ntim        =   nday(mm-1)*nhr8
       ytime       =   RAINob&time



       ;--------------------------------------------------
       ;--------------------------------------------------
       ;------
       ;------   Plotting script
       ;------
       ;--------------------------------------------------
       ;--------------------------------------------------

       ytime@calendar      =     "standard"
       ytime@units         =     "days since 1999-"+imons+"-01 00:00:0.0"
       utc                 =     cd_calendar(ytime, 0)
       month               =     utc(:,1)
       day                 =     utc(:,2)
       hour                =     utc(:,3)
       res@tmYLMode        =     "Explicit"
       res@tmYLLabels      =     "~F21~"+month(::nhr8)+"/"+day(::nhr8)
       res@tmYLValues      =     ytime(::nhr8)

       res@tmXBMode        =     "Explicit"
       res@tmXBLabels      =     "~F21~"+(/ 105, 100, 95 /)+"W"
       res@tmXBValues      =     (/ -105, -100, -95 /)

       timeer              =     hour(::4)+":00"
       timeer1             =     day (::4)+" "+hour(::4)+":00"
       timeer(::2)         =     timeer1(::2)
       ; res@tmYLLabels      =     timeer
       ; res@tmYLValues      =     ytime(::4)



       ;******
       ;******
       ;******   Control Experiment
       ;******
       ;******
       ;******
       ;----- Open workspace
       wks    =  gsn_open_wks("pdf" ,"FIGURE_9")
       gsn_merge_colormaps(wks,"temp1","cmp_b2r")      ; choose colormap

print(ytime+"      ")
print(dimsizes(ytime))
print(" ")
print(" ")
print(" ")
print("  FFFFFFFFFFF   "+FSDSno)
print(" "+dimsizes(FSDSno))

       res@tmYLOn         =   True
       res@tiMainString   =   "~F22~Control"
       plot0(mmm,0)       =   gsn_csm_hov(wks, RAINno, res)
       plotX(mmm,0)       =   gsn_csm_xy (wks, FSDSno, ytime, xyres )

       res@tiMainString   =   "~F22~HCF Trigger"
       plot0(mmm,1)       =   gsn_csm_hov(wks, RAINye, res)
       plotX(mmm,1)       =   gsn_csm_xy (wks, FSDSye, ytime, xyres )

       res@tiMainString   =   "~F22~HCF Land"
       plot0(mmm,2)       =   gsn_csm_hov(wks, RAINsu, res)
       plotX(mmm,2)       =   gsn_csm_xy (wks, FSDSsu, ytime, xyres )

       res@tiMainString   =   "~F22~TRMM"
       plot0(mmm,3)       =   gsn_csm_hov(wks, RAINob, res)
       plotX(mmm,3)       =   gsn_csm_xy (wks, FSDSye, ytime, xyres )

       attachres1                      =  True
       attachres1@gsnAttachPlotsXAxis  =  False ; attaches along x-axis
       attachres2                      = True
       attachid1  = gsn_attach_plots(plot0(mmm,0),plotX(mmm,0),attachres1,attachres2)
       attachid2  = gsn_attach_plots(plot0(mmm,1),plotX(mmm,1),attachres1,attachres2)
       attachid3  = gsn_attach_plots(plot0(mmm,2),plotX(mmm,2),attachres1,attachres2)
       attachid3  = gsn_attach_plots(plot0(mmm,3),plotX(mmm,3),attachres1,attachres2)

       gsn_panel(wks,plot0(mmm,0:3), (/2,2/), panelRes)
       frame (wks)
       delete(wks)


      wks    =  gsn_open_wks("pdf" ,"FIGURE_10")
      gsn_merge_colormaps(wks,"temp1","cmp_b2r")      ; choose colormap

      res@tiMainString   =   "~F22~Control"
      plot0(mmm,3)       =   gsn_csm_hov(wks, RAINnoL, res)

      res@tiMainString   =   "~F22~HCF Trigger"
      plot0(mmm,4)       =   gsn_csm_hov(wks, RAINyeL, res)

      res@tiMainString   =   "~F22~HCF Land"
      plot0(mmm,5)       =   gsn_csm_hov(wks, RAINsuL, res)

      res@tiMainString   =   " "
      plot0(mmm,6)       =   gsn_csm_hov(wks, RAINnoZ, res)
      plot0(mmm,7)       =   gsn_csm_hov(wks, RAINyeZ, res)
      plot0(mmm,8)       =   gsn_csm_hov(wks, RAINsuZ, res)

      gsn_panel(wks,plot0(mmm,3:8), (/3,3/), panelRes)
      frame (wks)
      delete(wks)


       delete( [/timeer, timeer1, hour/] )
       delete(RAINye ) 
       delete(RAINno )
       delete(RAINyeL) 
       delete(RAINnoL)
       delete(RAINyeZ) 
       delete(RAINnoZ)
       delete(RAINob )
       delete(ytime  )
       delete(utc    )
       delete( [/month,day/] )
       delete( [/res@tmYLLabels , res@tmYLValues/] )

   end do

;   txres               =  True      
;   txres@txFontHeightF =  0.010

   ;  panelRes@txString  =  "Month: "+cmons(mm-1)+" Frequency of Convective Precip"
;   gsn_panel(wks,ndtooned(plot0), (/3,3/), panelRes)
;   gsn_text_ndc( wks, "~F22~"+cmons(in_mons(0)-1), 0.078, 0.610, txres )
;   gsn_text_ndc( wks, "~F22~"+cmons(in_mons(1)-1), 0.078, 0.410, txres )
;   frame (wks)


end


