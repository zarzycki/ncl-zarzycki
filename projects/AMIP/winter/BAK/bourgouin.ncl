load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

h3filedir = "/glade/u/home/zarzycki/scratch/h3files/atl30x4/1993/"
h3filename = "atl_30_x4_refine_nochem.cam.h3.1993-01-30-00000.nc"
h3file = addfile(h3filedir+h3filename,"r")

h2filedir = "/glade/u/home/zarzycki/scratch/h2files/atl30x4/1993/"
h2filename = "atl_30_x4_refine_nochem.cam.h2.1993-01-28-00000.nc"
h2file = addfile(h2filedir+h2filename,"r")

h1filedir = "/glade/u/home/zarzycki/scratch/h1files/atl30x4/1993/"
h1filename = "atl_30_x4_refine_nochem.cam.h1.1993-01-30-00000.nc"
h1file = addfile(h1filedir+h1filename,"r")

;print(h3file)

stride = 10
lat = h3file->lat(::stride)
lon = h3file->lon(::stride)
nlat = dimsizes(lat)
nlon = dimsizes(lon)

h3filetime=h3file->time
h2filetime=h2file->time
h1filetime=h1file->time

option=0
option@calendar="noleap"

h3date = cd_inv_calendar(1993,01,30,12,00,00,h3filetime@units, option)
h2date = cd_inv_calendar(1993,01,30,12,00,00,h2filetime@units, option)
h1date = cd_inv_calendar(1993,01,30,12,00,00,h1filetime@units, option)

T = h3file->T({h3date},:,::stride,::stride)
PS = h2file->PS({h2date},::stride,::stride)
PRECT = h2file->PRECT({h2date},::stride,::stride)

hyam=h3file->hyam
hyai=h3file->hyai
hybm=h3file->hybm
hybi=h3file->hybi
P0=h3file->P0

ptype = PS

; p = a*p0+b*ps

;do i = 150,150
;do j = 100,100

do i = 0,nlat-1
print("doing "+i+" of "+nlat)
do j = 0,nlon-1
; Get pres arrays
pres_m = hyam*P0+hybm*PS(i,j)
pres_i = hyai*P0+hybi*PS(i,j)

;print(pres_m)
;print(pres_i)

linlog = -1
T_m = T(:,i,j)
T_i = int2p_Wrap(pres_m,T(:,i,j),pres_i,linlog)

Rd = 287
cp = 1004

theta_i = T_i*((pres_i/100000.)^(Rd/cp))
theta_top = theta_i(0:dimsizes(theta_i)-2)
theta_bot = theta_i(1:dimsizes(theta_i)-1)
pres_i_top = pres_i(0:dimsizes(pres_i)-2)
pres_i_bot = pres_i(1:dimsizes(pres_i)-1)

;printVarSummary(theta_top)
;printVarSummary(theta_bot)

;print(T_m)

area = -cp*(T_m-273.15)*log(pres_i_top/pres_i_bot)
;print(area)
area = where(abs(area).le.10^-5,10^-5,area)
;if i .eq. 24 then print(area) end if
;area_sign = where(abs(area).le.10^-5,0.,area/abs(area))

area_sign = area/abs(area)

signchange = 0
do k = 0,dimsizes(area_sign)-2
  if (area_sign(k) - area_sign(k+1) .ne. 0) then
    signchange = signchange+1
  end if
end do

if (signchange .eq. 0) then
  ; snow
  ptype(i,j) = 0
else if (signchange .eq. 1) then
  ; either rain or snow
  PA = where(area.gt.0,area,0)
  if (sum(PA).lt.5.6) then
    ;snow
    ptype(i,j) = 0
    ;print("snow")
  else if (sum(PA).gt.13.2) then
    ; rain
    ptype(i,j) = 2
  else
    ; mix
    ;print("mix")
    ptype(i,j) = 1
  end if
  end if
delete(PA)
else if (signchange .eq. 2) then





  ; freezing rain or ice
  ;ptype(i,j) = 3
  ;print("frza")
  
area_arr = new(3,double)
area_arr = 0
counter=0
do k = 0,dimsizes(area_sign)-2
  area_arr(counter) = area_arr(counter)+area(k)
  if (area_sign(k) - area_sign(k+1) .ne. 0) then
    counter = counter+1
  end if
end do
area_arr(counter) = area_arr(counter)+area(dimsizes(area_sign)-1)
; area_arr(0) wasted stuff above first cross
; area_arr(1) PA
; area_arr(2) NA
PA = area_arr(1)
NA = -area_arr(2)
print("PA: "+PA+"    NA: "+NA)
if (NA .gt. 66+0.66*PA) then
  ptype(i,j) = 3
  print("ICE")
  ;ice pellets
else if (NA .lt. 46+0.66*PA) then
  ptype(i,j) = 4
  print("FZRA")
  ;FZRA
else
  ptype(i,j) = 1
  print("MIX")
  ;mix of FZRA/ice
end if
end if

delete(PA)
delete(NA)
;print(area)
;print(area_arr)

  
  
else







  ptype(i,j) = 2
end if
end if
end if


; if signchange = 1, rain
; if signchange = 0, snow
  
end do
end do

;printVarSummary(ptype)
;ptype = where(PRECT.gt.1e-11,ptype,ptype@_FillValue)

 ;**************************************************
 ; create plot
 ;**************************************************
   wks = gsn_open_wks("x11","ptype")

   res                      = True
   res@gsnMaximize          = True

   res@cnFillOn             = True              ; turn on color
   res@cnLinesOn            = False             ; turn off contour lines
   res@cnLineLabelsOn       = False

   res@gsnAddCyclic = False

   plot = gsn_csm_contour_map(wks,ptype,res)






end
