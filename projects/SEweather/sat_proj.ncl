;/ Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "~/ncl/functions/rainratetodbz.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "~/ncl/functions/plot_outline_fcn_tcforecast_60_x4.ncl"

begin

plottrack=False
iniyear=2012
inimon=10
iniday=29
inisec=00000
;filename="/home/zarzycki/OTHER/2005082600/_tcforecast_60_x4.cam.h1.2005-08-29-43200.nc"

plotwind = new(1,graphic)

iniyearstr = sprinti("%04d",iniyear)
inimonstr = sprinti("%02d",inimon)
inidaystr = sprinti("%02d",iniday)
inisecstr = sprinti("%05d",inisec)
inihourstr = sprinti("%02d",toint(inisec)/3600)
inihoursince = cd_inv_calendar(toint(iniyearstr),toint(inimonstr),toint(inidaystr),toint(inihourstr),0,0,"hours", 0)

if (plottrack) then
csvfile = "issacBEST.csv"
lines = asciiread(csvfile,-1,"string")
delim = ","
bestLat  = tofloat(str_get_field(lines,1,delim))
bestLon = tofloat(str_get_field(lines,2,delim))
delete(lines)
csvfile = "issacCAMSE.csv"
lines = asciiread(csvfile,-1,"string")
delim = ","
CAMLat  = tofloat(str_get_field(lines,1,delim))
CAMLon = tofloat(str_get_field(lines,2,delim))
delete(lines)
print(bestLat)
print(CAMLat)
end if

zz  = ispan(3,960,3)
zzs = sprinti("%0.3i",zz)   ; "000", "001", ... "100"

;do time = 0,numfiles-1

;filename = fils(time)

datafile = addfile(filename,"r")
;print("Using: "+fils(time))

strs = str_split(filename,".")
; strs(0) = path to grid
; strs(1) = model
; strs(2) = file (h1, etc)
; strs(3) = date
; strs(4) = extension

datestrs = str_split(strs(3),"-")
yearstr = datestrs(0)
monstr = datestrs(1)
daystr = datestrs(2)
secstr = datestrs(3)
hourstr = sprinti("%02d",toint(secstr)/3600)

hoursince = cd_inv_calendar(toint(yearstr),toint(monstr),toint(daystr),toint(hourstr),0,0,"hours", 0)
forecastHour = toint(hoursince - inihoursince)
forecastHourStr = sprinti("%03d",forecastHour)
print(forecastHourStr)

if (mod(forecastHour,3) .ne. 0) then
  print("For now, we are only printing data at 6 hr increments")
  exit
end if

print("Forecast for: "+hourstr+"Z "+monstr+" "+daystr+" "+yearstr)
print("Initialized at: "+inihourstr+"Z "+inimonstr+" "+inidaystr+" "+iniyearstr)

;wgt_file = "/home/zarzycki/ncl/maps/map_atlsquad_30_x8_TO_0.25x0.25_patc.130621.nc"
wgt_file = "/glade/u/home/zarzycki/work/maps/tcforecast_60_x4/map_tcforecast_60_x4_TO_0.25x0.25_patc.nc"
;wgt_file = "/home/zarzycki/ncl/maps/map_newtcforecast_60_x4_TO_0.25x0.25_patc.nc"
;---Get two variables to regrid and the source lat/lon grid
lat1d = ndtooned(datafile->lat)          ; Pull off lat/lon variable and
lon1d = ndtooned(datafile->lon)          ; convert both to 1D.
prect_se = datafile->PRECT            ; time (1) x nlev x ncol
u250_se = datafile->U200
v250_se = datafile->V200
u500_se = datafile->U500
v500_se = datafile->V500
z500_se = datafile->Z500
tmq_se = datafile->TMQ
flut_se = datafile->FLUT
u850_se = datafile->U850
v850_se = datafile->V850
mslp_se = datafile->PSL/100

print(max(mslp_se))
print(min(mslp_se))

;Opt         = True
;prect  = ESMF_regrid_with_weights(prect_se,wgt_file,Opt)
;u250  = ESMF_regrid_with_weights(u250_se,wgt_file,Opt)
;v250  = ESMF_regrid_with_weights(v250_se,wgt_file,Opt)
;u500  = ESMF_regrid_with_weights(u500_se,wgt_file,Opt)
;v500  = ESMF_regrid_with_weights(v500_se,wgt_file,Opt)
;z500  = ESMF_regrid_with_weights(z500_se,wgt_file,Opt)
;tmq  = ESMF_regrid_with_weights(tmq_se,wgt_file,Opt)
;flut  = ESMF_regrid_with_weights(flut_se,wgt_file,Opt)
;u850  = ESMF_regrid_with_weights(u850_se,wgt_file,Opt)
;v850  = ESMF_regrid_with_weights(v850_se,wgt_file,Opt)
;mslp  = ESMF_regrid_with_weights(mslp_se,wgt_file,Opt)

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

;poisson_grid_fill( u250, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( v250, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( u500, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( v500, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( prect, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( z500, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( tmq, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( flut, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( u850, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( v850, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill( mslp, is_cyclic, guess, nscan, eps, relc, opt)

;print(max(mslp))
;print(min(mslp))

print("end interp")

;lat = u&lat
;lon = u&lon
;lat!0 = "lat"
;lon!0 = "lon"
;lat&lat = lat
;lon&lon = lon
;lev  = datafile->lev

RAINDBZ = rainratetodbz(prect_se,1)

;vort250 = uv2vrF_Wrap(u250,v250)
;vort250 = vort250/1e-5
;vort250@units="1E-5 1/s"

;vort500 = uv2vrF_Wrap(u500,v500)
;vort500 = vort500/1e-5
;vort500@units="1E-5 1/s"

wind = u850_se
wind = sqrt(u850_se^2 + v850_se^2)

;shear850250 = u850
;shear850250 = 1.943*sqrt((u850-u250)^2 + (v850-v250)^2)


;*****************************************************
; PLOT
;*****************************************************


  plotname = "natl"
  maxlat = 55.           ; choose subregion           
  minlat = 25.
  maxlon = 305. 
  minlon = 280.

print("Plotting: "+plotname)

varplot = "850wind"

;----------- Global resources -----------------------------------------

res                 = True

res@gsnDraw      = False                        ; don't draw yet
res@gsnFrame     = False                        ; don't advance frame yet
res@gsnMaximize = False

res@gsnAddCyclic = False                    ; Don't add a cyclic point.

res@cnFillOn		  = True
res@cnLinesOn   = False 

res@mpFillOn                    = False        ; turn off gray fill
res@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
res@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
res@mpGeophysicalLineThicknessF = 3            ; thickness of outlines

res@gsnSpreadColors      = True

;res@tiMainString = "CAM-SE Isaac Init: 00Z 08 21 2012"
res@gsnLeftString = "Valid: "+hourstr+"Z "+monstr+" "+daystr+" "+yearstr

out_type = "png"
wks = gsn_open_wks(out_type,varplot+"_"+yearstr+monstr+daystr+hourstr)




res_wind = res

res_wind@lbLabelBarOn = False

res_wind@gsnRightString = ""

if(varplot .eq. "flut") then
  thevar = flut_se(0,:)
  gsn_define_colormap(wks,"MPL_gist_yarg")
  res_wind@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
  res_wind@cnLevelSpacingF      =  10.0              ;
  res_wind@cnMinLevelValF       =  120.0           ;
  res_wind@cnMaxLevelValF       =  320.0 ; Use 80.0 -> 60 for this
end if

if(varplot .eq. "precip") then
  thevar = RAINDBZ(0,:)
  gsn_define_colormap(wks,"rainsnowradar")          ; choose colormap
  ;res_wind@gsnRightString = "Simulated Reflectivity (dBZ)"
  res_wind@gsnSpreadColors      = False              ; use full colormap
  res_wind@cnFillColors = (/-1,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32/)
  res_wind@cnLevelSelectionMode = "ExplicitLevels"                        ; set explicit contour levels
  res_wind@cnLevels    = (/0,5,10,15,20,25,30,35,40,45,50,55,60,65,70/)   ; set levels
  res_wind@lbLabelStride = 2
  ;res_wind@lbOrientation = "vertical"
end if

if(varplot .eq. "850wind") then
  thevar = wind(0,:)
  gsn_define_colormap(wks,"WhBlGrYeRe")
  res_wind@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
  res_wind@cnLevelSpacingF      =  2.0                ;
  res_wind@cnMinLevelValF       =  4.0           ;
  res_wind@cnMaxLevelValF       =  60.0 ; Use 80.0 -> 60 for this
  res_wind@lbLabelStride = 2
end if

res_wind@mpProjection          = "Satellite"  ; choose map projection
res_wind@mpCenterLonF          = 273.         ; choose center lon
res_wind@mpCenterLatF          =  28.         ; choose center lat
res_wind@mpLimitMode           = "LatLon"     ; required
size = 75.
res_wind@mpMinLatF             =  res_wind@mpCenterLatF - size
res_wind@mpMaxLatF             =  res_wind@mpCenterLatF + size
res_wind@mpMinLonF             =  res_wind@mpCenterLonF - size
res_wind@mpMaxLonF             =  res_wind@mpCenterLonF + size

res_wind@sfXArray            = lon1d        ; Required to tell NCL where to
res_wind@sfYArray            = lat1d        ; overlay data on globe.
res_wind@cnFillOn            = True         ; Turn on contour fill
res_wind@cnFillMode          = "RasterFill"   ; Style of fill. You can also
                                       ; use "CellFill" and "RasterFill"
res_wind@cnLinesOn           = False        ; Turn off contour lines
res_wind@cnLineLabelsOn      = False        ; Turn off contour line labels
res_wind@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;plotwind(0) = gsn_csm_contour_map(wks,thevar,res_wind)
;plotwind(0) = plot_outline_fcn(wks,plotwind(0),"red",5.0)

xsize = 10.
ysize = 7.
res_wind@mpMinLatF             =  res_wind@mpCenterLatF - ysize
res_wind@mpMaxLatF             =  res_wind@mpCenterLatF + ysize
res_wind@mpMinLonF             =  res_wind@mpCenterLonF - xsize
res_wind@mpMaxLonF             =  res_wind@mpCenterLonF + xsize
res_wind@gsnLeftString = ""

plotwind(0) = gsn_csm_contour_map(wks,thevar,res_wind)
plotwind(0) = plot_outline_fcn(wks,plotwind(0),"red",5.0)

resP                     = True                ; modify the panel plot
;resP@txString            = "A plot with a common label bar"
resP@gsnPanelLabelBar    = True                ; add common colorbar
resP@lbTitleString = thevar@units
resP@lbTitlePosition  = "Right"              ; title position
resP@lbTitleFontHeightF= .0135                ; make title smaller
resP@lbTitleDirection = "Across"             ; title direction
resP@lbTitleExtentF = 0.005
resP@lbTitleOffsetF = 0.06
gsn_panel(wks,plotwind,(/1,1/),resP)

end
