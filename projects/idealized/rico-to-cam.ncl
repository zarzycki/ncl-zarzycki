begin

ENS="001"
res="ne15x8"
numlevels=30

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
nlevi=dimsizes(ilev)

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

;299.28
init=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/scam/iop/BOMEX_5day_4scam_c180703.nc","r")
;init=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/scam/iop/RICO_3day_4scam_c180703.nc","r")
ui=init->u(0,:,:,:)
vi=init->v(0,:,:,:)
ti=init->T(0,:,:,:)
qi=init->q(0,:,:,:)
psi=init->Ps(0,:,:)
levi=init->lev(:)
p0=100000.

print(vi)

interp_ui = pres2hybrid(levi,psi,p0,ui,hya,hyb,1)
interp_vi = pres2hybrid(levi,psi,p0,vi,hya,hyb,1)
interp_ti = pres2hybrid(levi,psi,p0,ti,hya,hyb,1)
interp_qi = pres2hybrid(levi,psi,p0,qi,hya,hyb,1)



do ii=0,ncol-1

  lat=selat(ii)
  lon=selon(ii)

  V_(0,:,ii) = interp_vi(:,0,0)
  U_(0,:,ii) = interp_ui(:,0,0)
  Q_(0,:,ii) = interp_qi(:,0,0)
  T_(0,:,ii) = interp_ti(:,0,0)
  PD(0,ii) = psi(0,0)
      
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

se_inic="/glade/u/home/zarzycki/work/initial/bomex/ne0np4tcplane"+res+"_INIC_L"+numlevels+"."+ENS+".nc"
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


