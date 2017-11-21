load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

f = addfile("MERRAfile.nc","r")

;PSL,T200,T500,U850,UBOT,V850,VBOT,Z1000,Z200

Mlat = f->YDim_EOSGRID
Mlon = f->XDim_EOSGRID
Mlev = f->Height_EOSGRID
Mtime = f->TIME_EOSGRID(::2)
MPSL = f->SLP(::2,:,:)
MU850 = f->U(::2,{850},:,:)
MV850 = f->V(::2,{850},:,:)
MUBOT = f->U(::2,{1000},:,:)
MVBOT = f->V(::2,{1000},:,:)
MT500 = f->T(::2,{500},:,:)
MT200 = f->T(::2,{200},:,:)
MZ1000 = f->H(::2,{1000},:,:)
MZ200 = f->H(::2,{200},:,:)

utc_date = cd_calendar(Mtime, 0)
year   = tointeger(utc_date(:,0))    ; Convert to integer for
month  = tointeger(utc_date(:,1))    ; use sprinti 
day    = tointeger(utc_date(:,2))
hour   = tointeger(utc_date(:,3))
minute = tointeger(utc_date(:,4))
second = utc_date(:,5)
   month_abbr = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep", \
                    "Oct","Nov","Dec"/)
date_str = sprinti("%0.2iZ ", hour) + sprinti("%0.2i ", day) + \
              month_abbr(month) + " "  + sprinti("%0.4i", year)
print(date_str)

print("Filling missing data values")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 100             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill( MPSL, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MU850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MV850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MUBOT, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MVBOT, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MT500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MT200, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MZ1000, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( MZ200, is_cyclic, guess, nscan, eps, relc, opt)

print("Doing vort calculations")
MVR850 = MV850
MVR850 = uv2vrF(MU850,MV850)
MVR850sm = smth9_Wrap(MVR850, 0.50, 0.50, True)

print("Generating lat arrays")
gridsize = 0.5
latS = -90
latN = 90
lonW = -180
lonE = 180
dlat =  gridsize
dlon =  gridsize
nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)
lat  = todouble(fspan(latS, latN, nlat))
lon  = todouble(fspan(lonW, lonE-dlon, mlon))
lat@units = "degrees_north"
lon@units = "degrees_east"
lat@long_name = "latitude"
lon@long_name = "longitude"
;lat!0 = "lat"
;lat&lat = lat
;lon!0 = "lon"
;lon&lon = lon

print("Horizontal bilinear interpolation")
PSL = linint2_Wrap(Mlon,Mlat,MPSL,True,lon,lat,0)
PSL!0    = "time"
PSL!1    = "lat"
PSL!2    = "lon"
PSL&time = Mtime
PSL&lat = lat
PSL&lon = lon

U850 = linint2_Wrap(Mlon,Mlat,MU850,True,lon,lat,0)
U850!0    = "time"
U850!1    = "lat"
U850!2    = "lon"
U850&time = Mtime
U850&lat = lat
U850&lon = lon

V850 = linint2_Wrap(Mlon,Mlat,MV850,True,lon,lat,0)
V850!0    = "time"
V850!1    = "lat"
V850!2    = "lon"
V850&time = Mtime
V850&lat = lat
V850&lon = lon

T500 = linint2_Wrap(Mlon,Mlat,MT500,True,lon,lat,0)
T500!0    = "time"
T500!1    = "lat"
T500!2    = "lon"
T500&time = Mtime
T500&lat = lat
T500&lon = lon

T200 = linint2_Wrap(Mlon,Mlat,MT200,True,lon,lat,0)
T200!0    = "time"
T200!1    = "lat"
T200!2    = "lon"
T200&time = Mtime
T200&lat = lat
T200&lon = lon

UBOT = linint2_Wrap(Mlon,Mlat,MUBOT,True,lon,lat,0)
UBOT!0    = "time"
UBOT!1    = "lat"
UBOT!2    = "lon"
UBOT&time = Mtime
UBOT&lat = lat
UBOT&lon = lon

VBOT = linint2_Wrap(Mlon,Mlat,MVBOT,True,lon,lat,0)
VBOT!0    = "time"
VBOT!1    = "lat"
VBOT!2    = "lon"
VBOT&time = Mtime
VBOT&lat = lat
VBOT&lon = lon

Z1000 = linint2_Wrap(Mlon,Mlat,MZ1000,True,lon,lat,0)
Z1000!0    = "time"
Z1000!1    = "lat"
Z1000!2    = "lon"
Z1000&time = Mtime
Z1000&lat = lat
Z1000&lon = lon

Z200 = linint2_Wrap(Mlon,Mlat,MZ200,True,lon,lat,0)
Z200!0    = "time"
Z200!1    = "lat"
Z200!2    = "lon"
Z200&time = Mtime
Z200&lat = lat
Z200&lon = lon

VR850 = linint2_Wrap(Mlon,Mlat,MVR850,True,lon,lat,0)
VR850!0    = "time"
VR850!1    = "lat"
VR850!2    = "lon"
VR850&time = Mtime
VR850&lat = lat
VR850&lon = lon

VR850sm = linint2_Wrap(Mlon,Mlat,MVR850sm,True,lon,lat,0)
VR850sm!0    = "time"
VR850sm!1    = "lat"
VR850sm!2    = "lon"
VR850sm&time = Mtime
VR850sm&lat = lat
VR850sm&lon = lon

print("Filling missing data values again")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 100             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill( PSL, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( U850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( V850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( UBOT, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VBOT, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( T500, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( T200, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( Z1000, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( Z200, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VR850, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VR850sm, is_cyclic, guess, nscan, eps, relc, opt)

delete_VarAtts(U850, -1)
delete_VarAtts(V850, -1)
delete_VarAtts(PSL, -1)
delete_VarAtts(UBOT, -1)
delete_VarAtts(VBOT, -1)
delete_VarAtts(T500, -1)
delete_VarAtts(T200, -1)
delete_VarAtts(Z1000, -1)
delete_VarAtts(Z200, -1)
delete_VarAtts(VR850, -1)
delete_VarAtts(VR850sm, -1)

print(max(U850))
print(max(V850))



print("Writing file")
filename = tostring(year(0))+tostring(month(0))+tostring(day(0))+".nc"
system("/bin/rm -f "+filename)   ; remove any pre-existing file
ncdf = addfile(filename ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

;ncdf->lat = lat
;ncdf->lon = lon
ncdf->PSL  = PSL           
ncdf->U850 = U850
ncdf->V850 = V850
ncdf->UBOT = UBOT
ncdf->VBOT = VBOT
ncdf->T500  = T500
ncdf->T200  = T200
ncdf->Z200  = Z200
ncdf->Z1000  = Z1000
ncdf->VR850 = VR850
ncdf->VR850SM  = VR850sm

end
