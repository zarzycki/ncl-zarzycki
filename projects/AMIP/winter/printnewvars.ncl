load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "omega.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "bourgouin_fcn.ncl"
load "cobb_fcn.ncl"

begin

print("Date: "+yearstr+" "+monthstr+" "+daystr)

doplot=False
stride = 1

wcLoadData = systemfunc("date")

h3filedir = "/glade/u/home/zarzycki/scratch/h3files/atl30x4/1993/"
h3filename = "atl_30_x4_refine_nochem.cam.h3."+yearstr+"-"+monthstr+"-"+daystr+"-00000.nc"
h3file = addfile(h3filedir+h3filename,"r")

h2filedir = "/glade/u/home/zarzycki/scratch/h2files/atl30x4/1993/"
h2filename = "atl_30_x4_refine_nochem.cam.h5."+yearstr+"-"+monthstr+"-"+daystr+"-00000.nc"
h2file = addfile(h2filedir+h2filename,"r")


h1filedir = "/glade/u/home/zarzycki/scratch/h1files/atl30x4/1993/"
h1filename = "atl_30_x4_refine_nochem.cam.h1."+yearstr+"-"+monthstr+"-"+daystr+"-00000.nc"
h1file = addfile(h1filedir+h1filename,"r")

print("Files are loaded")

lat = h3file->lat(::stride)
lon = h3file->lon(::stride)
nlat = dimsizes(lat)
nlon = dimsizes(lon)

hyam=h3file->hyam
hyai=h3file->hyai
hybm=h3file->hybm
hybi=h3file->hybi
P0=h3file->P0

h3filetime=h3file->time
h2filetime=h2file->time(::2)
h1filetime=h1file->time

ntim = dimsizes(h3filetime)
nlev = dimsizes(hyam)
nlevi = dimsizes(hyai)

T = h3file->T(:,:,::stride,::stride)
PS = h2file->PS(::2,::stride,::stride)
U = h3file->U(:,:,::stride,::stride)
V = h3file->V(:,:,::stride,::stride)
Q = h3file->Q(:,:,::stride,::stride)
Z = h3file->Z3(:,:,::stride,::stride)

pres_m = T

wallClockElapseTime(wcLoadData, "Load data", 0)

wcdoPressure = systemfunc("date")

pres_i = new( (/ntim,nlevi,nlat,nlon/) ,"float")

do z = 0,3
do i = 0,nlat-1
;print("doing "+i+" of "+nlat)
do j = 0,nlon-1
; Get pres arrays
pres_m(z,:,i,j) = tofloat(hyam)*tofloat(P0)+tofloat(hybm)*PS(z,i,j)
pres_i(z,:,i,j) = tofloat(hyai)*tofloat(P0)+tofloat(hybi)*PS(z,i,j)
end do
end do
end do

pdel  = dpres_hybrid_ccm(PS,P0,hyai,hybi)
pmid  = pres_hybrid_ccm (PS,P0,hyam,hybm)
klevi  = dimsizes(hybi)
hybd   = hybi(1:) - hybi(0:klevi-2)

wallClockElapseTime(wcdoPressure, "Pressure looping", 0)

wcZinterp = systemfunc("date")

linlog = -1
Z_I = int2p_n_Wrap(pres_m,Z,pres_i,linlog,1)

wallClockElapseTime(wcZinterp, "Z interp", 0)

wcOmega = systemfunc("date")
print("Calculating omega...")

OMEGA = omega_driver(P0,PS,U,V,hyam,hybm,hyai,hybi)
PSX = PS
PSY = PS
gradsf(log(PS),PSX,PSY)

div   = uv2dvG(U,V)                     ; divergence on gaussian grid

wallClockElapseTime(wcOmega, "Calc omega", 0)

wcRH = systemfunc("date")
print("Calculating RH...")
rh_m = relhum(T,Q,pres_m)
print("... done calculating RH.")
wallClockElapseTime(wcRH, "Calc RH", 0)


wcOutfile = systemfunc("date")
outputFile="atl_30_x4_refine_nochem.cam.h7."+yearstr+"-"+monthstr+"-"+daystr+"-00000.nc"
outputDir="/glade/scratch/zarzycki/winter/"
system("/bin/rm -f "+outputDir+"/"+outputFile)   ; remove any pre-existing file
ncdf = addfile(outputDir+"/"+outputFile ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

print(hybd)

copy_VarCoords(T,rh_m)
copy_VarCoords(PS,PSX)
copy_VarCoords(PS,PSY)
copy_VarCoords(T,pmid)
copy_VarCoords(T,pdel)
copy_VarCoords(U,div)

; output variables directly
ncdf->OMEGA  = OMEGA      
ncdf->RH  = rh_m
ncdf->DIV = div
;ncdf->Z_I = Z_I
ncdf->PSX = PSX
ncdf->PSY = PSY
ncdf->pdel = pdel
ncdf->pmid = pmid
ncdf->PS = PS
;ncdf->DIV = div

delete(ncdf)

wallClockElapseTime(wcOutfile, "Writing file", 0)

end
