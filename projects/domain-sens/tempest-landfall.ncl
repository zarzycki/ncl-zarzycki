;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "../../functions/getTrajectoriesGeneric.ncl"
load "../../functions/strip_missing.ncl"
load "../../functions/find_landfalls.ncl"
;load "../../functions/getTrajectories.ncl"
load "../../functions/trackDensity.ncl"

;========================================================
begin

;===========================================================================================

thedir="/global/homes/c/czarzyck/tempest-scripts/hyperion/"
theconfig="EXT"
thefile="trajectories.txt.CHEY.VR28.NATL."+theconfig+".CAM5.4CLM5.0.dtime900.ALL"

ncols = 10                    ; assign number of columns
maxLines = -1
headerDelimStr = "start"
delimStr="tab"
isHeader=False
out_type="pdf"

npossLF=3

hrsbase=6
hrsinterp=0.25

windThresh=17.5

;===========================================================================================

traj_data = getTrajectories(thedir+"/"+thefile,ncols,maxLines,headerDelimStr,delimStr,isHeader)

lon = traj_data(:,1,:)
lat = traj_data(:,2,:)
wind = traj_data(:,4,:)*.85
pres = traj_data(:,3,:)/100.
yyyy=  traj_data(:,6,:)
mm= traj_data(:,7,:)
dd= traj_data(:,8,:)
hh= traj_data(:,9,:)

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

;===========================================================================================

landfall_lat=new((/npossLF,nstorms/),typeof(lat))
landfall_lon=new((/npossLF,nstorms/),typeof(lon))
landfall_wind=new((/npossLF,nstorms/),typeof(wind))
landfall_pres=new((/npossLF,nstorms/),typeof(pres))

;===========================================================================================

interp_lat =interp_traj(lat,hrsbase,hrsinterp,True)
interp_lon =interp_traj(lon,hrsbase,hrsinterp,False)
interp_wind=interp_traj(wind,hrsbase,hrsinterp,False)
interp_pres=interp_traj(pres,hrsbase,hrsinterp,False)

;===========================================================================================

; find landfalls

;stormtest=49

verbosity=0
debug=False

STIX=0
ENIX=nstorms-1
if (debug) then
  STIX=20
  ENIX=20
end if

do ii = STIX,ENIX
  print("STORM NUMBER: "+ii)

  latClean=strip_missing(interp_lat(ii,:))
  lonClean=strip_missing(interp_lon(ii,:))

  IX = find_landfalls(latClean,lonClean,1,12,0.5,npossLF,verbosity)

  do zz = 0,npossLF-1
    if(.not.ismissing(IX(zz)))
      landfall_lat(zz,ii) = interp_lat(ii,IX(zz))
      landfall_lon(zz,ii) = interp_lon(ii,IX(zz))
      landfall_wind(zz,ii) = interp_wind(ii,IX(zz))
      landfall_pres(zz,ii) = interp_pres(ii,IX(zz))
    end if
  end do

  if (debug) then
    print("       ")
    print(landfall_lat(:,ii)+" "+landfall_lon(:,ii))
  end if

  delete(latClean)
  delete(lonClean)

end do

print(num(landfall_lat(0,:)))

;===========================================================================================


;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(out_type,"landfall."+thefile)
map = new(1,graphic)
  
res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
  
res@mpMinLatF             = 7
res@mpMaxLatF             = 48
res@mpMinLonF             = 261
res@mpMaxLonF             = 305

res@tmXBOn = False
res@tmXTOn = False
res@tmYLOn = False
res@tmYROn = False
 
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new((/npossLF,nstorms/),graphic)
dum1 = new((/npossLF,nstorms/),graphic)

do j = 0,nstorms-1
do i = 0,npossLF-1

thisWind=landfall_wind(i,j)
thisLat=landfall_lat(i,j)
thisLon=landfall_lon(i,j)

if (.not.ismissing(thisWind) .and. thisWind .gt. windThresh)


  linethicknesses = (/0.5,1.0,1.3,1.9,2.3,2.6/)
  linethicknesses = 4.0*linethicknesses

  polyres@gsMarkerSizeF = 0.024          ; select size to avoid streaking
  if (thisWind .lt. 17)
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (thisWind .ge. 17 .and. thisWind .lt. 33)
    polyres@gsMarkerColor = (/"green3"/)
    lineres@gsLineColor = (/"green3"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (thisWind .ge. 33 .and. thisWind .lt. 43)
    polyres@gsMarkerColor = (/"yellow2"/)
    lineres@gsLineColor = (/"yellow2"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (thisWind .ge. 43 .and. thisWind .lt. 49)
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (thisWind .ge. 49 .and. thisWind .lt. 58)
    polyres@gsMarkerColor = (/"darkorange3"/)
    lineres@gsLineColor = (/"darkorange3"/)
    lineres@gsLineThicknessF  = linethicknesses(4)
  else
    polyres@gsMarkerColor = (/"red"/) 
    lineres@gsLineColor = (/"red"/)
    lineres@gsLineThicknessF  = linethicknesses(5)
  end if
  end if
  end if
  end if
  end if
  
 txres               = True                            
 txres@txFontHeightF = 0.01             ; Set the font height
 
 polyresback=polyres
 polyresback@gsMarkerSizeF=0.032
 polyresback@gsMarkerColor="black" 

      dum1(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyresback)
      dum(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyres)
  
end if

end do
end do
  
print("Drawing plot")

resP = True
resP@gsnPanelMainString = "CAM landfalls ("+theconfig+")"     ; set main title
resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end


exit