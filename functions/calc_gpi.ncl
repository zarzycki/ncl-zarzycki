function calc_gpi(U850,V850,U200,V200,RH600,SST,lat,lon)

;========================================================
; All variables must be lat/lon
;========================================================

begin

; constants
omega = 7.2921e-5
pi = 3.1415926

; Force RH below 100%
RH600 = RH600 < 100

; Calculate wind shear
USHEAR = U850
VSHEAR = V850
USHEAR = U850 - U200
VSHEAR = V850 - V200
TOTSHEAR = U850
TOTSHEAR = sqrt(USHEAR^2 + VSHEAR^2)

; Calculate relative vorticity
VR850 = V850
VR850 = uv2vrF_Wrap(U850,V850)
;VR850 = uv2vr_cfd(U850,V850,lat,lon,2)

AVR850 = VR850
do i = 0,dimsizes(lat)-1
  do j = 0,dimsizes(lon)-1
    AVR850(i,j) = VR850(i,j) + tofloat(2*omega*sin(lat(i)*(pi/180.)))
  end do
end do

; Calculate MPI
A = 28.2
B = 55.8
C = 0.1813
VPOT = V850
VPOT(:,:) = A + B * exp(C*(SST(:,:)-303.15))

GPI = VPOT
GPI(:,:) = abs(1e5*AVR850(:,:))^(3/2) * (RH600(:,:)/50)^(3) * (VPOT(:,:)/70)^(3) * (1 + 0.1*TOTSHEAR(:,:))^(-2)

return(GPI)

end

