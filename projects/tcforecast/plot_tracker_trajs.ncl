;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_gpi.ncl"
;========================================================
begin

  forecastdate = "2012102200"
  stormnumber = 18  
 
  filenames = (/"/glade/u/home/zarzycki/work/tracker_gfdl/trakout180e/"+forecastdate+"/trak.cmz.atcfunix.glob."+forecastdate,"/glade/u/home/zarzycki/work/tracker_gfdl/trakout180e/"+forecastdate+"/trak.cmz.atcfunix.glob."+forecastdate/)
  numfiles = dimsizes(filenames)
  
  maxRows = 1000
  FillValue = -999
  latArry = new((/numfiles,maxRows/),float,FillValue)
  lonArry = new((/numfiles,maxRows/),float,FillValue)

do i = 0,numfiles-1

  filename = filenames(i)

  lines = asciiread(filename,-1,"string")
  delim = ","

  basin  =          str_get_field(lines,1,delim)
  number = tointeger(str_get_field(lines,2,delim))
  date  =   tointeger(str_get_field(lines,3,delim))
  modelid  =          str_get_field(lines,5,delim)
  fctime =  tointeger(str_get_field(lines,6,delim))
  lat  =          tofloat(str_get_field(lines,7,delim))/10.
  lon  =          tofloat(str_get_field(lines,8,delim))/10.
  latChar = stringtocharacter(str_strip(str_get_field(lines,7,delim)))
  lonChar= stringtocharacter(str_strip(str_get_field(lines,8,delim)))
  latDir = (latChar(:,3))
  lonDir = (lonChar(:,3))
  
  latDirStr = new(dimsizes(latDir),"string")
  lonDirStr = new(dimsizes(lonDir),"string")
  do k = 0,dimsizes(latDir)-1
    latDirStr(k) = chartostring(latDir(k))
    lonDirStr(k) = chartostring(lonDir(k))
  end do
  
  lat@_FillValue = FillValue
  lon@_FillValue = FillValue
  lat = where(latDirStr .eq. "S",-lat,lat)
  lon = where(lonDirStr .eq. "W",360.-lon,lon)
  
  CMZLat = where(str_strip(modelid) .eq. "CMZ",lat,lat@_FillValue)
  CMZLon = where(str_strip(modelid) .eq. "CMZ",lon,lon@_FillValue)
  CMZLat = where(number .eq. stormnumber,CMZLat,CMZLat@_FillValue)
  CMZLon = where(number .eq. stormnumber,CMZLon,CMZLon@_FillValue)
  
  
  do j = 0,dimsizes(CMZLat)-1
    latArry(i,j) = CMZLat(j)
    lonArry(i,j) = CMZLon(j)
  end do
  
  delete([/basin,number,date,modelid,fctime,lat,lon,latChar,lonChar,latDir,lonDir,latDirStr,lonDirStr/])
  
  delete(lines)
  delete(CMZLat)
  delete(CMZLon)
  
end do
delete(i)

;********************************************
   wks = gsn_open_wks("x11","traj")               ; open workstation
   res            = True                          ; map resources
   res@gsnDraw    = False                         ; don't draw
   res@gsnFrame   = False                         ; don't advance frame
   res@mpMaxLatF  = 50                           ; select subregion
   res@mpMinLatF  = 10 
   res@mpMinLonF  = 250
   res@mpMaxLonF  = 345
   
  ; res@mpMaxLatF  = 45                           ; select subregion
  ; res@mpMinLatF  = 25 
  ; res@mpMinLonF  = 310
  ; res@mpMaxLonF  = 325

   res@tiMainString    = "Example of a trajectory plot"  ; title
   res@gsnCenterString = "markers every 4th time step"   ; center string
  
   map = gsn_csm_map_ce(wks,res)                         ; create map
   draw(map)
;*********************************************
; trajectory parameters
;*********************************************
   ;xpt = new(dimsizes(lon),float)
   ;ypt = new(dimsizes(lat),float)
;*********************************************
; some plot parameters
;*********************************************
   pres                  = True               ; polyline resources
   pres@gsLineThicknessF = 2.0                ; line thickness

   mres  = True                               ; marker resources
   first = True                               ; start of traj resources
;********************************
; counter variable
   ;do i = 0,dimsizes(lat)-1

; add markers to the trajectories
      ;mres@gsMarkerIndex  = 16           ; marker style (circle)
      ;mres@gsMarkerSizeF  = 4.0          ; marker size
      
      markerColors = (/"blue","red"/)


do i = 0,numfiles-1
      pres@gsMarkerColor  = markerColors(i)
      gsn_polymarker(wks,map,lonArry(i,:),latArry(i,:),pres)
end do

   
   frame(wks)    
  
end
