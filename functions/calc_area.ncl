function calc_area(lat[*]:numeric,lon[*]:numeric)

;========================================================
; CALCULATE SURFACE AREA OF GRIDBOXES
;========================================================

local nlat,mlon,re,pi,rad,rr,ASPHERE,dxeq,dx,dy,carea
begin

  nlat = dimsizes(lat) 
  mlon = dimsizes(lon) 
  re = 6371.0088; [km] average radius of earth 
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

  return(aire)

end



 

