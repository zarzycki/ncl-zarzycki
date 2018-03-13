undef("fronto")
function fronto (theta:numeric, u:numeric, v:numeric, lat:numeric, lon:numeric, smoothn:integer, opt:integer)
;
; Compute 2-D frontogenesis function (neglect diabatic and tilting terms)
;
; INPUTS
; theta   : potential temperature (K)
; u       : zonal wind (m/s)
; v       : meridional wind (m/s)
; lat     : array of latitudes (matching input vars)
; lon     : array of longitudes (matching input vars)
; smoothn : number of smoothing passes
; opt     : derivative option. 0 -> use spherical harmonics; !=0 -> centered finite diff.
;
; NOTE: if opt = 0, lats for inputs need to be oriented S->N!
;
local dvdx, dvdy, dudy, dudx, dthdy, dthdx, mag_grad_theta, gradLatLon, XTERM, YTERM
begin

; Optional smoothing of input fields
if(smoothn.gt.0) then
  smthp=0.5
  smthq=-0.05
  do j=0,smoothn
    theta = smth9_Wrap(theta,smthp,smthq,False)
    u= smth9_Wrap(u,smthp,smthq,False)
    v= smth9_Wrap(v,smthp,smthq,False)
  end do
end if

; allocate derivatives
dvdx = v
dvdy = v
dudy = u
dudx = u
dthdx= theta
dthdy= theta

; calculate derivatives
if (opt .eq. 0) then
  gradsf(v,dvdx,dvdy)
  gradsf(u,dudx,dudy)
  gradsf(theta,dthdx,dthdy)
else
  gradLatLon = grad_latlon_cfd (theta, lat, lon, True, False)            
  dthdy = gradLatLon[0]
  dthdx = gradLatLon[1]
  delete(gradLatLon)
  gradLatLon = grad_latlon_cfd (u, lat, lon, True, False)                            
  dudy = gradLatLon[0]
  dudx = gradLatLon[1]
  delete(gradLatLon)
  gradLatLon = grad_latlon_cfd (v, lat, lon, True, False)                            
  dvdy = gradLatLon[0]
  dvdx = gradLatLon[1]
  delete(gradLatLon)
end if

; Calculate magnitude of theta gradient
mag_grad_theta = (dthdx^2.+dthdy^2.)^0.5
mag_grad_theta = where(mag_grad_theta .eq. 0.,mag_grad_theta@_FillValue,mag_grad_theta)

; Calculate x term and y term from F equation
XTERM=dthdx*(-dudx*dthdx - dvdx*dthdy)
YTERM=dthdy*(-dudy*dthdx - dvdy*dthdy)

; Calc frontogenesis, set metadata
frontogenesis = (1/mag_grad_theta) * (XTERM + YTERM)
frontogenesis = frontogenesis*10800.*100000.
frontogenesis@_FillValue = -999.
copy_VarCoords(u,frontogenesis)
frontogenesis@units = "K/100 km/3 hr"
frontogenesis@long_name = "Horizontal frontogenesis"

return(frontogenesis)

end
