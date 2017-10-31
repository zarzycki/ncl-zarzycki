
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; ================================================;
begin

plot_traj = True
map_proj = "Orthographic" ; Orthographic or CylindricalEquidistant

if(plot_traj) then
  ibfile=addfile("/glade/u/home/zarzycki/work/ibtracs/Allstorms.ibtracs_wmo.v03r08.nc","r")
  ibyear = toint(ibfile->season(:))
  ibnamechar = ibfile->name(:,:)
  ibname = new(dimsizes(ibyear),"string")
  do i = 0,dimsizes(ibyear)-1
    ibname(i)=oneDtostring(ibnamechar(i,:))
    ibname(i)=str_sub_str(ibname(i),",","")
  end do

  thisStr="HAIYAN"
  thisYear=2013
  do i = 0,dimsizes(ibname)-1
    if (thisStr .eq. ibname(i) .and. thisYear .eq. ibyear(i)) then
      print("Hello "+thisStr+"   "+ibyear(i)+"   index "+i)
      thisIndex=i
    end if
  end do

  obs_lat=short2flt(ibfile->lat_wmo(thisIndex,:))
  obs_lon=short2flt(ibfile->lon_wmo(thisIndex,:))
  obs_wind=short2flt(ibfile->wind_wmo(thisIndex,:))
  obs_wind=0.514444*obs_wind ; convert to m/s
  obs_pres=short2flt(ibfile->pres_wmo(thisIndex,:))

  ; We have to do this crap to filter out initialization time
  obs_time=ibfile->time_wmo(thisIndex,:)
  obs_time_conv = cd_calendar(obs_time,3)
  obs_time = obs_time - 56600.5000000005
end if


wks  = gsn_open_wks("pdf","haiyan_48_x8_outline_"+map_proj)       ; open a ps file
gsn_define_colormap(wks,"wh-bl-gr-ye-re") ; choose a colormap


res                        = True         ; mods desdired
res@gsnDraw=False
res@gsnFrame=False
res@mpLandFillColor        = "tan"
res@mpOceanFillColor       = "LightBlue"
res@mpInlandWaterFillColor = "Blue"
res@mpPerimOn              = False

res@mpProjection               = map_proj

if(res@mpProjection .eq. "Orthographic") then
  res@mpCenterLonF               = 145.0       ; choose center lon
  res@mpCenterLatF               = 10.         ; choose center lat
else if (res@mpProjection .eq. "CylindricalEquidistant") then
  res@mpMinLatF              = -40
  res@mpMaxLatF              = 60
  res@mpMinLonF              = 40
  res@mpMaxLonF              = 250
  res@mpCenterLonF           = (res@mpMinLonF + res@mpMaxLonF)/2
else
end if
end if

plot = gsn_csm_map(wks,res)        ; draw global map

if (plot_traj) then
  dum_traj = new(1000,"graphic")
  lineres=True
  lineres@gsLineColor = "red"
  lineres@gsLineThicknessF = 5.0
  do k = 0,dimsizes(obs_lat)-2
    if(.not. ismissing(obs_lon(k+1))) then
      lon1=obs_lon(k)
      lon2=obs_lon(k+1)
      lat1=obs_lat(k)
      lat2=obs_lat(k+1)
    end if
    dum_traj(k) = gsn_add_polyline(wks,plot,(/lon1,lon2/),(/lat1,lat2/),lineres)
  end do
end if

nrefine=3 ; refinement level (2 = x4, 3 = x8, 4 = x16)
npoints=4 ; 4 for rectangular

xyPts=new((/nrefine,2,npoints/),"float")
xyPts(0,0,:) = (/ 63.9225,-138.6845,-138.6845,63.9225 /)  ;lon
xyPts(0,1,:) = (/ -30.2065,-30.2065,48.7895,48.7895 /)    ;lat
xyPts(1,0,:) = (/83.95,83.95,-165.0275,-165.0275/)
xyPts(1,1,:) = (/-14.924,37.7195,37.7195,-14.924/)
xyPts(2,0,:) = (/102.1045,102.1045,174.2925,174.2925/)
xyPts(2,1,:) = (/-1.4015,23.715,23.715,-1.4015/)

dum = new(100,"graphic")
plres = True
dumIx=0  ; index for dum array
plres@gsLineColor = "black"
plres@gsLineThicknessF = 5.0
do i=0,nrefine-1
  do j=0,npoints-1
    if (j .eq. npoints-1) then
      ; the line needs to "loop back" from last point to first point
      dum(dumIx) = gsn_add_polyline(wks, plot, (/xyPts(i,0,j),xyPts(i,0,0)/), (/xyPts(i,1,j),xyPts(i,1,0)/), plres)
    else
      dum(dumIx) = gsn_add_polyline(wks, plot, xyPts(i,0,j:j+1), xyPts(i,1,j:j+1), plres)
    end if
      dumIx=dumIx+1   ;iterate counter
  end do
end do

txres               = True                            
txres@txFontHeightF = 0.018             ; Set the font height
txres@txBackgroundFillColor="White"
txres@txPerimOn=True
txres@txPerimColor="Black"

if(res@mpProjection .eq. "Orthographic") then
  text1 = gsn_add_text(wks,plot,"8km",165,11.5,txres)
  text1 = gsn_add_text(wks,plot,"17km",180,-8,txres)
  text1 = gsn_add_text(wks,plot,"34km",205,-23,txres)
  text1 = gsn_add_text(wks,plot,"69km",160,-45,txres)
else if (res@mpProjection .eq. "CylindricalEquidistant") then
  text1 = gsn_add_text(wks,plot,"8km",163,13.5,txres)
  text1 = gsn_add_text(wks,plot,"17km",180,-8,txres)
  text1 = gsn_add_text(wks,plot,"34km",205,-23,txres)
  text1 = gsn_add_text(wks,plot,"69km",235,-32,txres)
else
end if
end if


draw(plot)
frame(wks)

end
