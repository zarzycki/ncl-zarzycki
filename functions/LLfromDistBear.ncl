;========================================================
; Input
; lat1deg: start lat (deg)
; lon1deg: start lon (deg)
; brngdeg: Bearing (deg)
; d: distance (km)
;
; Output
; latlon2(0) = lat2 (deg)
; latlon2(1) = lon2 (deg) 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
undef ( "LLfromDistBear" )
function LLfromDistBear( \
  lat1deg[*]    : numeric, \
  lon1deg[*]    : numeric, \
  brngdeg       : numeric, \
  d             : numeric \
)
local None

begin

deg2rad = 0.0174532925
R = 6378.1 ;km

lat1 = lat1deg*deg2rad
lon1 = lon1deg*deg2rad
brng = brngdeg*deg2rad

latlon2=new(2,"float")

latlon2(0) = asin(sin(lat1)*cos(d/R) + cos(lat1)*sin(d/R)*cos(brng))
latlon2(1) = lon1 + atan2(sin(brng)*sin(d/R)*cos(lat1),cos(d/R)-sin(lat1)*sin(latlon2(0)))


;lat2 = math.asin( math.sin(lat1)*math.cos(d/R) +
;             math.cos(lat1)*math.sin(d/R)*math.cos(brng))
;lon2 = lon1 + math.atan2(math.sin(brng)*math.sin(d/R)*math.cos(lat1),
;                     math.cos(d/R)-math.sin(lat1)*math.sin(lat2))

latlon2deg = latlon2/deg2rad

if (latlon2deg(1) .gt. 360.0) then
  latlon2deg(1)=latlon2deg(1)-360.0
end if
if (latlon2deg(1) .lt. 0.0) then
  latlon2deg(1)=latlon2deg(1)+360.0
end if



return(latlon2deg)


end

