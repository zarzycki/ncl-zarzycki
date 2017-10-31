load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

in_wrf_nm = "/glade/u/home/zarzycki/work/ReedTC_WRF/wrfinput_d01"
out_wrf_nm = "/glade/u/home/zarzycki/work/ReedTC_WRF/wrfinput_d01_new"
in_wrf = addfile(in_wrf_nm,"r")
out_wrf = addfile(out_wrf_nm,"w")

in_wrf_bdy_nm = "/glade/u/home/zarzycki/work/ReedTC_WRF/wrfbdy_d01"
out_wrf_bdy_nm = "/glade/u/home/zarzycki/work/ReedTC_WRF/wrfbdy_d01_new"
in_wrf_bdy = addfile(in_wrf_bdy_nm,"r")
out_wrf_bdy = addfile(out_wrf_bdy_nm,"w")

print("cp "+in_wrf_nm+" "+out_wrf_nm)
system("cp "+in_wrf_nm+" "+out_wrf_nm)

print("cp "+in_wrf_bdy_nm+" "+out_wrf_bdy_nm)
system("cp "+in_wrf_bdy_nm+" "+out_wrf_bdy_nm)

stride = 1 ;Set to 10 for debugging
print("Getting vars")
T_=in_wrf->T
U_=in_wrf->U
V_=in_wrf->V
Q_=in_wrf->Q

dims = dimsizes(T_)
ntime = dims(0)
nlev = dims(1)
nlat = dims(2) ; south_north
nlon = dims(3) ; west_east

; Get lons
GLON=in_wrf->GLON
GLAT=in_wrf->GLAT

PD=in_wrf->PD
PT=in_wrf->PT
PDTOP=in_wrf->PDTOP
; PSFC = PT + PDTOP + PD
; P = eta1*PDTOP + eta2*PD + PT

; get midpoint etas
AETA1=in_wrf->AETA1
AETA2=in_wrf->AETA2

; Constants
a	= 6371220.	        ; Earth's Radius (m)
Rd 	= 287.0	          ; Ideal gas const dry air (J kg^-1 K^1)
g	= 9.80616	          ; Gravity (m s^2)
omega   = 7.292115d-5 ; angular velocity 1/s
pi      = 4.*atan(1.)       ; pi
convert = 180./pi   ; conversion factor: radians to degrees
rp         = 282000.  ; Radius for calculation of PS
dp         = 1115.    ; Delta P for calculation of PS
zp         = 7000.    ; Height for calculation of P
q0         = 0.021    ; q at surface from Jordan
gamma_      = 0.007    ; lapse rate
Ts0        = 302.0   ; Surface temperature (SST)
p00        = 101500.  ; global mean surface pressure
p0         = 100000.  ; p for model level calculation
cen_lat    = 20.5      ; Center latitude of initial vortex
cen_lon    = -71.     ; Center longitufe of initial vortex
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

do i=0,nlat-1,stride ;N/S
  if (mod(i,10) .eq. 0) then
    print("doing "+i+" of 308")
  end if
  do j = 0,nlon-1,stride ;E/W
    do k = 0,nlev-1 ;k = 0 surface
 
      lat=GLAT(0,i,j)
      lon=GLON(0,i,j)
      
      f  = 2.*omega*sin(12.5/convert)           ; Coriolis parameter
      gr = a*acos(sin(cen_lat/convert)*sin(lat) + \  ; Great circle radius
           (cos(cen_lat/convert)*cos(lat)*cos(lon-cen_lon/convert)))
      
      ps = p00-dp*exp(-1*(gr/rp)^exppr) 
      
      pd = ps - PT(0) - PDTOP(0)
      
      ;p = AETA1(0,k)*PDTOP(0) + AETA2(0,k)*PD(0,i,j) + PT
      p = AETA1(0,k)*PDTOP(0) + AETA2(0,k)*pd + PT
          
      ;-----------------------------------------------------------------------
      ;    initialize PS (surface pressure of moist air)
      ;-----------------------------------------------------------------------
      
      ps = p00-dp*exp(-1*(gr/rp)^exppr) 
      
      height = (T0/gamma_)*(1.-(p/ps)^exponent)
      
      if (gr .lt. rfpi ) then
        ;print("We need to correct")
          zhere = height
          zherebefore = height
          
          do n = 1,500
          
            fpidFdz =-exppz*zhere*dp*exp(-1*(gr/rp)^exppr)*exp(-1*(zhere/zp)^exppz)/(zp*zp)*((T0-gamma_*zhere)/T0)^(g/(Rd*gamma_)) \
            +g/(Rd*T0)*(p00-dp*exp(-1*(gr/rp)^exppr)*exp(-1*(zhere/zp)^exppz))*((T0-gamma_*zhere)/T0)^(g/(Rd*gamma_)-1.)
            
            fpiF = p-(p00-dp*exp(-1*(gr/rp)^exppr)*exp(-1*(zhere/zp)^exppz)) \
               *((T0-gamma_*zhere)/T0)^(g/(Rd*gamma_))
               
            zn = zhere - fpiF/fpidFdz
            
            if ( abs(zn-zhere)/abs(zn) .lt. deltaz) then
                ;print("We are done with "+n+" iterations")
                break
            end if
            
            zhere = zn
            
            if (n .eq. 500) then
              print("FPI did not converge after 500 interations in q & T!!!")
            end if
          end do
          
          height = zn
          
          ;print("Corrected: "+zherebefore+" to: "+height)
          
      end if
      
      ;-----------------------------------------------------------------------
      ;    initialize U and V (wind components)
      ;-----------------------------------------------------------------------
      
      d1 = sin(cen_lat/convert)*cos(lat) - \
           cos(cen_lat/convert)*sin(lat)*cos(lon-cen_lon/convert)
      d2 = cos(cen_lat/convert)*sin(lon-cen_lon/convert)
      d  = max( (/ epsilon, sqrt(d1^2. + d2^2.) /) )
      ufac = d1/d
      vfac = d2/d
      if (height .gt. ztrop) then
          u = 0.
          v = 0.
      else
          ;v = vfac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
          ;    - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
          ;    /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
          ;    +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))
          v = vfac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
              - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
              /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
              +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))
          u = ufac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
              - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
              /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
              +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))
      end if
      
      ;-----------------------------------------------------------------------
      ;    set the vertical velocity to zero (only required for non-hydrostatic models)
      ;-----------------------------------------------------------------------
      
      w = 0.
      
      ;-----------------------------------------------------------------------
      ;    tracer q (specific humidity)
      ;-----------------------------------------------------------------------
      
      if (height .gt. ztrop) then
          q = qtrop
      else
          q = q0*exp(-height/zq1)*exp(-1*(height/zq2)^exppz)
      end if
          
      ;-----------------------------------------------------------------------
      ;    initialize T (temperature)
      ;-----------------------------------------------------------------------
      
      if (height .gt. ztrop) then
          t = Ttrop
      else
          t = (T0-gamma_*height)/(1.+constTv*q)/(1.+exppz*Rd*(T0-gamma_*height)*height \
              /(g*zp^exppz*(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz))))
      end if
      
      ;-----------------------------------------------------------------------
      ;    initialize PHIS (surface geopotential)
      ;-----------------------------------------------------------------------
      
      phis = 0.  ; constant
      
      ;-----------------------------------------------------------------------
      ;    initialize RHO (density of moist air)
      ;-----------------------------------------------------------------------
      
      rho = p/(Rd*t*(1.+constTv*q))
      
      
      V_(0,k,i,j) = tofloat(v)
      U_(0,k,i,j) = tofloat(u)
      Q_(0,k,i,j) = tofloat(q)
      T_(0,k,i,j) = tofloat(t)
      PD(0,i,j) = pd
          
          
          
    end do
  end do
end do




print("Writing out initial conditions")
out_wrf->V = V_
out_wrf->U = U_
out_wrf->Q = Q_
out_wrf->T = T_
out_wrf->PD = PD

print("Writing out boundary data")
; Load boundary data
PD_BXS=in_wrf_bdy->PD_BXS
PD_BXE=in_wrf_bdy->PD_BXE
PD_BYS=in_wrf_bdy->PD_BYS
PD_BYE=in_wrf_bdy->PD_BYE

printVarSummary(PD_BYS)

PD_BXS(0,0,:) = PD(0,:,0)
PD_BXE(0,0,:) = PD(0,:,0)
PD_BYS(0,0,:) = (/PD(0,0,:)/)
PD_BYE(0,0,:) = (/PD(0,0,:)/)

printVarSummary(PD_BYS)

;(Time, bdy_width, bottom_top, west_east) ;
Q_BXS=in_wrf_bdy->Q_BXS
Q_BXE=in_wrf_bdy->Q_BXE
Q_BYS=in_wrf_bdy->Q_BYS
Q_BYE=in_wrf_bdy->Q_BYE

Q_BXS(0,0,:,:) = Q_(0,:,:,0)
Q_BXE(0,0,:,:) = Q_(0,:,:,0)
Q_BYS(0,0,:,:) = Q_(0,:,0,:)
Q_BYE(0,0,:,:) = Q_(0,:,0,:)

T_BXS=in_wrf_bdy->T_BXS
T_BXE=in_wrf_bdy->T_BXE
T_BYS=in_wrf_bdy->T_BYS
T_BYE=in_wrf_bdy->T_BYE

T_BXS(0,0,:,:) = T_(0,:,:,0)
T_BXE(0,0,:,:) = T_(0,:,:,0)
T_BYS(0,0,:,:) = T_(0,:,0,:)
T_BYE(0,0,:,:) = T_(0,:,0,:)

out_wrf_bdy->PD_BXS = PD_BXS
out_wrf_bdy->PD_BXE = PD_BXE
out_wrf_bdy->PD_BYS = PD_BYS
out_wrf_bdy->PD_BYE = PD_BYE
out_wrf_bdy->Q_BXS = Q_BXS
out_wrf_bdy->Q_BXE = Q_BXE
out_wrf_bdy->Q_BYS = Q_BYS
out_wrf_bdy->Q_BYE = Q_BYE
out_wrf_bdy->T_BXS = T_BXS
out_wrf_bdy->T_BXE = T_BXE
out_wrf_bdy->T_BYS = T_BYS
out_wrf_bdy->T_BYE = T_BYE

;print(RES)
; PD - column mass in sigma domain (pressure)
;U
;T
;V
;Q

end