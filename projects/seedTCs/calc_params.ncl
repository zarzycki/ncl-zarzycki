; Constants
a	= 6371220.	        ; Earth's Radius (m)
Rd 	= 287.0	          ; Ideal gas const dry air (J kg^-1 K^1)
g	= 9.80616	          ; Gravity (m s^2)
omega   = 7.292115d-5 ; angular velocity 1/s
pi      = 4.*atan(1.)       ; pi
convert = 180./pi   ; conversion factor: radians to degrees

zp         = 7000.    ; Height for calculation of P
q0         = 0.021    ; q at surface from Jordan
gamma_      = 0.007    ; lapse rate
Ts0        = 302.0   ; Surface temperature (SST)
p00        = 101500.  ; global mean surface pressure
p0         = 100000.  ; p for model level calculation
;cen_lat    = 20.      ; Center latitude of initial vortex
;cen_lon    = -40.     ; Center longitufe of initial vortex
zq1        = 3000.    ; Height 1 for q calculation
zq2        = 8000.    ; Height 2 for q calculation
exppr      = 1.5      ; Exponent for r dependence of p
exppz      = 2.       ; Exponent for z dependence of p
ztrop      = 15000.   ; Tropopause Height
qtrop      = 1.e-11     ; Tropopause specific humidity
rfpi       = 1000000. ; Radius within which to use fixed-point iter.
constTv    = 0.608    ; Constant for Virtual Temp Conversion
deltaz     = 2.e-5     ; Small number to ensure convergence in FPI
epsilon    = 1.e-25     ; Small number to aviod dividing by zero in wind calc
exponent = Rd*gamma_/g   ; exponent
T0    = Ts0*(1.+constTv*q0)   ; Surface temp
Ttrop = T0 - gamma_*ztrop     ; Tropopause temp
ptrop = p00*(Ttrop/T0)^(1./exponent); Tropopause pressure

; We can tweak these!
rpi         = 200000.  ; Radius for calculation of PS
dp         = 5800.    ; Delta P for calculation of PS

fc  = 2.*omega*sin(10./convert)           ; Coriolis parameter

target_rmw = 50000.

step = 5000.

do jj = 0,1000

  rp = rpi

  ; define initial arrays
  rr = fspan(0.,1000000.,10000+1)
  vt = rr
  vt = 0.

  ; find RMW
  do ii = 0,dimsizes(rr)-1
    r = rr(ii)
    T1 = - (fc * r) / 2.
    T2 =  (fc*fc*r*r / 4.)
    NUM = (3./2.)* ((r/rp)^(3./2.)) * T0 * Rd
    DEN = 1. - (p00/dp)*exp((r/rp)^(3./2.))
    vt(ii) = tofloat ( T1 + sqrt( T2 - (NUM / DEN) ) )
  end do

  vmax = max(vt)
  rmw = rr(maxind(vt))

  err_here = rmw - target_rmw
  
  if (jj .ne. 0) then
    if (erri * err_here .lt. 0) then
      step = step/2.
    end if
  end if

  ; update error
  erri = err_here
  if (abs(erri) .lt. 200) then
    break
  end if

  print(rpi+" "+rmw+" "+target_rmw+" "+abs(erri))

  ; if not break, update rpi
  if (err_here .ge. 0) then
    rpi = rpi - step
    ; make rp smaller
  else
    rpi = rpi + step
    ; make rp bigger
  end if
  
end do

print("dp="+dp)
print("rp="+rpi)

;print(rr+" "+vt)

wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file
res                  = True                     ; plot mods desired
res@tiMainString     = "Basic XY plot"          ; add title
plot  = gsn_csm_xy (wks,rr,vt,res) ; create plot