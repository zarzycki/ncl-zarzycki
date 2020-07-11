begin

ENS="001"
res="ne15x16"
numlevels=56

; perturbation values
rseed1 = toint(systemfunc(" date +%s"))
rseed2 = toint((12345l*rseed1)%2147483398l)
random_setallseed(rseed1, rseed2)
latpert=random_uniform(-0.1d0,0.1d0,1)
lonpert=random_uniform(-0.1d0,0.1d0,1)
dppert =random_uniform(-5.d0,5.d0,1)
rppert =random_uniform(-1000.d0,1000.d0,1)

logname = getenv("LOGNAME")

dycore="se"   ; fv or se
P0 = 100000.d

wcStrt = systemfunc("date")

print("---------------------------------------------------------")

fC   = addfile ("./L"+tostring(numlevels)+"template.nc", "r")

hya  = fC->hyam
hyb  = fC->hybm
hyai  = fC->hyai
hybi  = fC->hybi
lev = fC->lev
ilev = fC->ilev

nlev=dimsizes(lev)

fH = addfile("/glade/work/zarzycki/grids/latlon/ne0np4tcfplane."+res+"_template.nc","r")

selat = fH->lat
selon = fH->lon
ncol = dimsizes(selat)

V_ = new((/1,nlev,ncol/),"double")
U_ = new((/1,nlev,ncol/),"double")
Q_ = new((/1,nlev,ncol/),"double")
T_ = new((/1,nlev,ncol/),"double")
PD = new((/1,ncol/),"double")

;========================================================================================================================================

; Constants
a	= 6371220.d0	        ; Earth's Radius (m)
Rd 	= 287.0d0	          ; Ideal gas const dry air (J kg^-1 K^1)
g	= 9.80616d0	          ; Gravity (m s^2)
omega   = 7.292115d-5 ; angular velocity 1/s
pi      = 4.d0*atan(1.)       ; pi
convert = 180./pi   ; conversion factor: radians to degrees
rp         = 282000.d0  ; Radius for calculation of PS
dp         = 1115.d0    ; Delta P for calculation of PS
zp         = 7000.d0    ; Height for calculation of P
q0         = 0.021d0    ; q at surface from Jordan
gamma_      = 0.007d0    ; lapse rate
Ts0        = 302.0d0   ; Surface temperature (SST)
p00        = 101500.d0  ; global mean surface pressure
p0         = 100000.d0  ; p for model level calculation
cen_lat    = 0.0d0      ; Center latitude of initial vortex
cen_lon    = 0.0d0     ; Center longitufe of initial vortex
zq1        = 3000.d0    ; Height 1 for q calculation
zq2        = 8000.d0    ; Height 2 for q calculation
exppr      = 1.5d0      ; Exponent for r dependence of p
exppz      = 2.d0       ; Exponent for z dependence of p
ztrop      = 15000.d0   ; Tropopause Height
qtrop      = 1.0d-11     ; Tropopause specific humidity
rfpi       = 1000000.d0 ; Radius within which to use fixed-point iter.
constTv    = 0.608d0    ; Constant for Virtual Temp Conversion
deltaz     = 2.0d-12     ; Small number to ensure convergence in FPI
epsilon    = 1.0d-25     ; Small number to aviod dividing by zero in wind calc
exponent = Rd*gamma_/g   ; exponent
T0    = Ts0*(1.+constTv*q0)   ; Surface temp
Ttrop = T0 - gamma_*ztrop     ; Tropopause temp
ptrop = p00*(Ttrop/T0)^(1./exponent); Tropopause pressure

print("... ADD PERTURBATIONS")
print("Starting...")
print("cen_lat "+cen_lat)
print("cen_lon "+cen_lon)
print("dp "+dp)
print("rp "+rp)
cen_lat=cen_lat+latpert
cen_lon=cen_lon+lonpert
dp=dp+dppert
rp=rp+rppert
print("Ending...")
print("cen_lat "+cen_lat)
print("cen_lon "+cen_lon)
print("dp "+dp)
print("rp "+rp)

do ii=0,ncol-1
    if (mod(ii,250) .eq. 0) then
      print( ((tofloat(ii) / tofloat(ncol-1) )*100.)+" % done")
    end if
    do k = 0,nlev-1
 
      lat=selat(ii)
      lon=selon(ii)

      
      f  = 2.*omega*sin(cen_lat/convert)           ; Coriolis parameter
      gr = a*acos(sin(cen_lat/convert)*sin(lat/convert) + \  ; Great circle radius
           (cos(cen_lat/convert)*cos(lat/convert)*cos(lon/convert-cen_lon/convert)))
    
      ; calculate pressures
      ps = p00-dp*exp(-1*(gr/rp)^exppr) 
            ;print(lat+" "+lon+" "+ps)
      p = hya(k)*P0 + hyb(k)*ps
      
      height = (T0/gamma_)*(1.-(p/ps)^exponent)
      ;print(height+"")
      
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
              exit
            end if
          end do
          
          height = zn

          ;print("Corrected: "+zherebefore+" to: "+height+"   at "+lat+" "+lon)
          
      end if

      
      ;-----------------------------------------------------------------------
      ;    initialize U and V (wind components)
      ;-----------------------------------------------------------------------
      d1 = sin(cen_lat/convert)*cos(lat/convert) - cos(cen_lat/convert)*sin(lat/convert)*cos((lon-cen_lon)/convert)
      d2 = cos(cen_lat/convert)*sin((lon-cen_lon)/convert)
      d  = max( (/ epsilon, sqrt(d1^2. + d2^2.) /) )
      ufac = d1/d
      vfac = d2/d
      if (d .gt. 1.0) then
        print(lat+"   "+lon+"    "+d)
      end if
      if (height .gt. ztrop) then
          u = todouble(0.)
          v = todouble(0.)
      else
          v = vfac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
              - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
              /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
              +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))
          u = ufac*(-f*gr/2.+sqrt((f*gr/2.)^(2.) \
              - exppr*(gr/rp)^exppr*Rd*(T0-gamma_*height) \
              /(exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz) \
              +(1.-p00/dp*exp((gr/rp)^exppr)*exp((height/zp)^exppz)))))

          ;TERMA = -f*gr/2.
          ;TERMB = f^2*gr^2/4.
          ;TERMC = exppr*(gr/rp)^exppr * Rd * (T0-gamma_*height)
          ;TERMD = exppz*height*Rd*(T0-gamma_*height)/(g*zp^exppz)
          ;TERME = p00/dp*exp((gr/rp)^exppr + (height/zp)^exppz)
          ;TERMF = sqrt(TERMB - ( TERMC / (1 + TERMD - TERME) ) )
          ;vt = TERMA + sqrt(TERMB - ( TERMC / (1 + TERMD - TERME) ) )
          ;v = vfac*vt
          ;u = ufac*vt
      end if

      ;if (lat .lt. -80.) then
      ;  print(TERMA+" "+TERMB+" "+TERMC+" "+TERMD+" "+TERME+" "+TERMF)
      ;  print(p00+" "+dp+" "+gr+" "+rp+" "+exppr+" "+height+" "+exppz+" "+zp)
      ;  print(lat+"   "+lon+"    "+d+" "+d1+" "+d2+"   "+u+"    "+v+"    "+vt)
      ;  print("     ")
      ;end if
      
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

se_inic="/glade/u/home/zarzycki/work/initial/tc_testcase/ne0np4tcplane"+res+"_INIC_L"+numlevels+"."+ENS+".nc"
print("Writing output file "+se_inic)
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


