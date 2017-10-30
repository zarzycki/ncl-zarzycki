undef("psminsolver")
function psminsolver(lat,lon,PS)

local nlat, nlon, b, b1D, dsizes_b, b_indices, psminlat, psminlon
; calculate lat/lon of min of PS array passed into function
; returns 2x1 array where lat is first index and lon is 2nd index
begin

nlat = dimsizes(lat)
nlon = dimsizes(lon)

b = new((/nlat,nlon/),float)

b(:,:) = PS(:,:)
b1D      = ndtooned(b)
dsizes_b = dimsizes(b)

;---Resolve the 1D indices back to their original 3D array.
b_indices  = ind_resolve(minind(b1D),dsizes_b)

;---Convert index to lat/lon points
psminlat = lat(b_indices(0,0))
psminlon = lon(b_indices(0,1))

psminloc = new(2,"float")
psminloc(0)=psminlat
psminloc(1)=psminlon

return(psminloc)
  
end