undef ( "radialAvg3D" )
function radialAvg3D ( \
  data[*][*][*]    : numeric, \
  lat[*]           : numeric, \
  lon[*]           : numeric, \
  lev[*]           : numeric, \
  psminlat         : numeric, \
  psminlon         : numeric, \
  outerRad         : numeric, \
  mergeInnerBins   : logical \
)
local None

; lat (deg)
; lon (deg)
; center_lat(deg)
; center_lon(deg)
; outerRad (km)

begin

deltaLat = lat(1)-lat(0)
deltaLon = lon(1)-lon(0)
deltaMax = max((/deltaLon, deltaLat/))
deltaMin = min((/deltaLon, deltaLat/))
kmInDeg = 111.32
kmGrid = kmInDeg * deltaMax
print("The max lat/lon km grid spacing at equator is "+kmGrid+" km")

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

pi = 3.14159
d2r = pi/180.
r2d = 180./pi
lonr = lon*d2r
latr = lat*d2r
copy_VarCoords(lon,lonr)
copy_VarCoords(lat,latr)

psminLocY = ind_nearest_coord(psminlat,lat,0)
psminLocX = ind_nearest_coord(psminlon,lon,0)

;;;;; DO RADIAL AVERAGES

loopWidth = toint(ceil((outerRad*1.10) / (kmInDeg * deltaMin)))
; for standard lat/lon grid
;1.25 gives n ~= 5 in inner grid if numMerge = 2
;1.4 gives n ~= 9 in inner grid if numMerge = 2
timesGrid = 1.1 ; we want each radius bin to be timeGrid times kmGrid

nx = toint(outerRad/(timesGrid*kmGrid))
print("Number of bins is equal to "+nx)

if (mergeInnerBins) then
;  origRadiusArr = fspan(0,outerRad,nx)
;  radiusArr = new(dimsizes(origRadiusArr)-1,double)
;  radiusArr(0) = origRadiusArr(0)
;  radiusArr(1:dimsizes(radiusArr)-1) = origRadiusArr(2:dimsizes(origRadiusArr)-1)
  numMerge = 2 ; numMerge is the number of innermost radial bins we want to merge
  print("Merging innermost "+numMerge+" bins because radial average is so small.")
  numMergeMinusOne = numMerge-1
  origRadiusArr = fspan(0,outerRad,nx+numMergeMinusOne)
  radiusArr = new((dimsizes(origRadiusArr)-numMergeMinusOne),double)
  radiusArr(0) = origRadiusArr(0)
  printVarSummary(radiusArr)
  printVarSummary(origRadiusArr)
  radiusArr(1:dimsizes(radiusArr)-1) = origRadiusArr(numMerge:dimsizes(origRadiusArr)-1)
else
  print("Not merging any innermost bins -- be careful that your inner bins have > 1 pt.")
  radiusArr = fspan(0,outerRad,nx)
end if

numRadBins = dimsizes(radiusArr)

rad_thevar_hit  = new((/nlev,numRadBins/),integer)
rad_thevar_cum  = new((/nlev,numRadBins/),double)

; NEEDS to be 1 or 0
rad_thevar_hit!1 = "radius"
rad_thevar_cum!1 = "radius"
rad_thevar_hit&radius = radiusArr
rad_thevar_cum&radius = radiusArr

rad_thevar_hit!0 = "lev"
rad_thevar_cum!0 = "lev"
rad_thevar_hit&lev = lev
rad_thevar_cum&lev = lev

rad_thevar_hit = 0
rad_thevar_cum = 0

; NEED TO CORRECT NLEV
print("Starting loop")
do i = psminLocY-loopWidth,psminLocY+loopWidth
  print("Doing outer loop #: "+(i-psminLocY+loopWidth)+" of "+(loopWidth*2)+"   ("+((tofloat(i-psminLocY+loopWidth)/tofloat(loopWidth*2))*100.)+"%)")
  do j = psminLocX-loopWidth,psminLocX+loopWidth
    do k = 0,dimsizes(lev)-1
      gcdist = tofloat(gc_latlon(psminlat,psminlon,lat(i),lon(j),2,4))
      if (gcdist .le. outerRad)
        rad_thevar_hit(k,{gcdist}) = rad_thevar_hit(k,{gcdist}) + 1
        rad_thevar_cum(k,{gcdist}) = rad_thevar_cum(k,{gcdist}) + data(k,i,j)
      end if
    end do
  end do
end do

print("Minimum number of hits per gridbox: "+min(rad_thevar_hit))
print("Maximum number of hits per gridbox: "+max(rad_thevar_hit))
rad_thevar = rad_thevar_cum/rad_thevar_hit

copy_VarCoords(rad_thevar_hit,rad_thevar)

rad_thevar@units = data@units
rad_thevar@long_name=data@long_name

return(rad_thevar)

end

; ====================================================================================================

undef ( "radialAvg2D" )
function radialAvg2D ( \
  data[*][*]       : numeric, \
  lat[*]           : numeric, \
  lon[*]           : numeric, \
  psminlat         : numeric, \
  psminlon         : numeric, \
  outerRad         : numeric, \
  mergeInnerBins   : logical \
)
local None

; lat (deg)
; lon (deg)
; center_lat(deg)
; center_lon(deg)
; outerRad (km)

begin

deltaLat = lat(1)-lat(0)
deltaLon = lon(1)-lon(0)
deltaMax = max((/deltaLon, deltaLat/))
deltaMin = min((/deltaLon, deltaLat/))
kmInDeg = 111.32
kmGrid = kmInDeg * deltaMax
print("The max lat/lon km grid spacing at equator is "+kmGrid+" km")

nlat = dimsizes(lat)
nlon = dimsizes(lon)

pi = 3.14159
d2r = pi/180.
r2d = 180./pi
lonr = lon*d2r
latr = lat*d2r
copy_VarCoords(lon,lonr)
copy_VarCoords(lat,latr)

psminLocY = ind_nearest_coord(psminlat,lat,0)
psminLocX = ind_nearest_coord(psminlon,lon,0)

;;;;; DO RADIAL AVERAGES

loopWidth = toint(ceil((outerRad*1.10) / (kmInDeg * deltaMin)))
; for standard lat/lon grid
;1.25 gives n ~= 5 in inner grid if numMerge = 2
;1.4 gives n ~= 9 in inner grid if numMerge = 2
timesGrid = 1.1 ; we want each radius bin to be timeGrid times kmGrid

nx = toint(outerRad/(timesGrid*kmGrid))
print("Number of bins is equal to "+nx)

if (mergeInnerBins) then
;  origRadiusArr = fspan(0,outerRad,nx)
;  radiusArr = new(dimsizes(origRadiusArr)-1,double)
;  radiusArr(0) = origRadiusArr(0)
;  radiusArr(1:dimsizes(radiusArr)-1) = origRadiusArr(2:dimsizes(origRadiusArr)-1)
  numMerge = 2 ; numMerge is the number of innermost radial bins we want to merge
  print("Merging innermost "+numMerge+" bins because radial average is so small.")
  numMergeMinusOne = numMerge-1
  origRadiusArr = fspan(0,outerRad,nx+numMergeMinusOne)
  radiusArr = new((dimsizes(origRadiusArr)-numMergeMinusOne),double)
  radiusArr(0) = origRadiusArr(0)
  printVarSummary(radiusArr)
  printVarSummary(origRadiusArr)
  radiusArr(1:dimsizes(radiusArr)-1) = origRadiusArr(numMerge:dimsizes(origRadiusArr)-1)
else
  print("Not merging any innermost bins -- be careful that your inner bins have > 1 pt.")
  radiusArr = fspan(0,outerRad,nx)
end if

numRadBins = dimsizes(radiusArr)

rad_thevar_hit  = new((/numRadBins/),integer)
rad_thevar_cum  = new((/numRadBins/),double)

; NEEDS to be 1 or 0
rad_thevar_hit!0 = "radius"
rad_thevar_cum!0 = "radius"
rad_thevar_hit&radius = radiusArr
rad_thevar_cum&radius = radiusArr

rad_thevar_hit = 0
rad_thevar_cum = 0

; NEED TO CORRECT NLEV
print("Starting loop")
do i = psminLocY-loopWidth,psminLocY+loopWidth
  print("Doing outer loop #: "+(i-psminLocY+loopWidth)+" of "+(loopWidth*2)+"   ("+((tofloat(i-psminLocY+loopWidth)/tofloat(loopWidth*2))*100.)+"%)")
  do j = psminLocX-loopWidth,psminLocX+loopWidth
      gcdist = tofloat(gc_latlon(psminlat,psminlon,lat(i),lon(j),2,4))
      if (gcdist .le. outerRad)
        rad_thevar_hit({gcdist}) = rad_thevar_hit({gcdist}) + 1
        rad_thevar_cum({gcdist}) = rad_thevar_cum({gcdist}) + data(i,j)
      end if
  end do
end do

print("Minimum number of hits per gridbox: "+min(rad_thevar_hit))
print("Maximum number of hits per gridbox: "+max(rad_thevar_hit))
rad_thevar = rad_thevar_cum/rad_thevar_hit

copy_VarCoords(rad_thevar_hit,rad_thevar)

rad_thevar@units = data@units
rad_thevar@long_name=data@long_name

return(rad_thevar)

end

; ====================================================================================================

undef ( "calcWindComponents" )
function calcWindComponents ( \
  U[*][*][*]       : numeric, \
  V[*][*][*]       : numeric, \
  lat[*]           : numeric, \
  lon[*]           : numeric, \
  psminlat         : numeric, \
  psminlon         : numeric \
)
local None
begin

pi = 3.14159
d2r = pi/180.
r2d = 180./pi
lonr = lon*d2r
latr = lat*d2r
copy_VarCoords(lon,lonr)
copy_VarCoords(lat,latr)

deltalong = lonr(:)-(psminlon*d2r)

arr1 = conform(U,sin(deltalong),2) * conform(U,cos(latr),1)
arr2 = cos(psminlat*d2r)*conform(U,sin(latr),1) - sin(psminlat*d2r)*conform(U,cos(latr),1)*conform(U,cos(deltalong),2)
dir_angle_r = atan2(arr1,arr2)
; need to conform here
dir_angle_d = dir_angle_r*r2d

copy_VarCoords(U,dir_angle_r)
copy_VarCoords(U,dir_angle_d)

eps = 10.e-6
phi_r = atan2(U,V)
phi_d = phi_r*r2d

copy_VarCoords(U,phi_r)
copy_VarCoords(U,phi_d)

WIND = U
WIND = sqrt(U^2+V^2)

v_theta = WIND*sin(dir_angle_r - phi_r)
v_rad = -WIND*cos(dir_angle_r - phi_r)

copy_VarCoords(U,v_theta)
copy_VarCoords(U,v_rad)

v_theta@units = U@units
v_theta@long_name="Tangential wind"
v_rad@units = U@units
v_rad@long_name="Radial wind"

return( [/ v_rad, v_theta /] )

end


undef ( "radialInt3D" )
function radialInt3D ( \
  data[*][*][*]    : numeric, \
  lat[*]           : numeric, \
  lon[*]           : numeric, \
  lev[*]           : numeric, \
  psminlat         : numeric, \
  psminlon         : numeric, \
  outerRad         : numeric \
)
local None

; lat (deg)
; lon (deg)
; center_lat(deg)
; center_lon(deg)
; outerRad (km)

begin

deltaLat = lat(1)-lat(0)
deltaLon = lon(1)-lon(0)
deltaMax = max((/deltaLon, deltaLat/))
deltaMin = min((/deltaLon, deltaLat/))
kmInDeg = 111.32
kmGrid = kmInDeg * deltaMax
print("The max lat/lon km grid spacing at equator is "+kmGrid+" km")

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

pi = 3.14159
d2r = pi/180.
r2d = 180./pi
lonr = lon*d2r
latr = lat*d2r
copy_VarCoords(lon,lonr)
copy_VarCoords(lat,latr)

psminLocY = ind_nearest_coord(psminlat,lat,0)
psminLocX = ind_nearest_coord(psminlon,lon,0)

; Get cosine weights
rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat*rad)

loopWidth = toint(ceil((outerRad*1.25) / (kmInDeg * deltaMin)))
; make sure we are more than 1 to do a few rows of buffer cells

rad_thevar_hit  = new((/nlev/),float)
rad_thevar_cum  = new((/nlev/),float)

rad_thevar_hit!0 = "lev"
rad_thevar_cum!0 = "lev"
rad_thevar_hit&lev = lev
rad_thevar_cum&lev = lev

rad_thevar_hit = 0
rad_thevar_cum = 0

; NEED TO CORRECT NLEV
print("Starting loop")
do i = psminLocY-loopWidth,psminLocY+loopWidth
  print("Doing outer loop #: "+(i-psminLocY+loopWidth)+" of "+(loopWidth*2)+"   ("+((tofloat(i-psminLocY+loopWidth)/tofloat(loopWidth*2))*100.)+"%)")
  do j = psminLocX-loopWidth,psminLocX+loopWidth
    do k = 0,dimsizes(lev)-1
      gcdist = tofloat(gc_latlon(psminlat,psminlon,lat(i),lon(j),2,4))
      if (gcdist .le. outerRad)
        rad_thevar_hit(k) = rad_thevar_hit(k) + data(k,i,j)*clat(i)
        rad_thevar_cum(k) = rad_thevar_cum(k) + clat(i)
      end if
    end do
  end do
end do

rad_thevar = rad_thevar_hit/rad_thevar_cum

copy_VarCoords(rad_thevar_hit,rad_thevar)

rad_thevar@units = data@units
rad_thevar@long_name=data@long_name

return(rad_thevar)

end



undef ( "calc_vertmax_from_rad" )
function calc_vertmax_from_rad ( \
  vrad[*][*]       : numeric \
)
local None

begin

lev = vrad&lev
nlev = dimsizes(lev)
rad = vrad&radius
nrad = dimsizes(rad)

rmw = new((/nlev/),"float")

do k = 0,dimsizes(lev)-1
  maxix = maxind(vrad(k,:))
  rmw(k) = tofloat(rad(maxix))
end do

rmw!0 = "lev"
rmw&lev = lev

return(rmw)



undef ( "calc_zmax_from_rad" )
function calc_zmax_from_rad ( \
  vrad[*][*]       : numeric \
)
local None

begin

lev = vrad&lev
nlev = dimsizes(lev)
rad = vrad&radius
nrad = dimsizes(rad)

zmax = new((/nlev/),"float")

do k = 0,nrad-1
  maxix = maxind(vrad(:,k))
  zmax(k) = tofloat(lev(maxix))
end do

zmax!0 = "lev"
zmax&lev = lev

return(zmax)





end
