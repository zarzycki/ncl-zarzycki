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

;;; RANGE FOR ANOMALY CALCULATION
minLat = 20
maxLat = 80
minLon = 0
maxLon = 360

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
WORKDIR="/glade/p/work/zarzycki/CFSRskill/"

climo_grib = "cfsr_z500.grb"
climo_netcdf = "simple.nc"

;;;; ===== GET CAM FORECAST FILE
if (do_cam) then
  forecast_netcdf = "/glade/u/home/zarzycki/scratch/TCFORECAST_2013/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/tcforecast_60_x4.cam.h1."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
  print("CAM FORECAST FILE: "+forecast_netcdf)
  forecastFile = addfile(forecast_netcdf,"r")
  wgt_file = "/glade/u/home/zarzycki/work/maps/tcforecast_60_x4/map_tcforecast_60_x4_TO_0.25x0.25_patc.nc"
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

climoFile = addfile(WORKDIR+climo_netcdf,"r")
gfsFile = addfile(WORKDIR+gfs_grib,"r")
analFile = addfile(WORKDIR+anal_grib,"r")

; Get climatology
time = climoFile->initial_time0_hours
climoLat = climoFile->g0_lat_1
climoLon = climoFile->g0_lon_2
date = cd_inv_calendar(1999,f_mm,f_dd,f_hh,0,0,time@units,0)
Z500climo = climoFile->Z500({date},:,:)

Z500gfs = gfsFile->HGT_P0_L100_GLL0({50000},:,:)
Z500anal = analFile->HGT_P0_L100_GLL0({50000},:,:)

if (do_cam) then
  Z500_se = forecastFile->Z500(0,:)
  Opt         = True
  Z500forecast  = ESMF_regrid_with_weights(Z500_se,wgt_file,Opt)
  ;print("Begin interp")
  guess     = 1                ; use zonal means
  is_cyclic = True             ; cyclic [global]
  nscan     = 500             ; usually much less than this
  eps       = 1.e-2            ; variable dependent
  relc      = 0.5              ; relaxation coefficient
  opt       = 0                ; not used
  poisson_grid_fill( Z500forecast, is_cyclic, guess, nscan, eps, relc, opt)
  newZ500 = linint2(Z500forecast&lon,Z500forecast&lat,Z500forecast,True,climoLon,climoLat,0)
  copy_VarMeta(Z500climo,newZ500)
end if

;copy_VarMeta(Z500climo,Z500gfs)

;printVarSummary(newZ500)
;printVarSummary(Z500gfs)

if (do_cam) then
  Z500forecastAnom = Z500climo
  Z500forecastAnom = newZ500 - Z500climo
end if

Z500gfsAnom      = Z500climo
Z500gfsAnom      = Z500gfs(::-1,:) - Z500climo

Z500analAnom = Z500climo
Z500analAnom = Z500anal(::-1,:) - Z500climo

ACCgfs =      sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))
print("GFS forecast: "+ACCgfs)


if (do_cam) then
  ACCforecast = sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))
  print("CAM forecast: "+ACCforecast)
else
  ACCforecast = 0.
end if

quote = inttochar(34) 
system("echo "+quote+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+" "+ACCforecast+" "+ACCgfs+quote+" >> stats.txt")

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
  gsn_define_colormap(wks,"gui_default")

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
  res@cnLevelSpacingF      =   100. 

  plot(0) = gsn_csm_contour_map(wks,Z500forecastAnom,res)  ; create the plot
  plot(1) = gsn_csm_contour_map(wks,Z500gfsAnom,res)
  plot(2) = gsn_csm_contour_map(wks,Z500analAnom,res)
  
  gsn_panel(wks,plot,(/3,1/),False)
end if
  
end

