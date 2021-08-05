
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
;load "/glade/u/home/ckruse/git/ncl/merra.ncl"
load "/glade/u/home/ckruse/git/ncl/cesm/calcmpv.ncl"

begin

  if ((.not.isvar("season")) .or. (.not.isvar("config"))) then
    print("Either 'season' or 'config' not specified: EXIT")
    print("season = DJF, JJA")
    print("config = CAM6, UW, CAM6ck10up,CAM6sfcstsup") 
  end if

  if config.eq."CAM6" then
    run = "cam6.era5.6hrtaundgall" 
  end if
  if config.eq."UW" then
    run = "uw.era5.6hrtaundgall"
  end if
  if config.eq."CAM6ck10up" then
    run = "cam6.era5.6hrtaundgall.ck10_1.0"
  end if
  if config.eq."CAM6sfcstsup" then 
    run = "cam6.era5.6hrtaundgall.sfcstressup"
  end if

  rundir = "/glade/scratch/ckruse/archive/ndgbudget."+run+"/atm/hist/"

  if season.eq."JJA" then 
    allfiles = systemfunc("ls "+rundir+"ndgbudget*h2.20??-0[678]*.nc")
  end if
  if season.eq."DJF" then
    allfiles = systemfunc("ls "+rundir+"ndgbudget*h2.20??-12*.nc "+rundir+"ndgbudget*h2.20??-0[12]*.nc")
  end if

  files = allfiles(1:89)
  nf = dimsizes(files)

  a = addfile(files(0),"r")
  vars = getfilevarnames(a)
  varinds = ind(str_match_bool(vars,"U_").and..not.str_match_bool(vars,"Nudge"))
  varsubset = vars(varinds)
  latlonstrs = str_get_cols(varsubset,2,-1)
  nprofs = dimsizes(latlonstrs)

  delete(a)
  a = addfiles(files,"r")

  do profi=0,nprofs-1
    zname = "Z3_"+latlonstrs(profi)
    uname = "U_"+latlonstrs(profi)
    uttotname = "UTEND_TOT_"+latlonstrs(profi)
    utcorname = "UTEND_CORE_"+latlonstrs(profi)
    utphyname = "UTEND_PHYSTOT_"+latlonstrs(profi)
    utndgname = "UTEND_NDG_"+latlonstrs(profi)
    utmacname = "UTEND_MACROP_"+latlonstrs(profi)
    utvdfname = "UTEND_VDIFF_"+latlonstrs(profi)
    utshcname = "UTEND_SHCONV_"+latlonstrs(profi)
    zmname = "ZM_CLUBB_"+latlonstrs(profi)
    umname = "UM_CLUBB_"+latlonstrs(profi)
    mfxname = "UPWP_CLUBB_"+latlonstrs(profi)
    ; read in vars
    z     = rm_single_dims(a[:]->$zname$)
    u     = rm_single_dims(a[:]->$uname$)
    uttot = rm_single_dims(a[:]->$uttotname$)
    utcor = rm_single_dims(a[:]->$utcorname$)
    utndg = rm_single_dims(a[:]->$utndgname$)
    utphy = rm_single_dims(a[:]->$utphyname$) - utndg
    utmac = rm_single_dims(a[:]->$utmacname$)
    if config.eq."UW" then
      utold = rm_single_dims(a[:]->$utvdfname$+a[:]->$utshcname$)
    else
      utold = rm_single_dims(a[:]->$utvdfname$)
    end if
    ; avg vars
    zavg = dim_avg_n(z,(/0/))/1000
    zavg = zavg-zavg(31) + 0.063
    zavg@long_name = "Height AGL (km)"
    uavg = dim_avg_n(u,(/0/))
    uttotavg = dim_avg_n(uttot,(/0/))
    utcoravg = dim_avg_n(utcor,(/0/))
    utndgavg = dim_avg_n(utndg,(/0/))
    utphyavg = dim_avg_n(utphy,(/0/))
    utmacavg = dim_avg_n(utmac,(/0/))
    utoldavg = dim_avg_n(utold,(/0/))

    ;print(zavg + " " + uavg)
    ;print(latlonstrs(profi)+"")

    ; we generate plots, but what kind do we prefer?
    type = "pdf"
    type@wkPaperHeightF = 11 ; only for ps
    type@wkPaperWidthF = 11 ; only for ps
    wksname = "./plots/utendprofs_"+latlonstrs(profi)+"_"+config+"_"+season
    wks = gsn_open_wks(type,wksname)

    allut = (/utoldavg,utmacavg,utcoravg,utphyavg,utndgavg,uttotavg/)*24*3600
    allut!1 = "z"
    allut&z = zavg
    allut@long_name = "Zonal Tendency (m/s/day)"

    res = True
    res@vpHeightF = 0.30
    res@vpWidthF  = 0.2
    res@trYMinF = 0
    res@trYMaxF = 5
    if (latlonstrs(profi).eq."140w_15n").or.(latlonstrs(profi).eq."100w_15s") then
      res@trXMaxF =  17
      res@trXMinF = -17
    end if
    if (latlonstrs(profi).eq."61w_22s").or.(latlonstrs(profi).eq."97w_37n") then
      res@trXMaxF =  27
      res@trXMinF = -27
    end if
    if (latlonstrs(profi).eq."140w_55s").or.(latlonstrs(profi).eq."150w_40n").or. \
       (latlonstrs(profi).eq."10w_55s").or.(latlonstrs(profi).eq."106w_39n") then
      res@trXMaxF =  25
      res@trXMinF = -25
    end if

    res@pmLegendDisplayMode    = "Always"
    res@pmLegendSide           = "Top"
    res@pmLegendParallelPosF   = .77
    res@pmLegendOrthogonalPosF = -0.30
    res@pmLegendWidthF         = 0.04
    res@pmLegendHeightF        = 0.08
    res@lgPerimOn              = False
    res@lgLabelFontHeightF     = .01

    res@xyMarkLineMode = "MarkLines"
    res@xyLineColors = (/"brown","purple","red","green","blue","black"/)
    res@xyDashPatterns = (/0,0,0,0,0,0/)
    res@xyLineThicknesses = (/2,2,2,2,2,2/)
    res@xyMarkers = (/16,16,16,16,16,16/)
    res@xyMarkerColors = res@xyLineColors
    res@xyExplicitLegendLabels = (/"SHC+VDF","MACP","CORE","PHYS","NDG","TOT"/)
    res@tiMainString = latlonstrs(profi)+", "+config+", "+season

      res2 = res
      delete(res2@xyLineColors)
      delete(res2@xyDashPatterns)
      delete(res2@xyLineThicknesses)
      delete(res2@xyExplicitLegendLabels)
      delete(res2@xyMarkerColors)
      res2@xyLineColors = (/"black"/)
      res2@xyDashPatterns = (/2/)
      res2@xyLineThicknesses = (/2/)
      res2@xyExplicitLegendLabels = (/"U"/)
      res2@pmLegendParallelPosF   = .24
      res2@pmLegendOrthogonalPosF = -0.40
      res2@tiXAxisString = "U (m/s)"
      res2@xyMarkerColors = res2@xyLineColors

      if (latlonstrs(profi).eq."140w_15n").or.(latlonstrs(profi).eq."100w_15s") then
        res2@trXMaxF =  10
        res2@trXMinF = -10
      else
        res2@trXMaxF =  20
        res2@trXMinF = -20
      end if

    ;plot = gsn_csm_x2y(wks1,alltends(mi,:,:),alluprofs(mi,:),allz(mi,:),res,res2)
    ;plot = gsn_csm_xy(wks,allut,zavg,res)
    plot = gsn_csm_x2y(wks,allut,uavg,zavg,res,res2)
 
    print("Done with "+latlonstrs(profi)+" profiles")
  end do
end
