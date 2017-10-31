; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "../../radial_plots/radialAvg.ncl"

begin
;configs=(/"0.3","cam5","1.2","0.6","0.1","0.3-reduceddrag","0.3-ktherm-0.1"/)  ;"0.3-reduceddrag","0.3-ktherm-1.2","0.3-ktherm-0.1"
;configs=(/"0.6","0.3","cam5","0.3-reduceddrag","0.3-ktherm-1.2","0.3-ktherm-0.1","0.3-ktherm-0.01"/)  ;"0.3-reduceddrag","0.3-ktherm-1.2","0.3-ktherm-0.1"
configs=(/"0.3","cam5","0.3-zmtau1200","0.3-Lscale-40","0.3-450s","0.3-ktherm-0.1"/)

plot_colors=(/"red","purple","orange","green","yellow","black","gray"/)
nruns = dimsizes(configs)
out_type="png"

innerRad=30.
outerRad=200.

; get data
do ii = 0,nruns-1

config="newcyclone30x4_clubb_k10-"+configs(ii)

if (configs(ii) .eq. "cam5")
  filename = "/glade/u/home/zarzycki/scratch/cam5_work/vertdiff-TC-test-VR/newcyclone30x4_cam5/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"
  f2= "/glade/u/home/zarzycki/scratch/cam5_work/vertdiff-TC-test-VR/newcyclone30x4_cam5/camrun.cam.h3.2000-01-08-00000.nc_regrid.nc"
  tf2 = addfile(f2,"r")
else
  filename = "/glade/scratch/zarzycki/cam5_work/vertdiff-TC-test-VR/"+config+"/camrun.cam.h1.2000-01-08-00000.nc_regrid.nc"
  f2= "/glade/u/home/zarzycki/scratch/cam5_work/vertdiff-TC-test-VR/"+config+"/camrun.cam.h3.2000-01-08-00000.nc_regrid.nc"
  tf2 = addfile(f2,"r")
end if

if (configs(ii) .eq. "cam5") then
  k10 = -999.00
else if (configs(ii) .eq. "1.2" .or. configs(ii) .eq. "0.6" .or. configs(ii) .eq. "0.3" .or. configs(ii) .eq. "0.1") then
  k10 = tofloat(configs(ii))
else
  k10 = 0.3
end if
end if

thefile = addfile(filename,"r")

stride = 1
topLev = 500
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
USTAR = tf2->USTAR(timeStep,{maxLat:minLat:stride},::stride)
LHFLX = tf2->LHFLX(timeStep,{maxLat:minLat:stride},::stride)
SHFLX = tf2->SHFLX(timeStep,{maxLat:minLat:stride},::stride)

PRES = U

if (k10 .gt. 0)
  KVM_CLUBB = thefile->KVM_CLUBB(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  KVM_CLUBB = KVM_CLUBB*k10
else
  KVM_CLUBB = tf2->KVM(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
end if

print(min(PS1))

PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)


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

vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)



;rad_v_rad    = radialAvg3D(v_rad,lat,lon,lev,psminlat,psminlon,500.,True)
rad_v_theta  = radialAvg3D(v_theta,lat,lon,lev,psminlat,psminlon,500.,True)
rad_kvm      = radialAvg3D(KVM_CLUBB,lat,lon,lev,psminlat,psminlon,500.,True)

rad_t = radialAvg3D(T,lat,lon,lev,psminlat,psminlon,500.,True)

rad_q = radialAvg3D(Q,lat,lon,lev,psminlat,psminlon,500.,True)


rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
nrad_rad=rad_dims(1)


rad_ustar = radialAvg2D(USTAR,lat,lon,psminlat,psminlon,500.,True)
rad_shflx= radialAvg2D(SHFLX,lat,lon,psminlat,psminlon,500.,True)
rad_lhflx = radialAvg2D(LHFLX,lat,lon,psminlat,psminlon,500.,True)
rad_tbot = radialAvg2D(T(nlev_rad-1,:,:),lat,lon,psminlat,psminlon,500.,True)

rad_tbot = rad_tbot - (29.0 + 273.15);



; find RMW
;---X is a two dimensional array dimensioned lat x lon
rad_sfc_v_theta=rad_v_theta(nlev_rad-1,:)

inds = maxind(rad_sfc_v_theta)
rad_max = rad_sfc_v_theta&radius(inds)   ; insert the longitude index into the lon coordinate variable
print("Maximum value located at, "+rad_max) 
;-------------




if (ii .eq. 0) then
  rad_kvm_all=new((/nruns,nlev_rad/),"float")
  rad_kvm_all!1 = "lev"
  rad_kvm_all&lev = rad_kvm&lev

  rad_wgts = rad_kvm&radius
  rad_wgts&radius = rad_wgts
  rad_wgts = rad_wgts * 2 * 3.14159
  rad_wgts&radius = rad_kvm&radius

  rad_v_theta_all=new((/nruns,nrad_rad/),"float")
  rad_v_theta_all!1 = "radius"
  rad_v_theta_all&radius = rad_kvm&radius

  rad_v_theta_vert=new((/nruns,nlev_rad/),"float")
  rad_v_theta_vert!1 = "lev"
  rad_v_theta_vert&lev = rad_kvm&lev

  rad_t_vert=new((/nruns,nlev_rad/),"float")
  rad_t_vert!1 = "lev"
  rad_t_vert&lev = rad_kvm&lev

  rad_q_vert=new((/nruns,nlev_rad/),"float")
  rad_q_vert!1 = "lev"
  rad_q_vert&lev = rad_kvm&lev

  rad_v_theta_avg=new((/nruns,nlev_rad/),"float")
  rad_v_theta_avg!1 = "lev"
  rad_v_theta_avg&lev = rad_kvm&lev

  rad_ustar_all=new((/nruns,nrad_rad/),"float")
  rad_ustar_all!1 = "radius"
  rad_ustar_all&radius = rad_kvm&radius

  rad_shflx_all=new((/nruns,nrad_rad/),"float")
  rad_shflx_all!1 = "radius"
  rad_shflx_all&radius = rad_kvm&radius

  rad_lhflx_all=new((/nruns,nrad_rad/),"float")
  rad_lhflx_all!1 = "radius"
  rad_lhflx_all&radius = rad_kvm&radius

  rad_tbot_all=new((/nruns,nrad_rad/),"float")
  rad_tbot_all!1 = "radius"
  rad_tbot_all&radius = rad_kvm&radius
end if

do jj = 0,nlev_rad-1
  rad_kvm_all(ii,jj) = tofloat(sum(rad_wgts({innerRad:outerRad})*rad_kvm(jj,{innerRad:outerRad}))/sum(rad_wgts({innerRad:outerRad})))
end do
delete(rad_kvm)

do jj = 0,nlev_rad-1
  rad_v_theta_avg(ii,jj) = tofloat(sum(rad_wgts({innerRad:outerRad})*rad_v_theta(jj,{innerRad:outerRad}))/sum(rad_wgts({innerRad:outerRad})))
end do

rad_ustar_all(ii,:) = tofloat(rad_ustar(:))
rad_lhflx_all(ii,:) = tofloat(rad_lhflx(:))
rad_shflx_all(ii,:) = tofloat(rad_shflx(:))
rad_tbot_all(ii,:) = tofloat(rad_tbot(:))

rad_v_theta_all(ii,:) = tofloat(rad_v_theta(nlev_rad-1,:))

rad_v_theta_vert(ii,:) = tofloat(rad_v_theta(:,{rad_max}))
rad_t_vert(ii,:) = tofloat(rad_t(:,{rad_max}))
rad_q_vert(ii,:) = tofloat(rad_q(:,{rad_max}))


delete(rad_v_theta)

end do



wks   = gsn_open_wks (out_type,"line_vert_Km_avg")                  ; send graphics to PNG file

res                   = True                       ; plot mods desired
res@trYReverse        = True                       ; reverse Y-axis

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of 
res@pmLegendParallelPosF   = .8                 ; move units right
res@pmLegendOrthogonalPosF = -0.5                ; move units down
res@pmLegendWidthF         = 0.15                ; Change width and
res@pmLegendHeightF        = 0.18                ; height of legend.
res@lgLabelFontHeightF     = .02                 ; change font height
res@lgTitleFontHeightF     = .025                ; font of legend title
res@xyExplicitLegendLabels = configs      
res@xyLineThicknessF =  5.0    
res@xyLineColors      = plot_colors
res@xyMarkLineMode = "MarkLines"               ; Markers *and* lines

res@tiMainString  = "Rad. Avg. K_m (30-200km)"             ; add title
res@tiXAxisString = "K_m (m2/s)"
res@tiYAxisString = "Pressure (mb)"
res@trYReverse        = True
plot  = gsn_csm_xy (wks,rad_kvm_all,rad_kvm_all&lev,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_vert_vtheta_avg")
res@tiMainString  = "Rad. Avg. v_theta (30-200km)"             ; add title
res@tiXAxisString = "V_theta (m/s)"
res@tiYAxisString = "Pressure (mb)"
res@trYReverse        = True
plot  = gsn_csm_xy (wks,rad_v_theta_avg,rad_v_theta_avg&lev,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_sfcwind_radial")
res@tiMainString  = "Surface wind profile"             ; add title
res@tiXAxisString = "Radius (km)"
res@tiYAxisString = "Surface wind (m/s)"
res@trYReverse        = False
plot  = gsn_csm_xy (wks,rad_v_theta_all&radius,rad_v_theta_all,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_vert_vtheta_rmw")
res@tiMainString  = "v_theta profile at RMW"             ; add title
res@tiXAxisString = "V_theta (m/s)"
res@tiYAxisString = "Pressure (mb)"
res@trYReverse        = True
plot  = gsn_csm_xy (wks,rad_v_theta_vert,rad_v_theta_vert&lev,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_vert_t_rmw")
res@tiMainString  = "T profile at RMW"             ; add title
res@tiXAxisString = "T (K)"
res@tiYAxisString = "Pressure (mb)"
res@trYReverse        = True
plot  = gsn_csm_xy (wks,rad_t_vert,rad_t_vert&lev,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_vert_q_rmw")
res@tiMainString  = "Q profile at RMW"             ; add title
res@tiXAxisString = "Q (kg/kg)"
res@tiYAxisString = "Pressure (mb)"
res@trYReverse        = True
plot  = gsn_csm_xy (wks,rad_q_vert,rad_q_vert&lev,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_ustar_radial")
res@tiMainString  = "U* profile"             ; add title
res@tiXAxisString = "Radius (km)"
res@tiYAxisString = "Friction velocity (m/s)"
res@trYReverse        = False
plot  = gsn_csm_xy (wks,rad_ustar_all&radius,rad_ustar_all,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_lhflx_radial")
res@tiMainString  = "LHFLX profile"             ; add title
res@tiXAxisString = "Radius (km)"
res@tiYAxisString = "Latent Heat Flux (W/m2)"
res@trYReverse        = False
plot  = gsn_csm_xy (wks,rad_lhflx_all&radius,rad_lhflx_all,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_shflx_radial")
res@tiMainString  = "SHFLX profile"             ; add title
res@tiXAxisString = "Radius (km)"
res@tiYAxisString = "Sensible Heat Flux (W/m2)"
res@trYReverse        = False
plot  = gsn_csm_xy (wks,rad_shflx_all&radius,rad_shflx_all,res) ; create plot
delete(plot)
delete(wks)

wks   = gsn_open_wks (out_type,"line_tbot_radial")
res@tiMainString  = "Tbot - SST profile"             ; add title
res@tiXAxisString = "Radius (km)"
res@tiYAxisString = "Lowest model lev T (K)"
res@trYReverse        = False
plot  = gsn_csm_xy (wks,rad_tbot_all&radius,rad_tbot_all,res) ; create plot
delete(plot)
delete(wks)

end
