; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "../../../functions/radialAvg.ncl"

begin


;configs=(/"CAM5","0.3","CAM5","0.3","0.1","0.6","1.2","0.3-Lscalex0.1","0.3-2xup2vp2","0.3-0.25xup2vp2","0.3-modifKpro01","0.3-modifKpro02","3.0-LscaleBlackadar-600m","0.3-LscaleBlackadar", \
;  "0.3-LscaleBlackadar-300m","3.0-LscaleBlackadar-300m","3.0-LscaleBlackadar","0.3-Lscalex0.4","6.0-LscaleBlackadar","6.0-LscaleBlackadar-2xup2vp2","0.3-0.5xC14","0.3-LscaleBlackadar-1500m", \
;  "3.0-LscaleBlackadar-1500m","0.3-Lscalex3.0","0.3-L120"/)
;grid=(/"x4","x4","x8","x8","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4","x4"/)

configs=(/"0.1","0.3","1.2","0.3-Lscale","0.3-CDx0.5","0.1-CDx0.5","0.6-CDFLAT","CAM5"/)
grid=(/"x4","x4","x4","x4","x4","x4","x4","x4"/)


printVarSummary(configs)
printVarSummary(grid)

plot_obs = True
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"

nruns = dimsizes(configs)
out_type="png"

data=new((/3,nruns/),"float")

;----------------Constants-----------------------------------

nEntries=50000
ms_to_kts = 1.94384449



; get data
do ii = 0,nruns-1

day="10"

config="newcyclone30"+grid(ii)+"_clubb_k10-"+configs(ii)

if (configs(ii) .eq. "CAM5")
  config="newcyclone30x4_CAM5"
 ; filename = "/glade/u/home/zarzycki/scratch/cam5_work/CAM5-TC-test-VR/newcyclone30"+grid(ii)+"_CAM5/camrun.cam.h1.2000-01-"+day+"-00000.nc"
 ; f2= "/glade/u/home/zarzycki/scratch/cam5_work/CAM5-TC-test-VR/newcyclone30"+grid(ii)+"_CAM5/camrun.cam.h3.2000-01-"+day+"-00000.nc"
  filename = "/glade/u/home/zarzycki/scratch/RCE.QPC5.ne0np4tcfplane.ne15x8/run/"+config+"/RCE.QPC5.ne0np4tcfplane.ne15x8.cam.h1.0001-01-10-00000.nc"
  f2= "/glade/u/home/zarzycki/scratch/RCE.QPC5.ne0np4tcfplane.ne15x8/run/"+config+"/RCE.QPC5.ne0np4tcfplane.ne15x8.cam.h3.0001-01-10-00000.nc"
  tf2 = addfile(f2,"r")
else
  filename = "/glade/u/home/zarzycki/scratch/RCE.QPC6.ne0np4tcfplane.ne15x8/run/"+config+"/RCE.QPC6.ne0np4tcfplane.ne15x8.cam.h1.0001-01-10-00000.nc"
  f2= "/glade/u/home/zarzycki/scratch/RCE.QPC6.ne0np4tcfplane.ne15x8/run/"+config+"/RCE.QPC6.ne0np4tcfplane.ne15x8.cam.h3.0001-01-10-00000.nc"
  tf2 = addfile(f2,"r")
end if

if (configs(ii) .eq. "cam5") then
  k10 = -999.00
else if (configs(ii) .eq. "1.2" .or. configs(ii) .eq. "0.6" .or. configs(ii) .eq. "0.3" .or. configs(ii) .eq. "0.1") then
  k10 = tofloat(configs(ii))
else
  k10 = 0.3
end if
end if

thefile = addfile(filename,"r")

timeStep=0

lat = thefile->lat
lon = thefile->lon


nlat = dimsizes(lat)
nlon = dimsizes(lon)


U = thefile->U(timeStep,:,:)
V = thefile->V(timeStep,:,:)
PS1 = thefile->PS(timeStep,:)
PS1 = PS1/100.
U10 = tf2->U10(timeStep,:)

UBOT = U(29,:)
UBOT = sqrt(U(29,:)^2 + V(29,:)^2)
UBOT = UBOT * .85

U850 = U({850},:)
U850 = sqrt(U({850},:)^2 + V({850},:)^2)

data(0,ii)=max(UBOT)
data(1,ii)=max(U10)
data(2,ii)=min(PS1)
if (ii .eq. 0) then
print("UBOT      U10      PS     U850")
end if
print(max(UBOT)+" "+max(U10)+" "+min(PS1)+" "+max(U850)+" "+config)

delete([/U850,UBOT,U10,PS1,U,V,nlat,nlon,lat,lon/])


end do

if (plot_obs) then

  ibfile = addfile(ibdir+ibfilename,"r")

  iblat = ibfile->lat_for_mapping*.01
  iblon = ibfile->lon_for_mapping*.01
  ibpres = ibfile->source_pres(:,:,0)*.1
  ibyear = ibfile->season
  ibwind = ibfile->source_wind(:,:,0)*.1/ms_to_kts

  ibdimsizes = dimsizes(iblat)
  ibnumstorms = ibdimsizes(0)

  do i = 0,ibnumstorms-1
    if (ibyear(i) .ge. 1995 .and. ibyear(i) .le. 2005) then
    else
      ibpres(i,:) = ibpres@_FillValue
      ibwind(i,:) = ibwind@_FillValue
    end if
  end do

  onedpres = ndtooned(ibpres)
  onedwind = ndtooned(ibwind)


end if






wks  = gsn_open_wks(out_type,"p-w")            ; open a ps file

res  = True
res@gsnMaximize            = True       ; Maximize plot in frame.
res@gsnDraw    = False                         ; don't draw
res@gsnFrame   = False                         ; don't advance frame

res@tiMainString  = "P-W curve"

res@tiYAxisString = "Wind speed (m/s)"  ; y axis title
res@tiXAxisString = "Surface pressure (hPa)"    ; y axis title

res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = 0.018
res@tiMainFontHeightF = 0.02
res@tmXBLabelFontHeightF = 0.015
res@tmYLLabelFontHeightF = 0.015

res@trXMinF           = 860.
res@trXMaxF           = 1025.
res@trYMinF           = 20.
res@trYMaxF           = 95.

res@xyMarkLineMode = "Markers"

res@xyMarkerColors = "red"
;res@xyMarker      = markerTypes(1)
res@xyMarkerSizeF = 0.004
plot = gsn_csm_xy(wks,data(2,:),data(1,:),res)

if (plot_obs) then
  res@xyMarkerColors = "blue"
  res@xyMarkerSizeF = 0.005
  plot2 = gsn_csm_xy(wks,onedpres,onedwind,res)
  overlay(plot,plot2)
end if

txres=True
buffer=0.0175*max(data(0,:))
txres@amJust="CenterRight"
txres@txFontHeightF = 0.014             ; Set the font height
;txres@txBackgroundFillColor="White"
;txres@txPerimOn=True
;txres@txPerimColor="Black"
  do i = 0,nruns-1

    text1 = gsn_add_text(wks,plot,configs(i),data(2,i)-buffer,data(1,i)+buffer,txres)
  end do


draw(plot)
frame(wks)

end
