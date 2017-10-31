; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "../radial_plots/radialAvg.ncl"

begin

outstring="clubb"
filename = "/glade/u/home/zarzycki/work/tcforecast_paper/clubb_cam5_cx/"+outstring+".nc"
out_type = "x11"

thefile = addfile(filename,"r")

stride = 1
topLev = 100
botLev = 1015
debug = False


lat = thefile->lat(::stride)
lon = thefile->lon(::stride)
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

timeStep = 0
U = thefile->U(timeStep,{topLev:botLev},::stride,::stride)
V = thefile->V(timeStep,{topLev:botLev},::stride,::stride)
PS1 = thefile->PSL(timeStep,::stride,::stride)
T = thefile->T(timeStep,{topLev:botLev},::stride,::stride)
Q = thefile->Q(timeStep,{topLev:botLev},::stride,::stride)
OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},::stride,::stride)
PRECT = thefile->PRECT(timeStep,::stride,::stride)

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

print(max(rad_omega))
print(min(rad_omega))


;==========================

wks   = gsn_open_wks ("pdf","cx_pdf/cx_radial_"+outstring)
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
res@tiXAxisString   = "Radius (km)"
res@tmYROn = False 
res@lbOrientation = "vertical"
res@tiYAxisFontHeightF=0.026
res@tiXAxisFontHeightF=0.026

res@gsnRightStringFontHeightF=0.026
res@gsnLeftStringFontHeightF=0.026
res@tmXBLabelFontHeightF=0.027
res@tmYLLabelFontHeightF=0.027
res@lbLabelFontHeightF=0.027

; Same for all plots
amres=True
txres=True
txres@txFontHeightF         = 0.03
txres@txBackgroundFillColor = "white"
txres@txPerimOn=True
txres@txPerimColor="black"
amres@amParallelPosF   = 0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = -0.48    ; This is the bottom edge of the plot.
amres@amJust           = "TopRight"

; Radial wind
res_rad = res
symMinMaxPlt(rad_v_rad,22,False,res_rad)
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = ispan(-16,16,2)
res_rad@lbLabelStride = 2
plot = gsn_csm_pres_hgt(wks,rad_v_rad(:,:),res_rad)



if (outstring .eq. "cam5") then
  txid1 = gsn_create_text(wks, "a.) CAM5", txres)
end if
if (outstring .eq. "clubb") then
  txid1 = gsn_create_text(wks, "d.) CLUBB", txres)
end if
annoid1 = gsn_add_annotation(plot, txid1, amres)


draw(plot)
frame(wks)

delete(plot)
delete(wks)

wks   = gsn_open_wks ("pdf","cx_pdf/cx_tangential_"+outstring)
gsn_define_colormap(wks,"matlab_jet")

; Tangential wind
res_theta = res
res_theta@cnLevelSelectionMode = "ExplicitLevels"
res_theta@cnLevels = ispan(-15,65,5)
res_theta@lbLabelStride = 2
plot = gsn_csm_pres_hgt(wks,rad_v_theta(:,:),res_theta)

if (outstring .eq. "cam5") then
  txid1 = gsn_create_text(wks, "b.) CAM5", txres)
end if
if (outstring .eq. "clubb") then
  txid1 = gsn_create_text(wks, "e.) CLUBB", txres)
end if
annoid1 = gsn_add_annotation(plot, txid1, amres)

draw(plot)
frame(wks)

delete(plot)
delete(wks)

wks   = gsn_open_wks ("pdf","cx_pdf/cx_t_anom_"+outstring)
gsn_define_colormap(wks,"matlab_jet")

; The var
res_thevar = res
res_thevar@cnLevelSelectionMode = "ExplicitLevels"
res_thevar@cnLevels = ispan(0,22,2)
plot = gsn_csm_pres_hgt(wks,rad_t_anom(:,:),res_thevar)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_thevar)


wks   = gsn_open_wks ("pdf","cx_pdf/cx_omega_"+outstring)
gsn_define_colormap(wks,"matlab_jet")

; The var
res_thevar = res
res_thevar@cnLevelSelectionMode = "ExplicitLevels"
res_thevar@cnLevels = fspan(-4.0,0.5,19)
res_thevar@gsnContourZeroLineThicknessF = 2.0
res_thevar@lbLabelStride = 2
plot = gsn_csm_pres_hgt(wks,rad_omega(:,:),res_thevar)
;res2                      = True
;res2@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
;res2@cnLevels    = (/ 0./)	; set levels
;plot2=gsn_csm_pres_hgt(wks,rad_omega(:,:),res2)
;overlay(plot,plot2)

if (outstring .eq. "cam5") then
  txid1 = gsn_create_text(wks, "c.) CAM5", txres)
end if
if (outstring .eq. "clubb") then
  txid1 = gsn_create_text(wks, "f.) CLUBB", txres)
end if
annoid1 = gsn_add_annotation(plot, txid1, amres)

draw(plot)
frame(wks)

end


