load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "~/ncl/functions/tctestcase.ncl"

begin

doplot=False
;system("rm ~/scratch/iniseed.nc")
;system("cp /glade/u/home/zarzycki/scratch/cam5_work/varres_seedTCs/camrun.cam.i.0000-10-26-00000.nc ~/scratch/iniseed.nc")

;system("cp ~/scratch/cam5_work/se30np4.tcSeed/camrun.cam.r.0000-09-06-00000.nc ~/scratch/iniseed.nc")

inputFile = addfile("~/scratch/iniseed.nc","w")

lat = inputFile->lat
lon = inputFile->lon
lev = inputFile->lev
ncol = dimsizes(lat)

hyai = inputFile->hyai
hybi = inputFile->hyai
hyam = inputFile->hyam
hybm = inputFile->hybm
P0   = inputFile->P0

u = inputFile->U
v = inputFile->V
ps = inputFile->PS
t = inputFile->T
q = inputFile->Q

srand(tointeger(systemfunc("date +%s")))

minlat=10.
maxlat=25.
minlon=0.
maxlon=360.

cen_lat = (rand()/32766.)*(maxlat-minlat)+minlat
cen_lon = (rand()/32766.)*(maxlon-minlon)+minlon
lat_bnd = 18.
lon_bnd = 18.

; Purpose: Hybrid level definitions: p = a*p0 + b*ps
;          interfaces   p(k) = hyai(k)*ps0 + hybi(k)*ps
;          midpoints    p(k) = hyam(k)*ps0 + hybm(k)*ps

do i = 0,ncol-1
if (mod(i,100) .eq. 0) then
  print("At ncol: "+i+" of "+ncol)
end if

if (lat(i) .lt. (cen_lat + lat_bnd) .and. lat(i) .gt. (cen_lat - lat_bnd)) then
if (lon(i) .lt. (cen_lon + lon_bnd) .and. lon(i) .gt. (cen_lon - lon_bnd)) then
; PUT IF STATEMENT HERE
;do j = 0,dimsizes(lon)-1
do k = 0,dimsizes(lev)-1

; calc pressure level
p = hyam(k)*P0 + hybm(k)*ps(0,i)
;print(p+"")
;print(p)

;theArr = tctestcase(lon(j),lat(i),85000.,-999,0,ps(i,j),us(i,j),vs(i,j),t(i,j),q(i,j))
;us(i,j) = todouble(theArr(0))
;vs(i,j) = todouble(theArr(1))
;q(i,j)  = todouble(theArr(2))
;t(i,j)  = todouble(theArr(3))
;ps(i,j) = todouble(theArr(4))


;theArr = tctestcase(lon(i),lat(i),p,-999,0,ps(0,i),u(0,k,i),v(0,k,i),t(0,k,i),q(0,k,i))
theArr = tctestcase(cen_lon,cen_lat,lon(i),lat(i),p,-999,0,ps(0,i),u(0,k,i),v(0,k,i),t(0,k,i),q(0,k,i))
v(0,k,i) = todouble(theArr(0))
u(0,k,i) = todouble(theArr(1))
q(0,k,i)  = todouble(theArr(2))
t(0,k,i)  = todouble(theArr(3))




end do

; we only want to update ps once per column
ps(0,i) = todouble(theArr(4))
if (ps(0,i) .lt. 80000) then
print(" "+ps(0,i))
end if


end if
end if
end do

;theArr = tctestcase(-70,-21,85000.,-999,0)
;print(theArr)

inputFile->PS=ps
inputFile->U=u
inputFile->V=v
inputFile->T=t
inputFile->Q=q

if (doplot) then
 ;**************************************************
 ; create plot
 ;**************************************************
   wks = gsn_open_wks("x11","tc_mask")
  
res                      = True
res@gsnMaximize          = True
res@gsnSpreadColors     = True 	 
res@cnFillOn             = True              ; turn on color
res@cnLinesOn            = False             ; turn off contour lines
res@cnLineLabelsOn       = False
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;res@gsnAddCyclic = False
;plot = gsn_csm_contour_map(wks,vs,res)

res@sfXArray            = lon        ; Required to tell NCL where to
res@sfYArray            = lat        ; overlay data on globe.
map = gsn_csm_contour_map_ce(wks,ps(0,:),res)
end if
end
