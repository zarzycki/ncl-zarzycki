; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "../../radial_plots/radialAvg.ncl"

begin


out_type="pdf"

plot_vickery=True
plot_blackadar=True
plot_log_ref=False
plot_10m=False


filename = "/glade/scratch/zarzycki/test_regrid_h2.nc"


thefile = addfile(filename,"r")


stride = 1
topLev = 0.1
botLev = 1050.
maxLat=0.
minLat=45.
timeStep=86

lat = thefile->lat({maxLat:minLat:stride})
lon = thefile->lon(::stride)
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"
hyam=thefile->hyam({topLev:botLev})
hybm=thefile->hybm({topLev:botLev})
hyai=thefile->hyai({topLev:botLev})
hybi=thefile->hybi({topLev:botLev})
P0=thefile->P0

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

U = thefile->U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
V = thefile->V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
PS1 = thefile->PSL(timeStep,{maxLat:minLat:stride},::stride)
PSFC = thefile->PS(timeStep,{maxLat:minLat:stride},::stride)
T = thefile->T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
Q = thefile->Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)

OMEGA = omega_ccm_driver(P0,PSFC,U,V,hyam,hybm,hyai,hybi)

PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)

W = omega_to_w(OMEGA, PRES, T)         ; w (m/s)

;---FIND LOCATIONS OF PSMIN and WINDMAX
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
a_indices  = ind_resolve(minind(a1D),dsizes_a)
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))

print(min(PS1)+" "+psminlat+" "+psminlon)

; calculate radial stuff
vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon,-1,-1)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

; get Z from hybrid levels
TV=T*(1.+0.61*Q) 
PHIS=PS1
PHIS=0.0
Z = cz2ccm(PS1,PHIS,TV,P0,hyam(::-1),hybm(::-1),hyai(::-1),hybi(::-1))
Z@units="m"

; generate Zlev
Zlev = fspan(10.,3000.,250)
;Zlev = (/50.,100.,150.,200.,250.,300.,350.500.,750.,1000.,2000.,3000.,4000.,5000.,10000./)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

printVarSummary(W)

interp_type=1
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
W_Z        = int2p_n_Wrap(Z,W,Zlev,interp_type,0)


; do radial integrals
rad_v_theta  = radialAvg3D(v_theta_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad    = radialAvg3D(v_rad_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad = -rad_v_rad  ; NEGATIVE FOR CONVENTION
rad_W        = radialAvg3D(W_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)


rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
nrad_rad=rad_dims(1)

; find RMW
rad_sfc_v_theta=rad_v_theta({70.},:)
inds = maxind(rad_sfc_v_theta)
rad_max = rad_sfc_v_theta&radius(inds)   ; insert the longitude index into the lon coordinate variable
print("Maximum value located at, "+rad_max)
rad_max_2x = rad_max*2

rad_v_theta_vert=new((/2,nlev_rad/),"float")
rad_v_theta_vert!1 = "lev"
rad_v_theta_vert&lev = rad_v_theta&lev

rad_v_rad_vert = rad_v_theta_vert
rad_W_vert     = rad_v_theta_vert



rad_v_theta_vert(0,:) = tofloat(rad_v_theta(:,{rad_max}))
rad_v_rad_vert(0,:) = tofloat(rad_v_rad(:,{rad_max}))
rad_W_vert(0,:) = tofloat(rad_W(:,{rad_max}))



rad_v_theta_vert(1,:) = tofloat(rad_v_theta(:,{rad_max_2x}))
rad_v_rad_vert(1,:) = tofloat(rad_v_rad(:,{rad_max_2x}))
rad_W_vert(1,:) = tofloat(rad_W(:,{rad_max_2x}))



; LOAD DATA

if (plot_vickery)
  txtdata = "txtdata/vickery2009.csv"
  dlines = asciiread(txtdata,-1,"string")
  delim = ","
  dwind  = tofloat(str_get_field(dlines,1,delim))
  dhgt   = tofloat(str_get_field(dlines,2,delim))
  data1x=dwind(0:35)
  data1y=dhgt(0:35)
  data2x=dwind(36:71)
  data2y=dhgt(36:71)
  data3x=dwind(72:117)
  data3y=dhgt(72:117)
  data4x=dwind(118:159)
  data4y=dhgt(118:159)
  data5x=dwind(160:205)
  data5y=dhgt(160:205)
  data6x=dwind(206:248)
  data6y=dhgt(206:248)
end if

if(plot_blackadar)
  vonKar=0.4  ; vonKarman
  linf = 80.0
  blackadar = (vonKar*Zlev)^(-1.0) + linf^(-1.0)
  blackadar = blackadar^(-1.0)
end if

if(plot_10m)
  factor = surfaceWindCorrFactor(70.0,-1,"log")
  U10=factor*rad_v_theta_vert(0,{70.0})
  print(U10)
  print(rad_v_theta_vert(0,{70.0}))
end if

if(plot_log_ref)
  USTAR = tf2->USTAR(timeStep,{maxLat:minLat:stride},::stride)
  rad_ustar = radialAvg2D(USTAR,lat,lon,psminlat,psminlon,500.,True)
  ustar_rmw = tofloat(rad_ustar({rad_max}))

  log_wind_profile = tofloat(rad_v_rad_vert(0,:))

  K = 0.4
  c4=0.0027
  c5=0.000142
  c6=0.0000764
  ;z_0 = 10 * exp( -K * (c4/U10 + c5 + c6*U10)^(-1) )
  ;print(z_0)
  z_0 = 0.015*ustar_rmw*ustar_rmw/9.81
  print(z_0)
  ;z_0=0.0002

  ;z_0 = 0.0002
  ;cdn = .0027/U10 + .000142 + .0000764 U10

  do ii = 0,dimsizes(log_wind_profile)-1
    log_wind_profile(ii) = ustar_rmw/K * log(Zlev(ii)/z_0)
  end do
  print(log_wind_profile+" "+Zlev)

  z_0=0.0002
  do ii = 0,dimsizes(log_wind_profile)-1
    log_wind_profile(ii) = rad_v_theta_vert(0,{70.0})*(1 + log(Zlev(ii)/70.0)/log(70.0/z_0) )
  end do


end if

; PLOTTING



wks   = gsn_open_wks (out_type,"panel_asd")
npanels=6
plot = new(npanels,"graphic")

; universal settings
res= True       
res@gsnDraw = False
res@gsnFrame = False
res@trYMinF           = 10.
res@trYMaxF           = 2500.

res@tiMainString  = "Radial Flow"
res@tiXAxisString = "V_rad (m/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = -25.
res@trXMaxF           = 10.
plot(0) = gsn_csm_xy (wks,rad_v_rad_vert(:,:),Zlev(:),res)
zlineres = True
zlineres@gsLineColor = "gray"
zlineres@gsLineThicknessF = 1.0
dummy_vert = gsn_add_polyline(wks,plot(0),(/0,0/),(/1,100000/),zlineres)

if(0.eq.0) then
res@tiMainString  = "Azimuthal Flow"
res@tiXAxisString = "V_theta (m/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 20.
res@trXMaxF           = 80.
plot(1) = gsn_csm_xy (wks,rad_v_theta_vert(:,:),Zlev(:),res)

if (plot_vickery)
  resover=True
  resover=res
  resover@xyLineColor="red"
  ;plot1 = gsn_csm_xy (wks,data1x,data1y,resover)
  ;overlay(plot(1),plot1)
  ;plot2 = gsn_csm_xy (wks,data2x,data2y,resover)
  ;overlay(plot(1),plot2)
  plot3 = gsn_csm_xy (wks,data3x,data3y,resover)
  overlay(plot(1),plot3)
  plot4 = gsn_csm_xy (wks,data4x,data4y,resover)
  overlay(plot(1),plot4)
  plot5 = gsn_csm_xy (wks,data5x,data5y,resover)
  overlay(plot(1),plot5)
  plot6 = gsn_csm_xy (wks,data6x,data6y,resover)
  overlay(plot(1),plot6)
  delete(resover)
end if

if (plot_log_ref)
  resover=True
  resover=res
  resover@xyLineColor="blue"
  plot19 = gsn_csm_xy (wks,log_wind_profile,Zlev,resover) ; create plot
  overlay(plot(1),plot19)
  delete(resover)
end if

res@tiMainString  = "Vertical Flow"
res@tiXAxisString = "W (m/s)"
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 0.6
plot(2) = gsn_csm_xy (wks,rad_W_vert(:,:),Zlev(:),res)

end if

resP = True
resP@txString = "test"

;resP@amJust           = "TopLeft"
;resP@gsnPanelFigureStringsFontHeightF = 0.014
;resP@gsnPanelFigureStrings= (/"T12","G16","T12-G16"/)

gsn_panel(wks,plot,(/3,2/),resP)

end
