function calc_area(lat[*]:numeric,lon[*]:numeric,scaling:numeric,returnunits:integer)

; return units 1 = km^2
; return units 0 = m^2
;========================================================
; CALCULATE SURFACE AREA OF GRIDBOXES
;========================================================

local nlat,mlon,re,pi,rad,rr,ASPHERE,dxeq,dx,dy,carea
begin
  if (scaling .le. 0.) then
    scaling=1.0
  end if

  re = 6371.0088/scaling

  nlat = dimsizes(lat) 
  mlon = dimsizes(lon) 
  pi = 4.0*atan(1.0) 
  rad = pi/180.0 
  rr = re*rad
  ASPHERE= 4*pi*re^2 ; km^2 [theoretical sfc sphere] 

  dxeq = (lon(2)-lon(1))*rr ; dx=dlon at equator [m] 
  dx = dxeq*cos(lat*rad) ; dx[*] at each latitude 
  dy = new (nlat,typeof(lat),"No_FillValue") 
  dy(0) = (90-abs((lat(1)+lat(0))*0.5))*rr 
  dy(nlat-1)= dy(0) 
  dy(1:nlat-2) = abs(lat(2:nlat-1)-lat(1:nlat-2))*rr 
  carea = dx*dy ; [*] cell area function of latitude only 
  
  aire = conform_dims( (/nlat,mlon/), carea, 0)

  if (returnunits .eq. 0) then
    aire = aire * 1000 * 1000
  else if (returnunits .eq. 1 ) then
    aire = aire
  else
    print("invalid return units, exiting")
    exit
  end if
  end if

  return(aire)

end



 

