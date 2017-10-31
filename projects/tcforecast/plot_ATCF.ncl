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

  filename = "issac.txt"
  
  forecastdate = "2012082100"

;---Read in file as array of strings so we can parse each line
  lines = asciiread(filename,-1,"string")

  delim = ","

;---Read fields 1, 5 and 9
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
  do i = 0,dimsizes(latDir)-1
    latDirStr(i) = chartostring(latDir(i))
    lonDirStr(i) = chartostring(lonDir(i))
  end do
  
  lat@_FillValue = -999
  lon@_FillValue = -999
  lat = where(latDirStr .eq. "S",-lat,lat)
  lon = where(lonDirStr .eq. "W",360.-lon,lon)
  
  ;print(modelid)
  
  bestLat = where(str_strip(modelid) .eq. "BEST",lat,lat@_FillValue)
  bestLon = where(str_strip(modelid) .eq. "BEST",lon,lon@_FillValue)
  
  AVNOLat = where(str_strip(modelid) .eq. "NGX",lat,lat@_FillValue)
  AVNOLon = where(str_strip(modelid) .eq. "NGX",lon,lon@_FillValue)
  AVNOLat = where(date .eq. forecastdate,AVNOLat,AVNOLat@_FillValue)
  AVNOLon = where(date .eq. forecastdate,AVNOLon,AVNOLon@_FillValue)
  
  CMZLat = where(str_strip(modelid) .eq. "CMZ",lat,lat@_FillValue)
  CMZLon = where(str_strip(modelid) .eq. "CMZ",lon,lon@_FillValue)
  CMZLat = where(date .eq. forecastdate,CMZLat,CMZLat@_FillValue)
  CMZLon = where(date .eq. forecastdate,CMZLon,CMZLon@_FillValue)
  CMZLat = where(number .eq. 09,CMZLat,CMZLat@_FillValue)
  CMZLon = where(number .eq. 09,CMZLon,CMZLon@_FillValue)
  ;print(bestLat)
  
  
   ; printVarSummary(lat)
  
  ;lat = where(date .eq. forecastdate,lat,lat@_FillValue)
  ;lon = where(date .eq. forecastdate,lon,lon@_FillValue)
  
  ;printVarSummary(lat)
  ;print(lat)
  ;print(lon)
  

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
      pres@gsLineColor  = "black"      ; maker color

      gsn_polyline(wks,map,bestLon,bestLat,pres) ; draw every 4th marker
      
      pres@gsLineColor  = "red"      ; maker color

      gsn_polyline(wks,map,AVNOLon,AVNOLat,pres) ; draw every 4th marker

print("BEST")
do j = 0,dimsizes(bestLon)-1
if(.not.ismissing(bestLon(j)))
print(bestLat(j)+","+bestLon(j))
end if
end do
print("CAMSE")
do j = 0,dimsizes(CMZLon)-1
if(.not.ismissing(CMZLon(j)))
print(CMZLat(j)+","+CMZLon(j))
end if
end do
      
      pres@gsLineColor  = "blue"      ; maker color

      gsn_polyline(wks,map,CMZLon,CMZLat,pres) ; draw every 4th marker
      ;print("We are "+i)

   ;end do
   
   frame(wks)    
  
end
