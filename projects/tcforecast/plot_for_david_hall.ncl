; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/home/zarzycki/ncl/functions/rainratetodbz.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

iniyear=2012
inimon=08
iniday=21
inisec=00000
filename="~/tcforecast_60_x4/run/FINRUNS/2012/2012082100/_tcforecast_60_x4.cam.h1.2012-08-29-00000.nc"

iniyearstr = sprinti("%04d",iniyear)
inimonstr = sprinti("%02d",inimon)
inidaystr = sprinti("%02d",iniday)
inisecstr = sprinti("%05d",inisec)
inihourstr = sprinti("%02d",toint(inisec)/3600)
inihoursince = cd_inv_calendar(toint(iniyearstr),toint(inimonstr),toint(inidaystr),toint(inihourstr),0,0,"hours", 0)


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

if (mod(forecastHour,6) .ne. 0) then
  print("For now, we are only printing data at 6 hr increments")
  exit
end if

print("Forecast for: "+hourstr+"Z "+monstr+" "+daystr+" "+yearstr)
print("Initialized at: "+inihourstr+"Z "+inimonstr+" "+inidaystr+" "+iniyearstr)

;wgt_file = "/home/zarzycki/ncl/maps/map_atlsquad_30_x8_TO_0.25x0.25_patc.130621.nc"
wgt_file = "/home/zarzycki/ncl/maps/map_tcforecast_60_x4_TO_0.25x0.25_patc.nc"
;wgt_file = "/home/zarzycki/ncl/maps/map_newtcforecast_60_x4_TO_0.25x0.25_patc.nc"
;---Get two variables to regrid and the source lat/lon grid
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

Opt         = True
prect  = ESMF_regrid_with_weights(prect_se,wgt_file,Opt)
u250  = ESMF_regrid_with_weights(u250_se,wgt_file,Opt)
v250  = ESMF_regrid_with_weights(v250_se,wgt_file,Opt)
u500  = ESMF_regrid_with_weights(u500_se,wgt_file,Opt)
v500  = ESMF_regrid_with_weights(v500_se,wgt_file,Opt)
z500  = ESMF_regrid_with_weights(z500_se,wgt_file,Opt)
tmq  = ESMF_regrid_with_weights(tmq_se,wgt_file,Opt)
flut  = ESMF_regrid_with_weights(flut_se,wgt_file,Opt)
u850  = ESMF_regrid_with_weights(u850_se,wgt_file,Opt)
v850  = ESMF_regrid_with_weights(v850_se,wgt_file,Opt)
mslp  = ESMF_regrid_with_weights(mslp_se,wgt_file,Opt)

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill( u250, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( v250, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( u500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( v500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( prect, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( z500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( tmq, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( flut, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( u850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( v850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( mslp, is_cyclic, guess, nscan, eps, relc, opt)

print(max(mslp))
print(min(mslp))

print("end interp")

;lat = u&lat
;lon = u&lon
;lat!0 = "lat"
;lon!0 = "lon"
;lat&lat = lat
;lon&lon = lon
;lev  = datafile->lev

RAINDBZ = rainratetodbz(prect,1)

;vort250 = uv2vrF_Wrap(u250,v250)
;vort250 = vort250/1e-5
;vort250@units="1E-5 1/s"

vort500 = uv2vrF_Wrap(u500,v500)
vort500 = vort500/1e-5
vort500@units="1E-5 1/s"

wind = u850
wind = sqrt(u850^2 + v850^2)

shear850250 = u850
shear850250 = 1.943*sqrt((u850-u250)^2 + (v850-v250)^2)


;*****************************************************
; PLOT
;*****************************************************

do plotindex = 0,1

if (plotindex .eq. 0)
  plotname = "natl"
  maxlat = 35.           ; choose subregion           
  minlat = 14.
  maxlon = 312. 
  minlon = 265.
else if (plotindex .eq. 1)
  plotname = "epac"
  maxlat = 40.           ; choose subregion           
  minlat = 5.
  maxlon = 270. 
  minlon = 195.
else
  plotname = "glob"
  maxlat = 90.           ; choose subregion           
  minlat = -90.
  maxlon = 360. 
  minlon = 0.
end if
end if

print("Plotting: "+plotname)


;----------- Global resources -----------------------------------------

res                 = True

res@gsnDraw      = False                        ; don't draw yet
res@gsnFrame     = False                        ; don't advance frame yet
res@gsnMaximize = True

res@gsnAddCyclic = False                    ; Don't add a cyclic point.

res@cnFillOn		  = True
res@cnLinesOn   = False 

res@mpFillOn                    = False        ; turn off gray fill
res@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
res@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
res@mpGeophysicalLineThicknessF = 3            ; thickness of outlines

res@mpMaxLatF                   = maxlat           ; choose subregion           
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon 
res@mpMaxLonF = maxlon 
res@mpCenterLonF = (res@mpMinLonF+res@mpMaxLonF)/2.

res@gsnSpreadColors      = True

res@tiMainString = "CAM-SE Isaac Init: 00Z 08 21 2012"
res@gsnLeftString = "Valid: "+hourstr+"Z "+monstr+" "+daystr+" "+yearstr

out_type = "png"
out_type@wkWidth = 800 
out_type@wkHeight = 800 

res_mslp = True
res_mslp@gsnDraw          = False           ; don't draw
res_mslp@gsnFrame         = False           ; don't advance frame
res_mslp@cnFillOn		  = False
res_mslp@cnLinesOn   = True
;res_mslp@cnLowLabelsOn = True
res_mslp@cnLowLabelBackgroundColor = -1
res_mslp@cnLabelMasking = False
;res_mslp@cnLowLabelFontColor = "red"
res_mslp@cnLineLabelsOn = False
res_mslp@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res_mslp@cnLevelSpacingF      =  4.0                ;
res_mslp@cnMinLevelValF       =  900.0           ;
res_mslp@cnMaxLevelValF       =  1060.0 ; Use 80.0 -> 60 for this
res_mslp@gsnRightString   = ""    
res_mslp@gsnLeftString    = ""
res_mslp@gsnCenterString  = ""
res_mslp@cnInfoLabelOn = False
res_mslp@cnLineThicknessF = 1.5

res_z500 = True
  res_z500@gsnDraw          = False           ; don't draw
  res_z500@gsnFrame         = False           ; don't advance frame
res_z500@cnFillOn		  = False
res_z500@cnLinesOn   = True
res_z500@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res_z500@cnLevelSpacingF      =  60.0                ;
res_z500@cnMinLevelValF       =  4800.0           ;
res_z500@cnMaxLevelValF       =  6200.0 ; Use 80.0 -> 60 for this
res_z500@gsnRightString   = ""    
res_z500@gsnLeftString    = ""
res_z500@gsnCenterString  = ""


out_type = "png"
wks = gsn_open_wks(out_type,"prect_"+plotname+"_"+yearstr+monstr+daystr+hourstr)

; Rain
res_rain                      = res
gsn_define_colormap(wks,"rainsnowradar")          ; choose colormap
res_rain@gsnRightString = "Simulated Reflectivity (dBZ)"
res_rain@gsnSpreadColors      = False              ; use full colormap
res_rain@cnFillColors = (/-1,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32/)
res_rain@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
res_rain@cnLevels    = (/0,5,10,15,20,25,30,35,40,45,50,55,60,65,70/)	; set levels
res_rain@lbLabelStride = 2
res_rain@lbOrientation = "vertical"
plotrain = gsn_csm_contour_map(wks,RAINDBZ(0,:,:),res_rain)
draw(plotrain)
frame(wks)
delete(wks)






; ====== Plot TMQ ============

out_type = "png"
wks = gsn_open_wks(out_type,"tmq_"+plotname+"_"+yearstr+monstr+daystr+hourstr)

gsn_define_colormap(wks,"rainbow")          ; choose colormap

res_tmq = res

res_tmq@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res_tmq@cnLevelSpacingF      =  2.5              ;
res_tmq@cnMinLevelValF       =  10.0           ;
res_tmq@cnMaxLevelValF       =  65.0 ; Use 80.0 -> 60 for this

plottmq = gsn_csm_contour_map(wks,tmq(0,:,:),res_tmq)
draw(plottmq)
frame(wks)
delete(wks)

; ====== Plot FLUT ============

out_type = "png"
wks = gsn_open_wks(out_type,"flut_"+plotname+"_"+yearstr+monstr+daystr+hourstr)

res_flut = res

res_flut@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res_flut@cnLevelSpacingF      =  15.0              ;
res_flut@cnMinLevelValF       =  90.0           ;
res_flut@cnMaxLevelValF       =  360.0 ; Use 80.0 -> 60 for this

plotflut = gsn_csm_contour_map(wks,flut(0,:,:),res_flut)
draw(plotflut)
frame(wks)
delete(wks)
delete(res_flut)

; ====== Plot 850 WIND ============

out_type = "pdf"
wks = gsn_open_wks(out_type,"wind_"+plotname+"_"+yearstr+monstr+daystr+hourstr)
gsn_define_colormap(wks,"WhBlGrYeRe")

res_wind = res

res_wind@cnLevelSelectionMode = "ManualLevels"
res_wind@cnLevelSpacingF      =  2.0 
res_wind@cnMinLevelValF       =  4.0
res_wind@cnMaxLevelValF       =  46.0 
res_wind@lbLabelStride = 2

res_wind@gsnRightString = "850 mb wind (color, m/s), SLP (contour, mb)"

plotwind = gsn_csm_contour_map(wks,wind(0,:,:),res_wind)
plotmslp = gsn_csm_contour(wks,mslp(0,:,:),res_mslp)
overlay(plotwind,plotmslp)

draw(plotwind)

pres                  = True
pres@gsLineThicknessF = 8.0
pres@gsLineColor  = "Black"
gsn_polyline(wks,plotwind,bestLon,bestLat,pres)
gsn_polyline(wks,plotwind,CAMLon,CAMLat,pres)
pres@gsLineThicknessF = 4.0
pres@gsLineColor  = "White"
gsn_polyline(wks,plotwind,bestLon,bestLat,pres)
pres@gsLineColor  = "Red"
gsn_polyline(wks,plotwind,CAMLon,CAMLat,pres)

frame(wks)

delete(wks)
delete(res_wind)



;----------- Get rid of 000001 on the end of png files
;  delete(wks)
  delete(res)

end do

end
