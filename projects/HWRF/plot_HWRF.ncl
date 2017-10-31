load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin

inFileName = "/glade/u/home/zarzycki/scratch/HWRF_v3.5a/results/01I/2008090612/wrfprd/cat.nc"
inFile = addfile(inFileName,"r")

dirnm = "/glade/u/home/zarzycki/scratch/HWRF_v3.5a/results/01I/2008090612/wrfprd/"
  allfiles = systemfunc(" ls -1 "+dirnm+"/wrfout_d03*")
 ; print(allfiles)

; set some resources used for all plots/times

  res = True
  res@gsnMaximize     = True
  res@gsnSpreadColors = True                 ; use full range of color map
  res@gsnAddCyclic    = False
  res@mpOutlineOn = False
  res@cnFillOn        = True                 ; turn on color fill
  res@cnLinesOn       = False                ; turn off contour lines
  res@cnLineLabelsOn  = False                ; turn off contour line labels
  res@cnLevelSelectionMode = "ManualLevels"  ; set explicit contour levels
  res@pmLabelBarWidthF   = 0.65
  res@pmLabelBarHeightF   = 0.1
  res@lbLabelFontHeightF   = 0.015

  res@tfDoNDCOverlay = True
  res@mpProjection = "CylindricalEquidistant"
  res@mpLimitMode = "Corners"
  res@mpDataBaseVersion = "MediumRes"

;---------------------------------------------- begin time loop

  do nt = 0,80
  
; open a workstation for each field

    wks1 = gsn_open_wks("png","pdfs/wspd10m_onmap_hr"+(nt+10))
    gsn_define_colormap(wks1,"BlueYellowRed")

    wks2 = gsn_open_wks("png","pdfs/slp_onmap_hr"+(nt+10))
    gsn_define_colormap(wks2,"BkBlAqGrYeOrReViWh200")

    wks3 = gsn_open_wks("png","pdfs/acprec_onmap_hr"+(nt+10))
    gsn_define_colormap(wks3,"weathertap_radar")

; read in model output file

    print("nt = "+nt+"   reading file "+allfiles(nt))
    fil = addfile(allfiles(nt)+".nc","r")

    u10 = fil->U10(0,:,:)
    v10 = fil->V10(0,:,:)
    pcp = fil->PREC(0,:,:)
    slp = fil->MSLP(0,:,:)
    slp = slp *0.01     ; convert to hPa (mb)
    slp@units = "hPa"
    lat2d = fil->HLAT(0,:,:)
    lon2d = fil->HLON(0,:,:)
    vlat2d = fil->VLAT(0,:,:)
    vlon2d = fil->VLON(0,:,:)

; mapping info

    lat2d@units = "degree_north"
    lon2d@units = "degree_east"
    nlat = dimsizes(lat2d(:,0))
    nlon = dimsizes(lon2d(0,:))
    print("nlat = "+nlat+"   nlon = "+nlon)

    vlat2d@units = "degree_north"
    vlon2d@units = "degree_east"

    res@mpCenterLonF = fil@CEN_LON
    res@mpCenterLatF = fil@CEN_LAT
    res@mpLeftCornerLatF = lat2d(0,0)
    res@mpLeftCornerLonF = lon2d(0,0)
    res@mpRightCornerLatF = lat2d(nlat-1,nlon-1)
    res@mpRightCornerLonF = lon2d(nlat-1,nlon-1)

; compute windspeed, attach map info

    wspd = u10                ; create the array with u's metadata
    wspd = sqrt(u10*u10 + v10*v10)
    wspd@lat2d = vlat2d
    wspd@lon2d = vlon2d
    wspd@description = "10m Windspeed"
    
; compute precip

; Convert precipitation to dBZ
    temp = pcp*1000*2*8 ; mult by 1000 to go from m to mm, mult by 2 since phys dt is 30 min (precip per phys dt)
    temp@units = "mm/hr"
    temp@long_name = "Total Precip. Rate"
    dbz = rainratetodbz(temp,0)

; set resources for windspeed, then plot

    resV = res
    resV@cnMinLevelValF  = 0.
    resV@cnMaxLevelValF  = 70.
    resV@cnLevelSpacingF = 5.
    resV@lbLabelStride   = 1
    resV@gsnCenterString  = "   fhr="+nt

    plot = gsn_csm_contour_map_ce(wks1,wspd,resV)

; set resources for SLP, then plot

    slp@lat2d = lat2d
    slp@lon2d = lon2d

    resSLP = res
    resSLP@cnMinLevelValF  = 940.
    resSLP@cnMaxLevelValF  = 1004.
    resSLP@cnLevelSpacingF = 4.
    resSLP@lbLabelStride   = 4
    resSLP@gsnLeftString   = ""
    resSLP@gsnCenterString  = "MSLP      fhr="+nt

    plot = gsn_csm_contour_map_ce(wks2,slp,resSLP)

; set resources for ACPREC, then plot

    resPCP = res
    resPCP@gsnRightString = "dBZ"
    resPCP@gsnSpreadColors      = True              ; use full colormap
    resPCP@cnLevelSelectionMode = "ExplicitLevels"                      ; set explicit contour levels
    resPCP@cnLevels    = (/0,5,10,15,20,25,30,35,40,45,50,55,60,65,70/) ; set levels
    resPCP@lbLabelStride = 2
    ;resPCP@cnMinLevelValF  = 0.
    ;resPCP@cnMaxLevelValF  = 60.
    ;resPCP@cnLevelSpacingF = 5.
    ;resPCP@lbLabelStride   = 4
    resPCP@gsnLeftString   = ""
    resPCP@gsnCenterString  = "Simulated Reflectivity (dBZ)  fhr="+nt*3

    plot = gsn_csm_contour_map_ce(wks3,dbz,resPCP)

    delete(wks1)
    delete(wks2)
    delete(wks3)

  end do

end