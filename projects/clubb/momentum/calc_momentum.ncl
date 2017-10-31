; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "../../radial_plots/radialAvg.ncl"

begin

debug=False
cam5=False
k10="0.3"      ; 0.1, 0.3, 0.6, 1.2
config="newcyclone30x4_clubb_k10-"+k10+"-Lscale-eqn8"
filename = "/glade/scratch/zarzycki/cam5_work/vertdiff-TC-test-VR/"+config+"/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"

if (debug) then
  filename = "/glade/scratch/zarzycki/cam5_work/vertdiff-TC-test-VR/test-wp2/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"
end if
if (cam5) then
  config="newcyclone30x4_cam5"
  filename = "/glade/scratch/zarzycki/cam5_work/vertdiff-TC-test-VR/newcyclone30x4_cam5/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"
end if

out_type = "pdf"

thefile = addfile(filename,"r")

stride = 1
topLev = 100
botLev = 1015
maxLat=0.
minLat=45.
timeStep=0

lat = thefile->lat({maxLat:minLat:stride})
lon = thefile->lon(::stride)
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"
hyam=thefile->hyam({topLev:botLev})
hybm=thefile->hybm({topLev:botLev})
P0=thefile->P0

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

U = thefile->U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
V = thefile->V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
PS1 = thefile->PS(timeStep,{maxLat:minLat:stride},::stride)
T = thefile->T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
Q = thefile->Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
if (.not. cam5) then
  KVM_CLUBB = thefile->KVM_CLUBB(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  KVM_CLUBB = KVM_CLUBB*tofloat(k10)
  if (debug) then
    KVM_CLUBB = thefile->KVM_CLUBB(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  end if
end if

;PRECT = thefile->PRECT(timeStep,{maxLat:minLat:stride},::stride)

PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)


W = OMEGA
W = omega_to_w(OMEGA,PRES,T)

print(max(OMEGA))
print(min(OMEGA))


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
Qref = Q(:,{psminlat},{psminlon+5.})
Qanom = Q - conform(Q,Qref,0)

WIND = U
WIND = sqrt(U^2+V^2)

DUDP=U
DUDP=DUDP@_FillValue
do i = 0,nlat-1
do j = 0,nlon-1
  DUDP(0,i,j) = (WIND(0,i,j) - WIND(1,i,j)) / (PRES(0,i,j) - PRES(1,i,j))
  DUDP(1:nlev-2,i,j) = (WIND(0:nlev-3,i,j) - WIND(2:nlev-1,i,j)) / (PRES(0:nlev-3,i,j) - PRES(2:nlev-1,i,j))
  DUDP(nlev-1,i,j) = (WIND(nlev-2,i,j) - WIND(nlev-1,i,j)) / (PRES(nlev-2,i,j) - PRES(nlev-1,i,j))
end do
end do
DUDP@long_name="DU/DP"
DUDP@units="m/s/hPa"

DUDZ=DUDP
DUDZ=DUDZ@_FillValue
DUDZ=(-PRES*9.81/287/T)*DUDP
DUDZ@long_name="DU/DZ"
DUDZ@units="s-1"

vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

rad_v_rad    = radialAvg3D(v_rad,lat,lon,lev,psminlat,psminlon,500.,True)
rad_v_theta  = radialAvg3D(v_theta,lat,lon,lev,psminlat,psminlon,500.,True)
rad_t  = radialAvg3D(T,lat,lon,lev,psminlat,psminlon,500.,True)
rad_t_anom  = radialAvg3D(Tanom,lat,lon,lev,psminlat,psminlon,500.,True)
rad_omega  = radialAvg3D(OMEGA,lat,lon,lev,psminlat,psminlon,500.,True)
rad_w = radialAvg3D(W,lat,lon,lev,psminlat,psminlon,500.,True)
rad_q_anom = radialAvg3D(Qanom,lat,lon,lev,psminlat,psminlon,500.,True)
;rad_q = radialAvg3D(Q,lat,lon,lev,psminlat,psminlon,500.,True)
rad_pres = radialAvg3D(PRES,lat,lon,lev,psminlat,psminlon,500.,True)
rad_dudp  = radialAvg3D(DUDP,lat,lon,lev,psminlat,psminlon,500.,True)
rad_dudz  = radialAvg3D(DUDZ,lat,lon,lev,psminlat,psminlon,500.,True)
if (.not. cam5) then
  rad_kvm  = radialAvg3D(KVM_CLUBB,lat,lon,lev,psminlat,psminlon,500.,True)
  if (debug) then
    rad_kvm  = radialAvg3D(KVM_CLUBB,lat,lon,lev,psminlat,psminlon,500.,True)
  end if
end if



;rad_dudz=rad_v_theta
;rad_dudz=rad_dudz@_FillValue
;rad_dudz(1:nlev-2,:) = (rad_v_theta(0:nlev-3,:) - rad_v_theta(2:nlev-1,:)) / (rad_pres(0:nlev-3,:) - rad_pres(2:nlev-1,:))
;rad_dudz= (-rad_pres*9.81/287./rad_t)*rad_dudz

rad_wu=rad_v_theta
rad_wu=rad_v_theta*rad_w
rad_wu@long_name="V_theta*W"
rad_wu@units="m2/s2"

K = rad_wu
K = rad_wu / rad_dudz


print(max(rad_w))
print(min(rad_w))

;==========================

res  = True
res@gsnDraw = False
res@gsnFrame = False
res@tiMainString     = config
res@gsnSpreadColors     = True        ; Span full color map
res@cnFillOn            = True        ; Turn on contour fill
res@cnLinesOn           = False
res@tmYRMode             = "Automatic"
res@cnLineLabelsOn = False
res@cnInfoLabelOn = False
res@tiYAxisString   = "Pressure (hPa)"
;res@tiXAxisString   = "Radius (km)"




wks   = gsn_open_wks (out_type,"pdf/v_radial_"+config)
gsn_define_colormap(wks,"hotcolr_19lev")
res_rad = res
symMinMaxPlt(rad_v_rad,26,False,res_rad)
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = ispan(-26,26,2)
plot = gsn_csm_pres_hgt(wks,rad_v_rad(:,:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)




wks   = gsn_open_wks (out_type,"pdf/v_theta_"+config)
gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
res_rad = res
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = fspan(0.0,80.0,21)
plot = gsn_csm_pres_hgt(wks,rad_v_theta(:,:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)




wks   = gsn_open_wks (out_type,"pdf/omega_"+config)
gsn_define_colormap(wks,"matlab_jet")
res_rad = res
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = fspan(-6.5,0.5,22)
res_rad@gsnContourZeroLineThicknessF = 2.0
plot = gsn_csm_pres_hgt(wks,rad_omega(:,:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)



wks   = gsn_open_wks (out_type,"pdf/q_anom_"+config)
gsn_define_colormap(wks,"matlab_jet")
res_rad = res
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = ispan(0,13,1)
plot = gsn_csm_pres_hgt(wks,rad_q_anom(:,:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)




wks   = gsn_open_wks (out_type,"pdf/t_anom_"+config)
gsn_define_colormap(wks,"matlab_jet")
res_rad = res
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = ispan(0,22,2)
plot = gsn_csm_pres_hgt(wks,rad_t_anom(:,:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)



wks   = gsn_open_wks (out_type,"pdf/wu_"+config)
gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
res_rad = res
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = fspan(0.0,55.0,23)
plot = gsn_csm_pres_hgt(wks,rad_wu({820:1000},:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)


if (.not. cam5) then
  wks   = gsn_open_wks (out_type,"pdf/kvm_"+config)
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
  res_rad = res
  res_rad@cnLevelSelectionMode = "ExplicitLevels"
  res_rad@cnLevels = fspan(0.0,500.0,21)
  plot = gsn_csm_pres_hgt(wks,rad_kvm({700:1000},:),res_rad)
  draw(plot)
  frame(wks)

  delete(plot)
  delete(wks)
  delete(res_rad)
end if

if debug then
  wks   = gsn_open_wks (out_type,"pdf/kvm_"+config)
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
  res_rad = res
  res_rad@cnLevelSelectionMode = "ExplicitLevels"
  res_rad@cnLevels = fspan(0.0,500.0,21)
  plot = gsn_csm_pres_hgt(wks,rad_kvm({820:1000},:),res_rad)
  draw(plot)
  frame(wks)

  delete(plot)
  delete(wks)
  delete(res_rad)
end if


wks   = gsn_open_wks (out_type,"pdf/dudz_"+config)
gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
res_rad = res
res_rad@cnLevelSelectionMode = "ExplicitLevels"
res_rad@cnLevels = fspan(-.01,.07,17)
plot = gsn_csm_pres_hgt(wks,rad_dudz({820:1000},:),res_rad)
draw(plot)
frame(wks)

delete(plot)
delete(wks)
delete(res_rad)

print(" DU/DZ")
print(rad_dudz&lev+"    "+rad_dudz(:,{100}))
print(" WU")
print(rad_wu&lev+"    "+rad_wu(:,{100}))
if (.not. cam5) then
  print(" KVM_CLUBB")
  print(rad_kvm&lev+"    "+rad_kvm(:,{100}))
end if
print(" K")
print(rad_wu&lev+"    "+(-rad_wu(:,{100})/rad_dudz(:,{100})))


end


