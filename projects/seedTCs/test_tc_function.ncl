load "/Users/cmz5202/ncl-zarzycki/functions/tctestcase.ncl"

begin

doplot=True

system("rm ./testing.nc")
system("cp ./FHIST-ne30-betacast-ERA5-x001_INIC.nc ./testing.nc")

inputFile = addfile("./testing.nc","w")

lat = inputFile->lat
lon = inputFile->lon
lev = inputFile->lev
ncol = dimsizes(lat)

hyai = inputFile->hyai
hybi = inputFile->hyai
hyam = inputFile->hyam
hybm = inputFile->hybm
;P0   = inputFile->P0
P0   = 100000.

u = inputFile->U
v = inputFile->V
ps = inputFile->PS
t = inputFile->T
q = inputFile->Q

;to_delete=(/"_FillValue_original","missing_value_original"/)
;to_delete=(/"_FillValue","missing_value"/)
;to_delete=(/"maximum_value","minimum_value"/)
to_delete=(/"time"/)

delete_VarAtts(u,to_delete)
delete_VarAtts(v,to_delete)
delete_VarAtts(t,to_delete)
delete_VarAtts(q,to_delete)
delete_VarAtts(ps,to_delete)

srand(tointeger(systemfunc("date +%s")))

;minlat=10.
;maxlat=25.
;minlon=0.
;maxlon=360.
;cen_lat = (rand()/32766.)*(maxlat-minlat)+minlat
;cen_lon = (rand()/32766.)*(maxlon-minlon)+minlon

lat_bnd = 18.
lon_bnd = 18.

cen_lat = 30.
cen_lon = 300.

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


res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 96000.			; set the minimum contour level
res@cnMaxLevelValF  = 102000.			; set the maximum contour level
res@cnLevelSpacingF = 500.			; set the interval between contours
  
res@mpMinLatF = cen_lat - 15.
res@mpMaxLatF = cen_lat + 15.
res@mpMinLonF = cen_lon - 15.
res@mpMaxLonF = cen_lon + 15.

;res@gsnAddCyclic = False
;plot = gsn_csm_contour_map(wks,vs,res)

res@sfXArray            = lon        ; Required to tell NCL where to
res@sfYArray            = lat        ; overlay data on globe.
map = gsn_csm_contour_map_ce(wks,ps(0,:),res)
end if
end
