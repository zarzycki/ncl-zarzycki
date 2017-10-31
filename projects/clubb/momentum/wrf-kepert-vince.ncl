; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "../../radial_plots/radialAvg.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/zarzycki/ncl/functions/bearing.ncl"

begin


out_type="pdf"

plot_vickery=True
plot_blackadar=True
plot_log_ref=False
plot_10m=False

filename="/glade/scratch/zarzycki/wrfout_d01_2005-08-28_00-00-00.nc"
;filename="/glade/scratch/zarzycki/wrfout_d01_2005-08-28_00-00-00_default.nc"
thefile = addfile(filename,"r")
basename = systemfunc("basename "+filename)
print("basename is: "+basename)

stride = 1
timeStep=20

xlat = thefile->XLAT(0,:,:)
xlon = thefile->XLONG(0,:,:)
xlev = thefile->ZNU(0,:)
xlevi = thefile->ZNW(0,:)
xlat_v=thefile->XLAT_V(0,:,:)
xlon_v=thefile->XLONG_V(0,:,:)
xlat_u=thefile->XLAT_U(0,:,:)
xlon_u=thefile->XLONG_U(0,:,:)

nlev=dimsizes(xlev)
nlevi=dimsizes(xlevi)

print(max(xlat))
print(min(xlat))
print(max(xlon))
print(min(xlon))
;
;lat -- need to gen
;lon -- need to gen
;lev 
;17 26.4241 -88.2941
;18 26.6635 -88.2469
;19 26.6635 -88.5481
;20
;21 26.8648 -88.749
;22 26.8648 -88.749

DIST = gc_latlon(26.4241,-88.2941,26.8648,-88.749,2,3)
BEARING = bearing(26.4241,-88.2941,26.8648,-88.749)
SPEED = DIST/(6.*3600.)
print(SPEED+" "+BEARING)
d2r=3.14159/180.
UMOVE = SPEED*sin(BEARING*d2r)
VMOVE = SPEED*cos(BEARING*d2r)

lat = fspan(16.5,32.5,80)
lat!0="lat"
lat&lat=lat
;lon = fspan(-77.,-101.,120)
lon = fspan(-101.,-77.,120)
lon!0="lon"
lon&lon=lon

nlat=dimsizes(lat)
nlon=dimsizes(lon)

; P on mid, Z on stag
P0=thefile->P00

U_WRF = thefile->U(timeStep,:,:,:)
V_WRF = thefile->V(timeStep,:,:,:)
;U_WRF = U_WRF-UMOVE
;V_WRF = V_WRF-VMOVE
W_WRF = thefile->W(timeStep,:,:,:)
P_WRF = thefile->P(timeStep,:,:,:)
PB_WRF = thefile->PB(timeStep,:,:,:)
PRES_WRF = P_WRF
PRES_WRF = P_WRF + PB_WRF
SLP_WRF = wrf_user_getvar(thefile,"slp",timeStep)


U  = rcm2rgrid(xlat_u,xlon_u,U_WRF,lat,lon,0)
V  = rcm2rgrid(xlat_v,xlon_v,V_WRF,lat,lon,0)
WINT  = rcm2rgrid(xlat,xlon,W_WRF,lat,lon,0)
PRES  = rcm2rgrid(xlat,xlon,PRES_WRF,lat,lon,0)
SLP= rcm2rgrid(xlat,xlon,SLP_WRF,lat,lon,0)

U!0="lev"
U!1="lat"
U!2="lon"
U&lat=lat
U&lon=lon
U@units="m/s"
copy_VarCoords(U,V)

SLP!0="lat"
SLP!1="lon"
SLP&lat=lat
SLP&lon=lon

PH = thefile->PH(timeStep,:,:,:)
PHB = thefile->PHB(timeStep,:,:,:)
ZINT_WRF = PH
ZINT_WRF = PH + PHB
ZINT_WRF = ZINT_WRF / 9.81
ZINT_WRF@units="m"

ZINT = rcm2rgrid(xlat,xlon,ZINT_WRF,lat,lon,0)

Z = new((/nlev,nlat,nlon/),"float")
Z(:,:,:) = (ZINT(0:nlevi-2,:,:) + ZINT(1:nlevi-1,:,:)) / 2.
Z@units="m"

W = new((/nlev,nlat,nlon/),"float")
W(:,:,:) = (WINT(0:nlevi-2,:,:) + WINT(1:nlevi-1,:,:)) / 2.
WINT@units="m/s"


PS1 = SLP





;---FIND LOCATIONS OF PSMIN and WINDMAX
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
a_indices  = ind_resolve(minind(a1D),dsizes_a)
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))
print(psminlat+" "+psminlon)

; calculate radial stuff
vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon,-1,-1)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

v_theta = where(ismissing(v_theta),0.0,v_theta)
v_rad = where(ismissing(v_rad),0.0,v_rad)
W = where(ismissing(W),0.0,W)

if (1.eq.1) then
system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file
filedimdef(ncdf,"time",-1,True) 

ncdf->U  = U                         ; 4D               
ncdf->V = V                         ; 3D 
ncdf->SLP = SLP
ncdf->v_theta = v_theta
ncdf->v_rad = v_rad
end if


; generate Zlev
Zlev = fspan(10.,4500.,250)
;Zlev = (/50.,100.,150.,200.,250.,300.,350.500.,750.,1000.,2000.,3000.,4000.,5000.,10000./)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

interp_type=0
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
W_Z        = int2p_n_Wrap(Z,W,Zlev,interp_type,0)

; do radial integrals
rad_v_theta  = radialAvg3D(v_theta_Z,lat,lon,Zlev,psminlat,psminlon,300.,True)
rad_v_rad    = radialAvg3D(v_rad_Z,lat,lon,Zlev,psminlat,psminlon,300.,True)
rad_v_rad = -rad_v_rad  ; NEGATIVE FOR CONVENTION
rad_W        = radialAvg3D(W_Z,lat,lon,Zlev,psminlat,psminlon,300.,True)

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



wks   = gsn_open_wks (out_type,"radial_panel_"+basename)
npanels=6
plot = new(npanels,"graphic")

; universal settings
res= True       
res@gsnDraw = False
res@gsnFrame = False
res@trYMinF           = 10.
res@trYMaxF           = 4000.

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

print(rad_v_theta_vert)

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
resP@txString = basename

;resP@amJust           = "TopLeft"
;resP@gsnPanelFigureStringsFontHeightF = 0.014
;resP@gsnPanelFigureStrings= (/"T12","G16","T12-G16"/)

gsn_panel(wks,plot,(/3,2/),resP)

end
