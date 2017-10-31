load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "omega.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "bourgouin_fcn.ncl"
load "cobb_fcn.ncl"

begin

doplot=False
stride = 1

h3files = systemfunc ("ls /glade/u/home/zarzycki/scratch/h3files/atl30x4/1993/atl_30_x4_refine_nochem.cam.h3.1993-01-04*.nc")
;h3filedir = "/glade/u/home/zarzycki/scratch/h3files/atl30x4/1993/"
;h3filename = "atl_30_x4_refine_nochem.cam.h3.1993-01-30-00000.nc"
;h3file = addfile(h3filedir+h3filename,"r")
h3file = addfiles(h3files,"r")

h2files = systemfunc ("ls /glade/u/home/zarzycki/scratch/h2files/atl30x4/1993/atl_30_x4_refine_nochem.cam.h5.1993-01-04*.nc")
;h2filedir = "/glade/u/home/zarzycki/scratch/h2files/atl30x4/1993/"
;h2filename = "atl_30_x4_refine_nochem.cam.h2.1993-01-28-00000.nc"
;h2file = addfile(h2filedir+h2filename,"r")
h2file = addfiles(h2files,"r")

h1files = systemfunc ("ls /glade/u/home/zarzycki/scratch/h1files/atl30x4/1993/atl_30_x4_refine_nochem.cam.h1.1993-01-04*.nc")
;h1filedir = "/glade/u/home/zarzycki/scratch/h1files/atl30x4/1993/"
;h1filename = "atl_30_x4_refine_nochem.cam.h1.1993-01-30-00000.nc"
;h1file = addfile(h1filedir+h1filename,"r")
h1file = addfiles(h1files,"r")

;print(h3file)


lat = h3file[0]->lat(::stride)
lon = h3file[0]->lon(::stride)
nlat = dimsizes(lat)
nlon = dimsizes(lon)

hyam=h3file[0]->hyam
hyai=h3file[0]->hyai
hybm=h3file[0]->hybm
hybi=h3file[0]->hybi
P0=h3file[0]->P0

h3filetime=h3file[:]->time
h2filetime=h2file[:]->time
h1filetime=h1file[:]->time

;do z = 0,dimsizes(h2filetime)-1,2
do z = 0,0

thisTime = h2filetime(z)
thisTimeCal = cd_calendar(thisTime,0)
YYYYMMDDHH = tostring(cd_calendar(thisTime,3))

print(thisTimeCal)

option=0
option@calendar="noleap"

;h3date = cd_inv_calendar(1993,01,30,00,00,00,h3filetime@units, option)
;h2date = cd_inv_calendar(1993,01,30,00,00,00,h2filetime@units, option)
;h1date = cd_inv_calendar(1993,01,30,00,00,00,h1filetime@units, option)

yyyy = tostring(thisTimeCal(0,0))
mm   = tostring(thisTimeCal(0,1))
dd   = tostring(thisTimeCal(0,2))
hh   = tostring(thisTimeCal(0,3))

h3date = cd_inv_calendar(toint(thisTimeCal(0,0)),toint(thisTimeCal(0,1)),toint(thisTimeCal(0,2)),toint(thisTimeCal(0,3)),toint(thisTimeCal(0,4)),toint(thisTimeCal(0,5)),h3filetime@units, option)
h2date = cd_inv_calendar(toint(thisTimeCal(0,0)),toint(thisTimeCal(0,1)),toint(thisTimeCal(0,2)),toint(thisTimeCal(0,3)),toint(thisTimeCal(0,4)),toint(thisTimeCal(0,5)),h2filetime@units, option)
h1date = cd_inv_calendar(toint(thisTimeCal(0,0)),toint(thisTimeCal(0,1)),toint(thisTimeCal(0,2)),toint(thisTimeCal(0,3)),toint(thisTimeCal(0,4)),toint(thisTimeCal(0,5)),h1filetime@units, option)

T = h3file[:]->T({h3date},:,::stride,::stride)
PS = h2file[:]->PS({h2date},::stride,::stride)
PRECT = h2file[:]->PRECT({h2date},::stride,::stride)
U = h3file[:]->U({h3date},:,::stride,::stride)
V = h3file[:]->V({h3date},:,::stride,::stride)
Q = h3file[:]->Q({h3date},:,::stride,::stride)
Z = h3file[:]->Z3({h3date},:,::stride,::stride)

ptype = PS
ratio = PS
ratio = 0.

;OMEGA = omega_driver(P0,PS,U,V,hyam,hybm,hyai,hybi)
OMEGA = T
; p = a*p0+b*ps

latindx=546
lonindx=1135
do i = latindx-1,latindx-1
do j = lonindx-1,lonindx-1

;do i = 0,nlat-1
;print("doing "+i+" of "+nlat)
;do j = 0,nlon-1
;do i = 4,4
;do j = 115,115
; Get pres arrays
pres_m = hyam*P0+hybm*PS(i,j)
pres_i = hyai*P0+hybi*PS(i,j)
T_m = T(:,i,j)
ptype(i,j) = bourgouin_fcn(pres_m,pres_i,T_m,-999)

print(ptype(i,j))



if (ptype(i,j) .eq. 0) then
omega_m = OMEGA(:,i,j)
q_m = Q(:,i,j)
; Get RH and trim
rh_m = relhum(T_m,q_m,pres_m)
rh_m = where(pres_m.lt.25000.,0,rh_m)
omega_m = where(pres_m.lt.25000.,0,omega_m)

z_m = Z(:,i,j)
linlog=-1
z_i = int2p_Wrap(pres_m,z_m,pres_i,linlog)

;ratio(i,j) = cobb_fcn(omega_m,T_m,rh_m,z_i)
if (ratio(i,j) .eq. 0) then
  ratio(i,j) = 10.
end if

delete([/omega_m,q_m,rh_m,z_m,z_i,linlog/])

if (ratio(i,j) .ge. 50.5) then
  print("WARNING: BAD SNOW RATIO AT i: "+i+"   j: "+j)
end if
end if

delete([/T_m,pres_m,pres_i/])

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

system("/bin/rm -f /glade/scratch/zarzycki/winter/"+YYYYMMDDHH+".nc")   ; remove any pre-existing file
ncdf     = addfile("/glade/scratch/zarzycki/winter/"+YYYYMMDDHH+".nc" ,"c")  ; open output netCDF file

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
delete([/PRECT,PRECT_SNOW,PRECT_RAIN,PRECT_MIX,PRECT_FZRA,PRECT_ICE,ptype,ratio,PRECT_SNOW_RATE/])
delete([/YYYYMMDDHH,yyyy,mm,dd,hh,thisTimeCal/])
;delete([/L_DIR_1900,L_INC_1899/])
;list_vars()



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

end do


end
