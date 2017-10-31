; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "../../radial_plots/radialAvg.ncl"

begin

outstring="clubb"
filename = "/glade/u/home/zarzycki/scratch/cam5_work/tc_"+outstring+"_ne120/camrun.cam.h2.2000-01-08-00000.nc"
out_type = "x11"

thefile = addfile(filename,"r")

stride = 1
topLev = 100
botLev = 1015
maxLat=0.
minLat=45.
debug = False
timeStep=0

lat = thefile->lat({maxLat:minLat:stride})
lon = thefile->lon(::stride)
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

U = thefile->U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
V = thefile->V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
PS1 = thefile->PS(timeStep,{maxLat:minLat:stride},::stride)
T = thefile->T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
Q = thefile->Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
PRECT = thefile->PRECT(timeStep,{maxLat:minLat:stride},::stride)

;---FIND LOCATIONS OF PSMIN and WINDMAX
;---Convert to 1D
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
;---Resolve the 1D indices back to their original 3D array.
a_indices  = ind_resolve(minind(a1D),dsizes_a)
;---Convert index to lat/lon points
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))

Tanom = T
Tref = T(:,{psminlat},{psminlon+5.})
Tanom = T - conform(T,Tref,0)

Q = Q*1000
Q@units="g/kg"
Qanom = Q
Qref = Q(:,{psminlat},{psminlon+10.})
Qanom = Q - conform(Q,Qref,0)

WIND = U
WIND = sqrt(U^2+V^2)

vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

rad_v_rad    = radialAvg3D(v_rad,lat,lon,lev,psminlat,psminlon,600.,True)
rad_v_theta  = radialAvg3D(v_theta,lat,lon,lev,psminlat,psminlon,600.,True)
rad_t_anom  = radialAvg3D(Tanom,lat,lon,lev,psminlat,psminlon,600.,True)
rad_omega  = radialAvg3D(OMEGA,lat,lon,lev,psminlat,psminlon,600.,True)
rad_q_anom = radialAvg3D(Qanom,lat,lon,lev,psminlat,psminlon,600.,True)
rad_q = radialAvg3D(Q,lat,lon,lev,psminlat,psminlon,600.,True)

print(max(rad_q))
print(min(rad_q))


;==========================

wks   = gsn_open_wks ("pdf","pdf/cx_radial_"+outstring)
gsn_define_colormap(wks,"hotcolr_19lev")
res  = True
res@gsnDraw = False
res@gsnFrame = False
;res@tiMainString     = "Basic XY plot"          ; add title
res@gsnSpreadColors     = True        ; Span full color map
res@cnFillOn            = True        ; Turn on contour fill
res@cnLinesOn           = False
res@tmYRMode             = "Automatic"
;res@lbLabelBarOn = False
res@cnLineLabelsOn = False
res@cnInfoLabelOn = False
res@tiYAxisString   = "Pressure (hPa)"
;res@tiXAxisString   = "Radius (km)"

; Radial wind
res_rad = res
symMinMaxPlt(rad_v_rad,26,False,res_rad)
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = ispan(-26,26,2)
plot = gsn_csm_pres_hgt(wks,rad_v_rad(:,:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)

wks   = gsn_open_wks ("pdf","pdf/cx_tangential_"+outstring)
gsn_define_colormap(wks,"matlab_jet")

; Tangential wind
res_theta = res
res_theta@tiYAxisString = ""
res_theta@cnLevelSelectionMode = "ExplicitLevels"
res_theta@cnLevels = ispan(-15,80,5)
plot = gsn_csm_pres_hgt(wks,rad_v_theta(:,:),res_theta)
draw(plot)
frame(wks)

delete(plot)
delete(wks)

wks   = gsn_open_wks ("pdf","pdf/cx_t_anom_"+outstring)
gsn_define_colormap(wks,"matlab_jet")

; The var
res_thevar = res
res_thevar@tiYAxisString = ""
res_thevar@cnLevelSelectionMode = "ExplicitLevels"
res_thevar@cnLevels = ispan(0,22,2)
plot = gsn_csm_pres_hgt(wks,rad_t_anom(:,:),res_thevar)
draw(plot)
frame(wks)
delete(plot)
delete(wks)
delete(res_thevar)

wks   = gsn_open_wks ("pdf","pdf/cx_q_anom_"+outstring)
gsn_define_colormap(wks,"matlab_jet")
; The var
res_thevar = res
res_thevar@tiYAxisString = ""
res_thevar@cnLevelSelectionMode = "ExplicitLevels"
res_thevar@cnLevels = ispan(0,13,1)
plot = gsn_csm_pres_hgt(wks,rad_q_anom(:,:),res_thevar)
draw(plot)
frame(wks)
delete(plot)
delete(wks)
delete(res_thevar)

wks   = gsn_open_wks ("pdf","pdf/cx_q_"+outstring)
gsn_define_colormap(wks,"matlab_jet")
; The var
res_thevar = res
res_thevar@tiYAxisString = ""
res_thevar@cnLevelSelectionMode = "ExplicitLevels"
res_thevar@cnLevels = ispan(0,26,2)
plot = gsn_csm_pres_hgt(wks,rad_q(:,:),res_thevar)
draw(plot)
frame(wks)
delete(plot)
delete(wks)
delete(res_thevar)


wks   = gsn_open_wks ("pdf","pdf/cx_omega_"+outstring)
gsn_define_colormap(wks,"matlab_jet")

; The var
res_thevar = res
res_thevar@tiYAxisString = ""
res_thevar@cnLevelSelectionMode = "ExplicitLevels"
res_thevar@cnLevels = fspan(-6.5,0.5,22)
res_thevar@gsnContourZeroLineThicknessF = 2.0
plot = gsn_csm_pres_hgt(wks,rad_omega(:,:),res_thevar)
;res2                      = True
;res2@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
;res2@cnLevels    = (/ 0./)	; set levels
;plot2=gsn_csm_pres_hgt(wks,rad_omega(:,:),res2)
;overlay(plot,plot2)
draw(plot)
frame(wks)

end


