load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "omega.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "bourgouin_fcn.ncl"
load "cobb_fcn.ncl"

begin

; ===== Getting date from YYYYMMDD
;dtime_map = (/4,2,2/)
;splitDate = str_split_by_length(tostring(YYYYMMDD),dtime_map)
;yearstr=splitDate(0)
;monthstr=splitDate(1)
;daystr=splitDate(2)
print("Date: "+yearstr+" "+monthstr+" "+daystr)

doplot=False
stride = 1

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

print(h3filetime)
print(h2filetime)
print(h1filetime)

T = h3file->T(:,:,::stride,::stride)
PS = h2file->PS(::2,::stride,::stride)
PRECT = h2file->PRECT(::2,::stride,::stride)
U = h3file->U(:,:,::stride,::stride)
V = h3file->V(:,:,::stride,::stride)
Q = h3file->Q(:,:,::stride,::stride)
Z = h3file->Z3(:,:,::stride,::stride)

print("Vars are loaded")

print("Calculating omega...")
OMEGA = omega_driver(P0,PS,U,V,hyam,hybm,hyai,hybi)
print("... done calculating omega")

ptype = PS
ratio = PS
ratio = 0.

do z = 0,dimsizes(h2filetime)-1

thisTime = h2filetime(z)
thisTimeCal = cd_calendar(thisTime,0)
YYYYMMDDHH = tostring(cd_calendar(thisTime,3))

print(thisTimeCal)

option=0
option@calendar="noleap"

;h3date = cd_inv_calendar(1993,01,30,00,00,00,h3filetime@units, option)
;h2date = cd_inv_calendar(1993,01,30,00,00,00,h2filetime@units, option)
;h1date = cd_inv_calendar(1993,01,30,00,00,00,h1filetime@units, option)

;yyyy = tostring(thisTimeCal(0,0))
;mm   = tostring(thisTimeCal(0,1))
;dd   = tostring(thisTimeCal(0,2))
;hh   = tostring(thisTimeCal(0,3))

h3date = cd_inv_calendar(toint(thisTimeCal(0,0)),toint(thisTimeCal(0,1)),toint(thisTimeCal(0,2)),toint(thisTimeCal(0,3)),toint(thisTimeCal(0,4)),toint(thisTimeCal(0,5)),h3filetime@units, option)
h2date = cd_inv_calendar(toint(thisTimeCal(0,0)),toint(thisTimeCal(0,1)),toint(thisTimeCal(0,2)),toint(thisTimeCal(0,3)),toint(thisTimeCal(0,4)),toint(thisTimeCal(0,5)),h2filetime@units, option)
h1date = cd_inv_calendar(toint(thisTimeCal(0,0)),toint(thisTimeCal(0,1)),toint(thisTimeCal(0,2)),toint(thisTimeCal(0,3)),toint(thisTimeCal(0,4)),toint(thisTimeCal(0,5)),h1filetime@units, option)

; p = a*p0+b*ps

;do i = 150,150
;do j = 100,100

do i = 0,nlat-1
print("doing "+i+" of "+nlat)
do j = 0,nlon-1
;do i = 4,4
;do j = 115,115
; Get pres arrays
pres_m = hyam*P0+hybm*PS(z,i,j)
pres_i = hyai*P0+hybi*PS(z,i,j)
T_m = T(z,:,i,j)
ptype(z,i,j) = bourgouin_fcn(pres_m,pres_i,T_m,-999)



if (ptype(z,i,j) .eq. 0) then
omega_m = OMEGA(z,:,i,j)
q_m = Q(z,:,i,j)
; Get RH and trim
rh_m = relhum(T_m,q_m,pres_m)
rh_m = where(pres_m.lt.25000.,0,rh_m)
omega_m = where(pres_m.lt.25000.,0,omega_m)

z_m = Z(z,:,i,j)
linlog=-1
z_i = int2p_Wrap(pres_m,z_m,pres_i,linlog)

ratio(z,i,j) = cobb_fcn(omega_m,T_m,rh_m,z_i)
if (ratio(z,i,j) .eq. 0) then
  ratio(z,i,j) = 10.
end if

delete([/omega_m,q_m,rh_m,z_m,z_i,linlog/])

if (ratio(z,i,j) .ge. 50.5) then
  print("WARNING: BAD SNOW RATIO AT i: "+i+"   j: "+j)
end if
end if

delete([/T_m,pres_m,pres_i/])

end do
end do

end do

delete([/PS,T,Q,U,V,Z,OMEGA/])

PRECT@_FillValue = -999     
PRECT_SNOW = PRECT
PRECT_RAIN = PRECT
PRECT_MIX = PRECT
PRECT_FZRA = PRECT
PRECT_ICE = PRECT

;PRECT_SNOW = where(ptype.eq.0,PRECT_SNOW,PRECT_SNOW@_FillValue)
;PRECT_RAIN = where(ptype.eq.2,PRECT_RAIN,PRECT_RAIN@_FillValue)
;PRECT_MIX = where(ptype.eq.1,PRECT_MIX,PRECT_MIX@_FillValue)
;PRECT_FZRA = where(ptype.eq.4,PRECT_FZRA,PRECT_FZRA@_FillValue)
;PRECT_ICE = where(ptype.eq.3,PRECT_ICE,PRECT_ICE@_FillValue)

PRECT_SNOW = where(ptype.eq.0,PRECT_SNOW,0)
PRECT_RAIN = where(ptype.eq.2,PRECT_RAIN,0)
PRECT_MIX = where(ptype.eq.1,PRECT_MIX,0)
PRECT_FZRA = where(ptype.eq.4,PRECT_FZRA,0)
PRECT_ICE = where(ptype.eq.3,PRECT_ICE,0)

PRECT_SNOW_RATE = PRECT
PRECT_SNOW_RATE = PRECT_SNOW*ratio*141732.283
;printVarSummary(ptype)
;PRECT = where(ptype.eq.0,PRECT,PRECT@_FillValue)

outputFile="atl_30_x4_refine_nochem.cam.h9."+yearstr+"-"+monthstr+"-"+daystr+"-00000.nc"
outputDir="/glade/scratch/zarzycki/winter/"
system("/bin/rm -f "+outputDir+"/"+outputFile)   ; remove any pre-existing file
ncdf = addfile(outputDir+"/"+outputFile ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->PRECT_SNOW  = PRECT_SNOW      
ncdf->PRECT_RAIN  = PRECT_RAIN
ncdf->PRECT_MIX = PRECT_MIX
ncdf->PRECT_FZRA = PRECT_FZRA
ncdf->PRECT_ICE = PRECT_ICE
ncdf->PTYPE = ptype
ncdf->RATIO = ratio
ncdf->PRECT_SNOW_RATE = PRECT_SNOW_RATE

delete(ncdf)
;delete([/PRECT,PRECT_SNOW,PRECT_RAIN,PRECT_MIX,PRECT_FZRA,PRECT_ICE,ptype,ratio,PRECT_SNOW_RATE/])
;delete([/YYYYMMDDHH,yyyy,mm,dd,thisTimeCal/])
;delete([/L_DIR_1900,L_INC_1899/])
list_vars()



if (doplot) then

;**************************************************
; create plot
;**************************************************
wks = gsn_open_wks("x11","ptype")

res                      = True
res@gsnMaximize          = True

res@cnFillOn             = True              ; turn on color
res@cnLinesOn            = False             ; turn off contour lines
res@cnLineLabelsOn       = False

res@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
res@cnLevels    = (/ 0.5,1.5,2.5,3.5/)	; set levels
res@cnFillColors = (/ "blue","pink","green","orange","red"/)	; set the colors to be used


res@gsnAddCyclic = False

res@cnFillMode = "RasterFill"

plot = gsn_csm_contour_map(wks,ptype,res)

end if




end
