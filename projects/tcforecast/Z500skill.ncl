load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

hourForecast=48
do_plot = False
do_CAM = True

; ===== Getting date from YYYYMMDDHH
dtime_map = (/4,2,2,2/)
splitDate = str_split_by_length(tostring(YYYYMMDDHH),dtime_map)
yyyy=toint(splitDate(0))
mm=toint(splitDate(1))
dd=toint(splitDate(2))
hh=toint(splitDate(3))

print("Forecast initialized at: "+hh+"Z on "+mm+"/"+dd+"/"+yyyy)

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

print("Forecast at "+hourForecast+" HOURS: valid at: "+f_hh+"Z on "+f_mm+"/"+f_dd+"/"+f_yyyy)

;sprinti("%0.5i",f_hh_to_sec)
;sprinti("%0.2i",f_dd)

forecast_netcdf = "/glade/u/home/zarzycki/scratch/_TCFORECAST/"+sprinti("%0.4i",yyyy)+"_"+sprinti("%0.2i",hh)+"Z/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/tcforecast_60_x4.cam.h1."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"

climo_grib = "/glade/u/home/zarzycki/work/CFSRskill/cfsr_z500.grb"
climo_netcdf = "/glade/u/home/zarzycki/work/CFSRskill/simple.nc"

gfs_dir  = "/glade/u/home/zarzycki/scratch/GFS_VALID/forecasts/"
gfs_name = "gfs_4_"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"_0000_"+sprinti("%0.3i",hourForecast)+".grb2"
gfs_grib = gfs_dir+"/"+gfs_name
if (.not.isfilepresent(gfs_grib)) then
  print("Trying to get forecast file")
  system("wget ftp://nomads.ncdc.noaa.gov/GFS/Grid4/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+"/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"/gfs_4_"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"_0000_"+sprinti("%0.3i",hourForecast)+".grb2")
  system("mv "+gfs_name+" "+gfs_dir)
  if (.not.isfilepresent(gfs_grib)) then
    print("forecast still not present, exiting")
    exit
  end if
end if
  
anal_dir  = "/glade/u/home/zarzycki/scratch/GFS_VALID/analysis/"
anal_name = "gfsanl_4_"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"_0000_000.grb2"
anal_grib = anal_dir+"/"+anal_name
if (.not.isfilepresent(anal_grib)) then
  print("Trying to get analysis file")
  system("wget ftp://nomads.ncdc.noaa.gov/GFS/analysis_only/"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+"/"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"/gfsanl_4_"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"_0000_000.grb2")
  system("mv "+anal_name+" "+anal_dir)
  if (.not.isfilepresent(anal_grib)) then
    print("analysis still not present, exiting")
    exit
  end if
end if


climoFile = addfile(climo_netcdf,"r")
gfsFile = addfile(gfs_grib,"r")
analFile = addfile(anal_grib,"r")

time = climoFile->initial_time0_hours
climoLat = climoFile->g0_lat_1
climoLon = climoFile->g0_lon_2
date = cd_inv_calendar(1999,mm,dd,hh,0,0,time@units,0)
Z500climo = climoFile->Z500({date},:,:)

Z500gfs = gfsFile->HGT_P0_L100_GLL0({50000},:,:)
Z500anal = analFile->HGT_P0_L100_GLL0({50000},:,:)

if(do_CAM)
  forecast_netcdf = "/glade/u/home/zarzycki/scratch/_TCFORECAST/"+sprinti("%0.4i",yyyy)+"_"+sprinti("%0.2i",hh)+"Z/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+"/tcforecast_60_x4.cam.h1."+sprinti("%0.4i",f_yyyy)+"-"+sprinti("%0.2i",f_mm)+"-"+sprinti("%0.2i",f_dd)+"-"+sprinti("%0.5i",f_hh_to_sec)+".nc"
  forecastFile = addfile(forecast_netcdf,"r")
  wgt_file = "/glade/u/home/zarzycki/work/maps/tcforecast_60_x4/map_tcforecast_60_x4_TO_0.25x0.25_patc.nc"

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

Z500gfsAnom      = Z500climo
Z500gfsAnom      = Z500gfs(::-1,:) - Z500climo

Z500analAnom = Z500climo
Z500analAnom = Z500anal(::-1,:) - Z500climo

if(do_CAM)
  Z500forecastAnom = Z500climo
  Z500forecastAnom = newZ500 - Z500climo
end if

minLat = 20
maxLat = 80
minLon = 0
maxLon = 360

ACCgfs   =      sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))
if(do_CAM)
  ACCforecast = sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(Z500forecastAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))
else
  ACCforecast = 0
end if

quote = inttochar(34) 

;; CAM, GFS
system("echo "+quote+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+" "+ACCforecast+" "+ACCgfs+quote+" >> stats.txt")

;system("rm gfs*")


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

