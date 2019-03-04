;*************************************************
; shapefiles_4.ncl
;
; Concepts illustrated:
;   - Drawing the Mississippi River Basin using data from a shapefile
;   - Masking a data array based on a geographical area obtained from a shapefile
;   - Attaching markers to a map
;   - Attaching polylines to a map plot
;
;*************************************************
; This script shows the "new" way (post NCL V6.0.0) of  masking
; data and adding shapefile outlines to an existing NCL map.
;*************************************************
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; This file still has to be loaded manually
load "./shapefile_utils.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;clm_file="/global/homes/c/czarzyck/scratch/hyperion/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003/lnd/hist/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003.clm2.h0.2002-01-15-00000.nc"
;clmf=addfile(clm_file,"r")
;swe=clmf->SNOWLIQ

YYYY=1987

print("Loading CLM data...")
clm_files=systemfunc("ls /global/homes/c/czarzyck/scratch/hyperion/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003/lnd/hist/*clm2.h0."+YYYY+"*")
clmf=addfiles (clm_files, "r")
swe =clmf[:]->H2OSNO
clmtime=clmf[:]->time
delete(clmf)
delete(clm_files)
print("... done loading CLM data.")

mintime=min(clmtime)
maxtime=max(clmtime)

print("Loading CAM data...")
cam_files=systemfunc("ls /global/homes/c/czarzyck/scratch/hyperion/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003/atm/hist/*.h1."+(YYYY-1)+"* /global/homes/c/czarzyck/scratch/hyperion/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003/atm/hist/*.h1."+YYYY+"*")
camf=addfiles (cam_files, "r")
prect =camf[:]->PRECT
precsl=camf[:]->PRECSL
precsc=camf[:]->PRECSC
delete(camf)
delete(cam_files)
print("... done loading CAM data.")

print("Processing CAM data...")
precra=prect
precra=prect-precsl-precsc
precra=8.64e7*precra
precra_sub=precra({mintime:maxtime},:)
delete(prect)
delete(precsl)
delete(precsc)
print("... done processing CAM data.")

print("regridding data...")
mapWgt="/global/homes/c/czarzyck/scratch/maps/hyperion/map_ne0np4natlanticwat.ne30x4_to_0.25x0.25_CONUS.nc"
data=ESMF_regrid_with_weights(swe,mapWgt,False)
rain=ESMF_regrid_with_weights(precra_sub,mapWgt,False)
print("... done regridding data.")

utctime = cd_calendar(data&time, -3)

print("masking data...")
;---Open shapefile and read lat/lon values.
shp_filename = "./SusquehannaRiverBasin.shp"
opt=True
opt@debug=True
opt@return_mask=True
data_mask    = shapefile_mask_data(data(0,:,:),shp_filename,opt)
data_mask!0="lat"
data_mask!1="lon"
data_mask&lat=data&lat
data_mask&lon=data&lon
data_mask = where(data_mask .eq. 0,data_mask@_FillValue,data_mask)
tmp=conform_dims(dimsizes(data), data_mask, (/1,2/))
data = where( ismissing(tmp) , data@_FillValue, data)
rain = where( ismissing(tmp) , rain@_FillValue, rain)
print("... done masking data.")

basin_avg_data=dim_avg_n_Wrap(data,(/1,2/))

basin_avg_rain=dim_avg_n_Wrap(rain,(/1,2/))

basin_avg_rain = where(basin_avg_data .lt. 1.0,basin_avg_rain@_FillValue,basin_avg_rain)

basin_avg_dSWE=basin_avg_data
do ii = 0,dimsizes(basin_avg_data)-2
  basin_avg_dSWE(ii)=basin_avg_data(ii)-basin_avg_data(ii+1)
end do

basin_avg_dSWE = where(basin_avg_dSWE.lt.-5,basin_avg_dSWE,0)
basin_avg_rain = where(basin_avg_rain.gt.5,basin_avg_rain,0)

basin_avg_dSWE@long_name="SWE change (filtered)"
basin_avg_rain@long_name="daily rainfall (filtered)"

print(utctime+" "+basin_avg_rain)

wks   = gsn_open_wks ("png","xy_"+YYYY)               ; send graphics to PNG file

res                  = True                     ; plot mods desired
res@trXMinF=mintime
res@trXMaxF=mintime+120
res@tiMainString     = "RoS (early "+YYYY+")"          ; add title
res@xyLineThicknessF = 2.0
res@trYMaxF           = abs(min(basin_avg_dSWE))                ; axis max
res@trYMinF           = min(basin_avg_dSWE) 
;res@vpHeightF = 0.4 
;res@vpWidthF = 0.9 

res2=res
res2@xyLineColors      = "green"                   ; line color
res2@trYMinF           = 0.                    ; axis max
res2@trYMaxF           = 20.                    ; axis min
plot  = gsn_csm_xy2 (wks,clmtime,basin_avg_dSWE,basin_avg_rain,res,res2) ; create plot

exit


wks = gsn_open_wks("x11","proj")          ; send graphics to PNG file

res                   = True

maxlat = 49.
minlat = 37.
maxlon = 295.-360.
minlon = 275.-360.
res@mpMaxLatF                   = maxlat           ; choose subregion           
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon
res@mpMaxLonF = maxlon
res@mpCenterLonF = (res@mpMinLonF+res@mpMaxLonF)/2.

res@mpFillOn          = False

res@cnFillOn          = True              ; color plot desired
res@cnFillPalette     = "gui_default"     ; set color map
res@cnLineLabelsOn    = False             ; turn off contour lines
res@txFontHeightF     = 0.015 

res@lbLabelFontHeightF  = 0.015           ; label bar font height

res@tiMainString       = "test"  ; add a title
res@tiMainFontHeightF  = .018                               ; font height
res@gsnAddCyclic = False

contour = gsn_csm_contour_map(wks,data(0,:,:),res)  ; create the plot

end
