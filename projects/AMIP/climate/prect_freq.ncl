;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"
;========================================================
begin

whowedoing="TRMM"
mmday_to_ms = 1.15740741e-8

; generate 1 deg lats, lons
gridsize = 0.5
lonW = 0
lonE =    360
if (whowedoing .eq. "TRMM") then
  latS =    -50
  latN =   50
else
  latS =    -90
  latN =   90
end if
dlat =  gridsize
dlon =  gridsize
nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)
lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)
lat@units = "degrees_north"
lon@units = "degrees_east"

print("Loading the data")
if (whowedoing .eq. "TRMM") then
  filesdir="/glade/u/home/zarzycki/scratch/TRMM/daily/"
  all_files = systemfunc("ls "+ filesdir+"/3B42_daily*.nc ")
  fall      = addfiles (all_files, "r")
  ListSetType (fall, "cat")             ; concatenate or "merge" (default)
  latitude  = fall[0]->latitude
  longitude  = fall[0]->longitude
  time = fall[:]->time
  PRECT = fall[:]->r
  ;PRECT = PRECT * (24/21)
  printVarSummary(PRECT)
  PRECTNEW = area_conserve_remap_Wrap(longitude,latitude,PRECT,lon,lat,False)
  delete(PRECT)
  PRECT = PRECTNEW

else if (whowedoing .eq. "ne30") then
  filesdir="/glade/scratch/zarzycki/h0files/ne30/"
  all_files = systemfunc("ls "+ filesdir+"/*h0*.nc ")
  fall      = addfiles (all_files, "r")
  ListSetType (fall, "cat")             ; concatenate or "merge" (default)

  lev  = fall[0]->lev
  ;lat  = ndtooned(fall[0]->lat)
  ;lon  = ndtooned(fall[0]->lon)
  time = fall[:]->time

  PRECT = fall[:]->PRECT(:,:)
  PRECT@_FillValue = -9999.9
  PRECT = PRECT/mmday_to_ms
  ncol = dimsizes(lat)
  
  wgtfile = "/glade/u/home/zarzycki/work/grids/ne30amip_to_1x1.nc"
  opt = True
  opt@PrintTimings = True
  PRECTNEW = ESMF_regrid_with_weights(PRECT,wgtfile,opt)
  delete(PRECT)
  PRECT = PRECTNEW
  delete(PRECTNEW)

  PRECTNEW = area_conserve_remap_Wrap(PRECT&lon,PRECT&lat,PRECT,lon,lat,False)
  delete(PRECT)
  PRECT = PRECTNEW
  
else if (whowedoing .eq. "atl30x4") then
  filesdir="/glade/scratch/zarzycki/h0files/atl30x4/"
  all_files = systemfunc("ls "+ filesdir+"/*h0*.nc ")
  fall      = addfiles (all_files, "r")
  ListSetType (fall, "cat")             ; concatenate or "merge" (default)
  latitude  = fall[0]->lat
  longitude  = fall[0]->lon
  time = fall[:]->time
  PRECT = fall[:]->PRECT
  PRECT@_FillValue = -9999.9
  PRECT = PRECT/mmday_to_ms

  PRECTNEW = area_conserve_remap_Wrap(longitude,latitude,PRECT,lon,lat,False)
  delete(PRECT)
  PRECT = PRECTNEW
else
print("wrong model")
exit()
end if
end if
end if
                         
ntimes = dimsizes(time)

freqThres = 0.5

FREQ = PRECT
PREC_EVENTS = PRECT
PRECTSUM = dim_sum_n_Wrap(PRECT,0)

FREQ = where(FREQ.gt.freqThres,1,0)
PREC_EVENTS = where(PREC_EVENTS.gt.freqThres,PREC_EVENTS,PREC_EVENTS@_FillValue)

FREQSUM = dim_sum_n_Wrap(FREQ,0)
if (whowedoing .eq. "blah") then
  FREQSUM_PERC = PRECT(0,:)
else
  FREQSUM_PERC = PRECT(0,:,:)
end if
FREQSUM_PERC = 100*FREQSUM/ntimes

printVarSummary(FREQSUM_PERC)

PRECT_INTENS = dim_avg_n_Wrap(PREC_EVENTS,0)
;PRECT_INTENS = dim_sum_n_Wrap(PREC_EVENTS,0)/ntimes

;******************************************************
; create plot
;******************************************************
wks = gsn_open_wks("pdf","rain_stats_"+whowedoing)               ; open workstation
gsn_define_colormap(wks,"wh-bl-gr-ye-re")   ; choose colormap
map = new(2,graphic) 

res                     = True         ; plot modifications desired
;  res@gsnMaximize         = True         ; Maximize size of plot in frame
res@gsnSpreadColors     = True         ; Use full colormap, but start
res@gsnDraw = False
res@gsnFrame = False

if (whowedoing .eq. "blah") then
  res@sfXArray            = lon        ; Required to tell NCL where to
  res@sfYArray            = lat        ; overlay data on globe.
end if

res@cnFillOn            = True         ; Turn on contour fill
res@cnFillMode          = "RasterFill"   ; Style of fill. You can also
                                       ; use "CellFill" and "RasterFill"
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels

res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

res@mpMinLatF   = -20.                 
res@mpMaxLatF   = 50.
res@mpMinLonF   = -120.
res@mpMaxLonF   = 20.

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 5.			; set the minimum contour level
res@cnMaxLevelValF  = 95.			; set the maximum contour level
res@cnLevelSpacingF = 5.			; set the interval between contours

map(0) = gsn_csm_contour_map_ce(wks,FREQSUM_PERC,res)

res@cnMinLevelValF  = 0.8		; set the minimum contour level
res@cnMaxLevelValF  = 15.2			; set the maximum contour level
res@cnLevelSpacingF = 0.8		; set the interval between contours

map(1) = gsn_csm_contour_map_ce(wks,PRECT_INTENS,res)

map(0) = plot_outline_fcn(wks,map(0),"Black",5.0)
map(1) = plot_outline_fcn(wks,map(1),"Black",5.0)

gsn_panel(wks,map,(/2,1/),False)  

end
