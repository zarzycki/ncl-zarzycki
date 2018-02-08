load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;; USER SETTINGS
do_plot = False           ; Do we want a 3 panel plot?
deleteGFSfiles = False     ; do we want to delete GFS files?
do_cam = True
do_comparison = True
use_Z500 = False

;;; COMMENT THESE WHEN RUNNING BATCH
;azvar="Z500"
;fcst_config = "hindcast_conus_15_x16_CAM5_L30"
;region="conus"   ; region = conus or nhemi
;hourForecast=120         ; What forecast do we want to analyze
;YYYYMMDDHH=2017120100

stats_string=fcst_config+"_"+region+"_"+azvar+"_"+sprinti("%0.10i",YYYYMMDDHH)+"_"+sprinti("%0.4i",hourForecast)

;;; check for dycore
strs = str_split(fcst_config, "_")
modres = strs(1)
if (str_get_cols(modres,0,1) .eq. "mp") then
  print("using MPAS...")
  mpas=True
else
  print("using SE...")
  mpas=False
end if

;;; RANGE FOR ANOMALY CALCULATION

if (region .eq. "nhemi")
  minLat = 20
  maxLat = 80
  minLon = 0
  maxLon = 360
else if (region .eq. "conus")
  minLat = 21
  maxLat = 53
  minLon = 231
  maxLon = 295
else
  print("invalid region")
  exit()
end if
end if

if (azvar .eq. "TS") then
  print("cannot parse, not an interpolatable value")
  varname=azvar
else
  varname=str_get_cols(azvar,0,0)
  varlev=tofloat(str_get_cols(azvar,1,3))
  print(varname+" "+varlev)
  climo_varname=azvar
end if

; ===== Getting date from YYYYMMDDHH
dtime_map = (/4,2,2,2/)
splitDate = str_split_by_length(tostring(YYYYMMDDHH),dtime_map)
yyyy=toint(splitDate(0))
mm=toint(splitDate(1))
dd=toint(splitDate(2))
hh=toint(splitDate(3))

print("Forecast initialized at: "+hh+"Z on "+mm+"/"+dd+"/"+yyyy)

; We now have to figure out the date for the verification
convertUnits = "hours ref 1-1-1 00:00:0.0"
todayHour = cd_inv_calendar(toint(yyyy),toint(mm),toint(dd),toint(hh),0,0,convertUnits,0)
forecastHour = todayHour ;to keep metadata
forecastHour = todayHour + hourForecast ; to advance forecast
forecastDay = cd_calendar(forecastHour,0)

f_yyyy = toint(forecastDay(0,0))
f_mm = toint(forecastDay(0,1))
f_dd = toint(forecastDay(0,2))
f_hh = toint(forecastDay(0,3))
f_hh_to_sec = toint(f_hh * 3600)

print("Forecast at "+hourForecast+" HOURS: verification at: "+f_hh+"Z on "+f_mm+"/"+f_dd+"/"+f_yyyy)

;;;; FILES

THISDIR=systemfunc("pwd") 
WORKDIR="/glade/scratch/zarzycki/CFSRskill/"

climo_netcdf = "/glade/u/home/zarzycki/sewx-cam-forecast/plotting_ncl/climo-files/"+climo_varname+"-1980-2009-NCEP.nc"

;;;; ===== GET CAM FORECAST FILE
if (do_cam) then
;  forecast_netcdf = "/glade/scratch/zarzycki/forecast_conus_30_x8_CAM5/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/_forecast_conus_30_x8_CAM5.cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
;  forecast_netcdf = "/glade/scratch/zarzycki/hindcast_conus_30_x8_CAM5_L30/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/hindcast_conus_30_x8_CAM5_L30.cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
;  forecast_netcdf = "/glade/scratch/zarzycki/hindcast_conus_30_x8_CAM4_L26/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/hindcast_conus_30_x8_CAM4_L26.cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
  forecast_netcdf = "/glade/scratch/zarzycki/"+fcst_config+"/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/"+fcst_config+".cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
  print("CAM FORECAST FILE: "+forecast_netcdf)
  forecastFile = addfile(forecast_netcdf,"r")
  if (mpas) then
    wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.25x0.25glob_patch.nc"
  else
    if (.not.ismissing(str_match(fcst_config, "conus_30_x8"))) then
      wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.25x0.25glob_patch.nc"
    else if (.not.ismissing(str_match(fcst_config, "conus_60_x4"))) then
      wgt_file = "/glade/scratch/zarzycki/map_conus_60_x4_to_0.25x0.25glob_patch.nc"
    else if (.not.ismissing(str_match(fcst_config, "conus_15_x16"))) then
      wgt_file = "/glade/scratch/zarzycki/map_conus_15_x16_to_0.25x0.25glob_patch.nc"
    else
      print("incorrect matching SE weight file string")
      exit()
    end if
    end if
    end if
  end if
end if

gfs_grib = "gfs_4_"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"_"+sprinti("%0.2i",hh)+"00_"+sprinti("%0.3i",hourForecast)+".grb2"
print("GFS FORECAST FILE: "+gfs_grib)
if (.not.isfilepresent(WORKDIR+gfs_grib)) then
  system("cd "+WORKDIR+"; wget ftp://nomads.ncdc.noaa.gov/GFS/Grid4/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+"/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"/"+gfs_grib)
end if
anal_grib = "gfsanl_4_"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"_"+sprinti("%0.2i",f_hh)+"00_000.grb2"
print("GFS ANALYSIS FILE: "+anal_grib)
if (.not.isfilepresent(WORKDIR+anal_grib)) then
  system("cd "+WORKDIR+"; wget ftp://nomads.ncdc.noaa.gov/GFS/analysis_only/"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+"/"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"/"+anal_grib)
end if

if (.not.isfilepresent(WORKDIR+gfs_grib)) then
  print("We couldn't get gfs_grib! Now exiting...")
  exit
end if
if (.not.isfilepresent(WORKDIR+anal_grib)) then
  print("We couldn't get anal_grib! Now exiting...")
  exit
end if

climoFile = addfile(climo_netcdf,"r")
gfsFile = addfile(WORKDIR+gfs_grib,"r")
analFile = addfile(WORKDIR+anal_grib,"r")

; get climatological Z500 field for this day
time = climoFile->time
climoLat = climoFile->lat
climoLon = climoFile->lon
date = cd_inv_calendar(2000,f_mm,f_dd,f_hh,0,0,time@units,0)
Z500climo_native = climoFile->$climo_varname$({date},:,:)

; extract Z500 from GFS forecast and analysis
if (varname .eq. "Z") then
  Z500gfs = gfsFile->HGT_P0_L100_GLL0({varlev*100.},:,:)
  Z500anal = analFile->HGT_P0_L100_GLL0({varlev*100.},:,:)
else if (varname .eq. "TS") then
  Z500gfs = gfsFile->TMP_P0_L1_GLL0(:,:)
  Z500anal = analFile->TMP_P0_L1_GLL0(:,:)
else if (varname .eq. "T") then
  Z500gfs = gfsFile->TMP_P0_L100_GLL0({varlev*100.},:,:)
  Z500anal = analFile->TMP_P0_L100_GLL0({varlev*100.},:,:)
else if (varname .eq. "U") then
  Z500gfs = gfsFile->UGRD_P0_L100_GLL0({varlev*100.},:,:)
  Z500anal = analFile->UGRD_P0_L100_GLL0({varlev*100.},:,:)
else
  print("no")
end if
end if
end if
end if

; Flip lats since GFS is 90 -> -90 by default
Z500gfs=Z500gfs(::-1,:)
Z500anal=Z500anal(::-1,:)

; interp CLIMO
Z500climo=linint2_Wrap(climoLon,climoLat,Z500climo_native,True,Z500gfs&lon_0,Z500gfs&lat_0,0)

if (do_cam) then
  if (varname .eq. "Z") then
    if (use_Z500) then
      Z500_se = forecastFile->$climo_varname$(0,:)
      Opt         = True
      Z500forecast  = ESMF_regrid_with_weights(Z500_se,wgt_file,Opt)
    else
      if (mpas) then
        Z3=forecastFile->Z3(0,:,:)
        PS=forecastFile->PS(0,:)
        PRESSURE=forecastFile->PRESSURE(0,:,:)
        TBOT=forecastFile->T(0,29,:)
        topofile=addfile("/glade/u/home/zarzycki/work/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
        PHIS=topofile->PHIS

        Opt         = True
        Z3int      = ESMF_regrid_with_weights(Z3,wgt_file,Opt)
        PSint      = ESMF_regrid_with_weights(PS,wgt_file,Opt)
        PRESSUREint= ESMF_regrid_with_weights(PRESSURE,wgt_file,Opt)
        TBOTint    = ESMF_regrid_with_weights(TBOT,wgt_file,Opt)
        PHISint    = ESMF_regrid_with_weights(PHIS,wgt_file,Opt)

        intyp = 2      ; 1=linear, 2=log, 3=log-log
        kxtrp = False   ; True=extrapolate
        varflg = -1                          ; geo pot hgt is variable [tbot is used]

        Z500forecast_interp = vintp2p_ecmwf(Z3int, PRESSUREint/100., varlev ,PSint, intyp, 1, \
                   kxtrp,varflg,TBOTint,PHISint)
        Z500forecast = Z500forecast_interp(0,:,:)
      else
        Z3=forecastFile->Z3(0,:,:)
        PS=forecastFile->PS(0,:)
        hyam=forecastFile->hyam
        hybm=forecastFile->hybm
        p0=1000.
        Opt         = True
        Z3int  = ESMF_regrid_with_weights(Z3,wgt_file,Opt)
        PSint  = ESMF_regrid_with_weights(PS,wgt_file,Opt)

        intyp = 2      ; 1=linear, 2=log, 3=log-log
        kxtrp = False   ; True=extrapolate

        Z500forecast_interp = vinth2p(Z3int,hyam,hybm,varlev,PSint,intyp,p0,1,kxtrp)
        Z500forecast = Z500forecast_interp(0,:,:)
      end if
    end if
  else if (varname .eq. "T") then
      if (mpas) then
        T=forecastFile->T(0,:,:)
        PS=forecastFile->PS(0,:)
        PRESSURE=forecastFile->PRESSURE(0,:,:)
        TBOT=forecastFile->T(0,29,:)
        topofile=addfile("/glade/u/home/zarzycki/work/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
        PHIS=topofile->PHIS

        Opt         = True
        Tint       = ESMF_regrid_with_weights(T,wgt_file,Opt)
        PSint      = ESMF_regrid_with_weights(PS,wgt_file,Opt)
        PRESSUREint= ESMF_regrid_with_weights(PRESSURE,wgt_file,Opt)
        TBOTint    = ESMF_regrid_with_weights(TBOT,wgt_file,Opt)
        PHISint    = ESMF_regrid_with_weights(PHIS,wgt_file,Opt)

        intyp = 2      ; 1=linear, 2=log, 3=log-log
        kxtrp = False   ; True=extrapolate
        varflg = 1                          ; temp is variable [tbot is used]

        Z500forecast_interp = vintp2p_ecmwf(Tint, PRESSUREint/100., varlev ,PSint, intyp, 1, \
                   kxtrp,varflg,TBOTint,PHISint)
        Z500forecast = Z500forecast_interp(0,:,:)
      else
        T=forecastFile->T(0,:,:)
        PS=forecastFile->PS(0,:)
        hyam=forecastFile->hyam
        hybm=forecastFile->hybm
        p0=1000.
        Opt         = True
        Tint  = ESMF_regrid_with_weights(T,wgt_file,Opt)
        PSint  = ESMF_regrid_with_weights(PS,wgt_file,Opt)

        intyp = 2      ; 1=linear, 2=log, 3=log-log
        kxtrp = False   ; True=extrapolate

        Z500forecast_interp = vinth2p(Tint,hyam,hybm,varlev,PSint,intyp,p0,1,kxtrp)
        Z500forecast = Z500forecast_interp(0,:,:)
      end if
  else if (varname .eq. "U") then
      if (mpas) then
        U=forecastFile->U(0,:,:)
        PS=forecastFile->PS(0,:)
        PRESSURE=forecastFile->PRESSURE(0,:,:)
        TBOT=forecastFile->T(0,29,:)
        topofile=addfile("/glade/u/home/zarzycki/work/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
        PHIS=topofile->PHIS

        Opt         = True
        Uint       = ESMF_regrid_with_weights(U,wgt_file,Opt)
        PSint      = ESMF_regrid_with_weights(PS,wgt_file,Opt)
        PRESSUREint= ESMF_regrid_with_weights(PRESSURE,wgt_file,Opt)
        TBOTint    = ESMF_regrid_with_weights(TBOT,wgt_file,Opt)
        PHISint    = ESMF_regrid_with_weights(PHIS,wgt_file,Opt)

        intyp = 2      ; 1=linear, 2=log, 3=log-log
        kxtrp = False   ; True=extrapolate
        varflg = 1                          ; temp is variable [tbot is used]

        Z500forecast_interp = vintp2p_ecmwf(Uint, PRESSUREint/100., varlev ,PSint, intyp, 0, \
                   kxtrp,varflg,TBOTint,PHISint)
        Z500forecast = Z500forecast_interp(0,:,:)
      else
        U=forecastFile->U(0,:,:)
        PS=forecastFile->PS(0,:)
        hyam=forecastFile->hyam
        hybm=forecastFile->hybm
        p0=1000.
        Opt         = True
        Uint  = ESMF_regrid_with_weights(U,wgt_file,Opt)
        PSint  = ESMF_regrid_with_weights(PS,wgt_file,Opt)

        intyp = 2      ; 1=linear, 2=log, 3=log-log
        kxtrp = False   ; True=extrapolate

        Z500forecast_interp = vinth2p(Uint,hyam,hybm,varlev,PSint,intyp,p0,0,kxtrp)
        Z500forecast = Z500forecast_interp(0,:,:)
      end if
  else if (azvar .eq. "TS") then
    Z500_se = forecastFile->TREFHT(0,:)
    Opt         = True
    Z500forecast  = ESMF_regrid_with_weights(Z500_se,wgt_file,Opt)
  else
    print("no")
  end if
  end if
  end if
  end if ; var selection

  ;print("Begin interp")
  guess     = 1                ; use zonal means
  is_cyclic = True             ; cyclic [global]
  nscan     = 500             ; usually much less than this
  eps       = 1.e-2            ; variable dependent
  relc      = 0.5              ; relaxation coefficient
  opt       = 0                ; not used
  poisson_grid_fill( Z500forecast, is_cyclic, guess, nscan, eps, relc, opt)
  Z500forecast_ = Z500forecast(:,0:1439)
  Z500forecast_ = lonFlip(Z500forecast_)
  newZ500 = linint2(Z500forecast_&lon,Z500forecast_&lat,Z500forecast_,True,Z500gfs&lon_0,Z500gfs&lat_0,0)
  copy_VarMeta(Z500climo,newZ500)
end if

if (do_cam) then
  Z500forecastAnom = Z500climo
  Z500forecastAnom = newZ500 - Z500climo
end if

; Calculate anoms
Z500gfsAnom  = Z500climo
Z500analAnom = Z500climo
Z500gfsAnom  = Z500gfs - Z500climo
Z500analAnom = Z500anal - Z500climo

print("Calculating anomaly correlations...")
ACCgfs =      sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))
print("GFS forecast: "+ACCgfs)

if (do_cam) then
  ACCforecast = sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))
  print("CAM forecast: "+ACCforecast)
  if (do_comparison) then
    ACCcomparison = sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})*Z500gfsAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500gfsAnom({minLat:maxLat},{minLon:maxLon})^2))
    print("CAM/GFS comparison: "+ACCcomparison)
  else
    ACCcomparison = 0.
  end if
else
  ACCforecast = 0.
  ACCcomparison = 0.
end if

;stats_output_name="stats_"+fcst_config+"_"+hourForecast+".txt"
;stats_output_name="stats.txt"
stats_output_name="./out-stats/"+stats_string
quote = inttochar(34)
delim = " "
system("echo "+quote+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+delim+ACCgfs+delim+ACCforecast+delim+ACCcomparison+delim+fcst_config+delim+hourForecast+delim+region+delim+azvar+     quote+" >> "+stats_output_name)

if (deleteGFSfiles) then
  print("Deleting files...")
  system("rm gfs*")
end if

if (do_plot)
;************************************************
; create plot
;************************************************
  plot = new(3,graphic)   
  wks = gsn_open_wks("x11","map")           ; open a ps file
  gsn_define_colormap(wks,"MPL_RdBu")

  res                   = True
  res@gsnDraw = False
  res@gsnFrame = False
  res@mpFillOn          = False
 
  res@cnFillOn          = True              ; color plot desired
  res@cnLineLabelsOn    = False             ; turn off contour lines
  res@cnLinesOn = False
  res@gsnSpreadColors     = True            ; use full range of color map
  res@cnLevelSelectionMode =  "ManualLevels"
   
  if (varname .eq. "Z") then
    res@cnMinLevelValF       = -500.
    res@cnMaxLevelValF       = 500.
    res@cnLevelSpacingF      =   50.
  else if (varname .eq. "TS" .or. azvar .eq. "T") then
    res@cnLevelSelectionMode =  "ManualLevels"   
    res@cnMinLevelValF       = -10.
    res@cnMaxLevelValF       = 10.
    res@cnLevelSpacingF      =   4.
  else if (varname .eq. "U") then
    res@cnLevelSelectionMode =  "ManualLevels"   
    res@cnMinLevelValF       = -20.
    res@cnMaxLevelValF       = 20.
    res@cnLevelSpacingF      =   5.
  else  
  end if
  end if
  end if

  res@lbLabelBarOn = False

  res@mpMaxLatF = maxLat           ; choose subregion
  res@mpMinLatF = minLat
  res@mpMinLonF = minLon
  res@mpMaxLonF = maxLon
  res@mpCenterLonF = (res@mpMinLonF+res@mpMaxLonF)/2.

  res@gsnLeftString="GFS forecast"
  plot(0) = gsn_csm_contour_map(wks,Z500gfsAnom,res)
  res@gsnLeftString="CAM forecast"
  plot(1) = gsn_csm_contour_map(wks,Z500forecastAnom,res)  ; create the plot
  res@gsnLeftString="GFS analysis"
  plot(2) = gsn_csm_contour_map(wks,Z500analAnom,res)

;************************************************
; create panel
;************************************************
  resP                     = True
  ;resP@gsnPanelMainString = "A plot with a common label bar"
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.01               ; make labels smaller

  gsn_panel(wks,plot,(/3,1/),resP)
end if
  
end

