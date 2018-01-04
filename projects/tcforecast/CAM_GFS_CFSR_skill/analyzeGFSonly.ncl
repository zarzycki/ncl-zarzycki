load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

hourForecast=120
do_plot = False

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

climo_netcdf = "/glade/u/home/zarzycki/sewx-cam-forecast/plotting_ncl/climo-files/Z500-1980-2009-NCEP.nc"

gfs_grib = "gfs_4_"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"_"+sprinti("%0.2i",f_hh)+"00_"+sprinti("%0.3i",hourForecast)+".grb2"
if (.not.isfilepresent(gfs_grib)) then
  system("wget ftp://nomads.ncdc.noaa.gov/GFS/Grid4/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+"/"+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+"/"+gfs_grib)
end if
  
anal_grib = "gfsanl_4_"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"_"+sprinti("%0.2i",f_hh)+"00_000.grb2"
if (.not.isfilepresent(anal_grib)) then
  system("wget ftp://nomads.ncdc.noaa.gov/GFS/analysis_only/"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+"/"+sprinti("%0.4i",f_yyyy)+sprinti("%0.2i",f_mm)+sprinti("%0.2i",f_dd)+"/"+anal_grib)
end if

climoFile = addfile(climo_netcdf,"r")
gfsFile = addfile(gfs_grib,"r")
analFile = addfile(anal_grib,"r")

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

; Calculate anoms
Z500gfsAnom  = Z500climo
Z500analAnom = Z500climo
Z500gfsAnom  = Z500gfs - Z500climo
Z500analAnom = Z500anal - Z500climo

;printVarSummary(Z500gfsAnom)

minLat = 20
maxLat = 80
minLon = 0
maxLon = 360

;ACCforecast
ACCgfs =      sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})*Z500analAnom({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(     Z500gfsAnom({minLat:maxLat},{minLon:maxLon})^2)*sum(Z500analAnom({minLat:maxLat},{minLon:maxLon})^2))

;print(ACCgfs)
;print(ACCforecast)

quote = inttochar(34) 

system("echo "+quote+sprinti("%0.4i",yyyy)+sprinti("%0.2i",mm)+sprinti("%0.2i",dd)+sprinti("%0.2i",hh)+" "+ACCgfs+quote+" >> stats.txt")

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

