load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;; USER SETTINGS
hourForecast=120           ; What forecast do we want to analyze
do_plot = False            ; Do we want a 3 panel plot?
deleteGFSfiles = False     ; do we want to delete GFS files?
do_cam = True
do_comparison = True
use_Z500 = False
fcst_config = "hindcast_conus_30_x8_CAM5_L30"

;;; RANGE FOR ANOMALY CALCULATION
;minLat = 20
;maxLat = 80
;minLon = 0
;maxLon = 360

minLat = 21
maxLat = 53
minLon = 231
maxLon = 295

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

climo_netcdf = "/glade/u/home/zarzycki/sewx-cam-forecast/plotting_ncl/climo-files/Z500-1980-2009-NCEP.nc"

;;;; ===== GET CAM FORECAST FILE
if (do_cam) then
;  forecast_netcdf = "/glade/scratch/zarzycki/forecast_conus_30_x8_CAM5/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/_forecast_conus_30_x8_CAM5.cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
;  forecast_netcdf = "/glade/scratch/zarzycki/hindcast_conus_30_x8_CAM5_L30/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/hindcast_conus_30_x8_CAM5_L30.cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
;  forecast_netcdf = "/glade/scratch/zarzycki/hindcast_conus_30_x8_CAM4_L26/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/hindcast_conus_30_x8_CAM4_L26.cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
  forecast_netcdf = "/glade/scratch/zarzycki/"+fcst_config+"/run/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/"+fcst_config+".cam.h0."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
  print("CAM FORECAST FILE: "+forecast_netcdf)
  forecastFile = addfile(forecast_netcdf,"r")
  wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.25x0.25glob_patch.nc"
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
Z500climo_native = climoFile->Z500({date},:,:)

; extract Z500 from GFS forecast and analysis
Z500gfs = gfsFile->HGT_P0_L100_GLL0({50000},:,:)
Z500anal = analFile->HGT_P0_L100_GLL0({50000},:,:)

; Flip lats since GFS is 90 -> -90 by default
Z500gfs=Z500gfs(::-1,:)
Z500anal=Z500anal(::-1,:)

; interp CLIMO
Z500climo=linint2_Wrap(climoLon,climoLat,Z500climo_native,True,Z500gfs&lon_0,Z500gfs&lat_0,0)

if (do_cam) then
  if (use_Z500) then
    Z500_se = forecastFile->Z500(0,:)
    Opt         = True
    Z500forecast  = ESMF_regrid_with_weights(Z500_se,wgt_file,Opt)
  else
    Z3=forecastFile->Z3(0,:,:)
    PS=forecastFile->PS(0,:)
    hyam=forecastFile->hyam
    hybm=forecastFile->hybm
    p0=1000.
    Opt         = True
    Z3int  = ESMF_regrid_with_weights(Z3,wgt_file,Opt)
    PSint  = ESMF_regrid_with_weights(PS,wgt_file,Opt)
    Z500forecast_interp = vinth2p(Z3int,hyam,hybm,500.0,PSint,2,p0,1,True)
    Z500forecast = Z500forecast_interp(0,:,:)
  end if
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

stats_output_name="stats_"+fcst_config+"_"+hourForecast+".txt"
quote = inttochar(34) 
system("echo "+quote+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"  "+ACCgfs+"  "+ACCforecast+"  "+ACCcomparison+quote+" >> "+stats_output_name)

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

  res@gsnSpreadColors     = True            ; use full range of color map
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = -500.
  res@cnMaxLevelValF       = 500.
  res@cnLevelSpacingF      =   50. 

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

