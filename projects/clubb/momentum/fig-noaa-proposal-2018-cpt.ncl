; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "../../../functions/radialAvg.ncl"

begin

out_type="pdf"
configs=(/"RCE.QPC6.ne0np4tcfplane.ne15x8.exp999","RCE.QPC6.ne0np4tcfplane.ne15x8.exp997"/)

wks   = gsn_open_wks (out_type,"cam_TC_diags")
npanels=6
plot = new(npanels,"graphic")

do zz = 0,1

config=configs(zz)
ncdf=addfile("./netcdf/"+config+".AVG.nc","r")
rad_v_theta=ncdf->rad_v_theta
rad_v_rad=ncdf->rad_v_rad
rad_v_rad=ncdf->rad_v_rad
rad_W=ncdf->rad_W

rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
pi=3.14159
Zlev=rad_v_theta&lev
plot_vickery=False
plot_blackadar=False
plot_log_ref=False
plot_10m=True
plot_K_ref=False

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

; find surface inflow angle
do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(0,ii))) then
    sfc_inflow_ang=atan(rad_v_rad_vert(0,ii)/rad_v_theta_vert(0,ii))*180./pi
    sfc_radial_flow=abs(rad_v_rad_vert(1,ii))
    break
  else
    print("Missing value in search for lowest model level...")
  end if
end do

do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(1,ii))) then
    if (abs(rad_v_rad_vert(1,ii)) .ge. 0.1*sfc_radial_flow) then
      print("Searing for inflow depth -- at z: "+Zlev(ii)+" "+rad_v_rad_vert(1,ii)+" compared to: "+(0.1*sfc_radial_flow))
      inflow_depth=Zlev(ii)
    else
      print("Breaking -- at z: "+Zlev(ii)+" "+rad_v_rad_vert(1,ii)+" compared to: "+(0.1*sfc_radial_flow))
      break
    end if
  else
    print("Missing value in search for inflow depth...")
  end if
end do

z_jet_max=0.
jet_max=-100.
do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(1,ii))) then
    if (rad_v_theta_vert(0,ii) .ge. jet_max) then
      jet_max = rad_v_theta_vert(0,ii)
      z_jet_max = Zlev(ii)
    end if
  else
    print("Missing value in search for inflow depth...")
  end if
end do

print("-------------------------------------------------------------------")
print("surface inflow angle: "+abs(sfc_inflow_ang))
print("inflow depth: "+inflow_depth+" "+Zlev@units)
print("jet max location: "+z_jet_max)

print("-------------------------------------------------------------------")

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
  ;print(log_wind_profile+" "+Zlev)

  z_0=0.0002
  do ii = 0,dimsizes(log_wind_profile)-1
    log_wind_profile(ii) = rad_v_theta_vert(0,{70.0})*(1 + log(Zlev(ii)/70.0)/log(70.0/z_0) )
  end do

  k_profile = tofloat(rad_KVM_vert(0,:))
  
  print("ustar_rmw "+ustar_rmw)
  do ii = 0,dimsizes(k_profile)-1
    k_profile(ii) = K*ustar_rmw*Zlev(ii)
  end do

  print(k_profile+" "+Zlev)

end if

; PLOTTING



; universal settings
res= True       
res@gsnDraw = False
res@gsnFrame = False
res@trYMinF           = 30.
res@trYMaxF           = 3000.

res@xyLineThicknessF = 3.0

res@tiXAxisFontHeightF=0.03
res@tiYAxisFontHeightF=0.03

res@xyDashPatterns = (/0,16/)


res@tiMainString  = ""
res@tiXAxisString = ""
res@tiYAxisString = ""
if (zz .eq. 0) then
  res@tiMainString  = "Radial Flow"
end if
if (zz .eq. 1) then 
  res@tiXAxisString = "V~B~r~N~ (m/s)"
end if
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = -25.
res@trXMaxF           = 10.
plot(0+(zz*3)) = gsn_csm_xy (wks,rad_v_rad_vert(:,:),Zlev(:),res)
zlineres = True
zlineres@gsLineColor = "gray"
zlineres@gsLineThicknessF = 1.0
dummy_vert1 = gsn_add_polyline(wks,plot(0),(/0,0/),(/1,100000/),zlineres)
dummy_vert2 = gsn_add_polyline(wks,plot(3),(/0,0/),(/1,100000/),zlineres)

; add inflow depth annotation
txres                       = True
txres@txFontHeightF         = 0.025
txid = gsn_create_text(wks, "inflow depth: "+inflow_depth+Zlev@units, txres)
amres = True
amres@amParallelPosF   = -0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = -0.48    ; This is the bottom edge of the plot.
amres@amJust           = "TopLeft"
annoid = gsn_add_annotation(plot(0+(zz*3)), txid, amres)

; add inflow angle annotation
txres                       = True
txres@txFontHeightF         = 0.025
txid = gsn_create_text(wks, "sfc inflow ang: "+abs(sfc_inflow_ang)+"deg", txres)
amres = True
amres@amParallelPosF   = 0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = 0.48    ; This is the bottom edge of the plot.
amres@amJust           = "BottomRight"
annoid = gsn_add_annotation(plot(0+(zz*3)), txid, amres)

res@tiMainString  = ""
res@tiXAxisString = ""
res@tiYAxisString = ""
if (zz .eq. 0) then
  res@tiMainString  = "Azimuthal Flow"
end if
if (zz .eq. 1) then
  res@tiXAxisString = "V~F33~~B~q~N~~F21~ (m/s)"
end if
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 30.
res@trXMaxF           = 65.
plot(1+(zz*3)) = gsn_csm_xy (wks,rad_v_theta_vert(:,:),Zlev(:),res)

zlineres@gsLineColor = "red"
zlineres@gsLineThicknessF = 2.0
if (zz .eq. 0) then
  dummy_vert3 = gsn_add_polyline(wks,plot(1),(/-100000,100000/),(/z_jet_max,z_jet_max/),zlineres)
else
  dummy_vert4 = gsn_add_polyline(wks,plot(4),(/-100000,100000/),(/z_jet_max,z_jet_max/),zlineres)
end if

; add RMW annotation
txres                       = True
txres@txFontHeightF         = 0.025
txid = gsn_create_text(wks, "RMW: "+rad_max+"km", txres)
amres = True
amres@amParallelPosF   = -0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = -0.48    ; This is the bottom edge of the plot.
amres@amJust           = "TopLeft"
annoid = gsn_add_annotation(plot(1+(zz*3)), txid, amres)

; add inflow angle annotation
txres                       = True
txres@txFontHeightF         = 0.025
txid = gsn_create_text(wks, "HMW: "+z_jet_max+"m", txres)
amres = True
amres@amParallelPosF   = 0.48    ; This is the right edge of the plot.
amres@amOrthogonalPosF = 0.48    ; This is the bottom edge of the plot.
amres@amJust           = "BottomRight"
annoid = gsn_add_annotation(plot(1+(zz*3)), txid, amres)


if (plot_vickery)
  resover=True
  resover=res
  resover@xyLineColor="red"
  ;plot11 = gsn_csm_xy (wks,data1x,data1y,resover)
  ;overlay(plot(1),plot11)
  ;plot21 = gsn_csm_xy (wks,data2x,data2y,resover)
  ;overlay(plot(1),plot21)
  plot31 = gsn_csm_xy (wks,data3x,data3y,resover)
  overlay(plot(1+(zz*3)),plot31)
  plot41 = gsn_csm_xy (wks,data4x,data4y,resover)
  overlay(plot(1+(zz*3)),plot41)
  plot51 = gsn_csm_xy (wks,data5x,data5y,resover)
  overlay(plot(1+(zz*3)),plot51)
  plot61 = gsn_csm_xy (wks,data6x,data6y,resover)
  overlay(plot(1+(zz*3)),plot61)
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

res@tiMainString  = ""
res@tiXAxisString = ""
res@tiYAxisString = ""
if (zz .eq. 0) then
  res@tiMainString  = "Vertical Flow"
end if
if (zz .eq. 1) then
  res@tiXAxisString = "w (m/s)"
end if
res@tiYAxisString = "Height (m)"
res@xyYStyle          = "Log"
res@trXMinF           = 0.
res@trXMaxF           = 0.75
plot(2+(zz*3)) = gsn_csm_xy (wks,rad_W_vert(:,:),Zlev(:),res)

end do

resP = True


fig_strs = (/"a","b","c","d","e","f"/) + "."
resP@gsnPanelFigureStrings = fig_strs
resP@amJust = "BottomLeft"
gsn_panel(wks,plot,(/2,3/),resP)
delete(res)
delete(resP)


end

