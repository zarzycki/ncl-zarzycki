load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

numlevels=30
dycore="se"   ; fv or se
P0 = 100000.

wcStrt = systemfunc("date")

print("---------------------------------------------------------")
print("Loading CAM levels")
if (numlevels .eq. 30)
  print("Loading 30 level data")
  fC   = addfile ("./L30template.nc", "r")
else if (numlevels .eq. 32)
  print("Loading 32 level data")
  fC   = addfile ("./L32template.nc", "r")
else if (numlevels .eq. 26)
  print("Loading 26 level data")
  fC   = addfile ("./L26template.nc", "r")
else if (numlevels .eq. 59)
  print("Loading 59 level data")
  fC   = addfile ("./L59template.nc", "r")
else
  print("Bad numlevs, exiting...")
  exit
end if
end if
end if
end if
hya  = fC->hyam
hyb  = fC->hybm
hyai  = fC->hyai
hybi  = fC->hybi
lev = fC->lev
ilev = fC->ilev

nlev=dimsizes(lev)

fH = addfile("/glade/u/home/zarzycki/work/grids/latlon/uniform_15_template.nc","r")

selat = fH->lat
selon = fH->lon
ncol = dimsizes(selat)

V_ = new((/1,nlev,ncol/),"double")
U_ = new((/1,nlev,ncol/),"double")
Q_ = new((/1,nlev,ncol/),"double")
T_ = new((/1,nlev,ncol/),"double")
PD = new((/1,ncol/),"double")

;=======================================================================================================================================

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
cen_lat    = 10.0      ; Center latitude of initial vortex
cen_lon    = 0.0     ; Center longitufe of initial vortex
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

do ii=0,ncol-1
    print("doing "+ii+" of "+ncol)
    do k = 0,nlev-1
 
      lat=selat(ii)
      lon=selon(ii)

      
      f  = 2.*omega*sin(lat/convert)           ; Coriolis parameter
      gr = a*acos(sin(cen_lat/convert)*sin(lat/convert) + \  ; Great circle radius
           (cos(cen_lat/convert)*cos(lat/convert)*cos(lon/convert-cen_lon/convert)))
    
      ; calculate pressures
      ps = p00-dp*exp(-1*(gr/rp)^exppr) 
            ;print(lat+" "+lon+" "+ps)
      p = hya(k)*P0 + hyb(k)*ps
      
      height = (T0/gamma_)*(1.-(p/ps)^exponent)
      print(height+"")
      
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
      
      d1 = sin(cen_lat/convert)*cos(lat/convert) - \
           cos(cen_lat/convert)*sin(lat/convert)*cos(lon/convert-cen_lon/convert)
      d2 = cos(cen_lat/convert)*sin(lon/convert-cen_lon/convert)
      d  = max( (/ epsilon, sqrt(d1^2. + d2^2.) /) )
      ufac = d1/d
      vfac = d2/d
      if (height .gt. ztrop) then
          u = todouble(0.)
          v = todouble(0.)
      else
;          v = vfac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
;              - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
;              /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
;              +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))
;          u = ufac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
;              - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
;              /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
;              +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))

        v = vfac*(-f*gr/2.+sqrt((f*gr/2)^(2) &
            - exppr*(gr/rp)**exppr*Rd*(T0-gamma*height) &
            /(exppz*height*Rd*(T0-gamma*height)/(g*zp**exppz) &
            +(1-p00/dp*exp((gr/rp)**exppr)*exp((height/zp)**exppz)))))

        u = ufac*(-f*gr/2+sqrt((f*gr/2)**(2) &
            - exppr*(gr/rp)**exppr*Rd*(T0-gamma*height) &
            /(exppz*height*Rd*(T0-gamma*height)/(g*zp**exppz) &
            +(1-p00/dp*exp((gr/rp)**exppr)*exp((height/zp)**exppz)))))


      end if
      
      ;-----------------------------------------------------------------------
      ;    set the vertical velocity to zero (only required for non-hydrostatic models)
      ;-----------------------------------------------------------------------
      
      w = 0.
      
      ;-----------------------------------------------------------------------
      ;    tracer q (specific humidity)
      ;-----------------------------------------------------------------------
      
      if (height .gt. ztrop) then
          q = todouble(qtrop)
      else
          q = q0*exp(-height/zq1)*exp(-1*(height/zq2)^exppz)
      end if
          
      ;-----------------------------------------------------------------------
      ;    initialize T (temperature)
      ;-----------------------------------------------------------------------
      
      if (height .gt. ztrop) then
          t = todouble(Ttrop)
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
      
      
      V_(0,k,ii) = v
      U_(0,k,ii) = u
      Q_(0,k,ii) = q
      T_(0,k,ii) = t
      PD(0,ii) = ps
          
    end do
end do





PD!0 = "time"
PD!1 = "ncol"
U_!0 = "time"
U_!1 = "lev"
U_!2 = "ncol"
V_!0 = "time"
V_!1 = "lev"
V_!2 = "ncol"
T_!0 = "time"
T_!1 = "lev"
T_!2 = "ncol"
Q_!0 = "time"
Q_!1 = "lev"
Q_!2 = "ncol"

selat!0 = "ncol"
selon!0 = "ncol"


print("Writing output file")

se_inic="./INIC.nc"
system("/bin/rm -f "+se_inic)   ; remove any pre-existing file
in2 = addfile(se_inic,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( in2, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(in2,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================
in2->PS=PD
in2->U=U_
in2->V=V_
in2->T=T_
in2->Q=Q_
in2->hyam  = hya
in2->hybm  = hyb
in2->hyai  = hyai
in2->hybi  = hybi
in2->lev = lev
in2->ilev = ilev

in2->lat=selat
in2->lon=selon

status_exit(9)
  
end


