;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/strip_missing.ncl"
load "../../../functions/find_landfalls.ncl"
;load "../../../functions/getTrajectories.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"

;========================================================
begin

;===========================================================================================

thedir="./"
thefile="trajectories.txt.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.ALL"

ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
headerDelimStr = "start"
delimStr="tab"
isHeader=False
out_type="pdf"

plot_gen=False

maskBasins=True
basin = 1
tcMask = mask_tc(0,-999,-999,1.0,360)

npossLF=3

hrsbase=6
hrsinterp=0.25

windThresh=17.5

;===========================================================================================

traj_data = getTrajectoriesGeneric(thedir+"/"+thefile,ncols,maxLines,headerDelimStr,delimStr,True,isHeader)

lon = traj_data(:,2,:)
lat = traj_data(:,3,:)
wind = traj_data(:,5,:)
pres = traj_data(:,4,:)/100.
yyyy=  traj_data(:,7,:)
mm= traj_data(:,8,:)
dd= traj_data(:,9,:)
hh= traj_data(:,10,:)

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

;===========================================================================================

landfall_lat=new((/2,npossLF,nstorms/),typeof(lat))
landfall_lon=new((/2,npossLF,nstorms/),typeof(lon))
landfall_wind=new((/2,npossLF,nstorms/),typeof(wind))
landfall_pres=new((/2,npossLF,nstorms/),typeof(pres))

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
  if ( .not.ismissing(interp_lat(ii,1)) .and. \ 
    tcMask({interp_lat(ii,1)},{min((/interp_lon(ii,1),359.0/))}) .eq. basin)
  print("STORM NUMBER: "+ii)

  latClean=strip_missing(interp_lat(ii,:))
  lonClean=strip_missing(interp_lon(ii,:))

  IX = find_landfalls(latClean,lonClean,1,12,0.5,npossLF,verbosity)

  do zz = 0,npossLF-1
    if(.not.ismissing(IX(zz)))
      landfall_lat(0,zz,ii) = interp_lat(ii,IX(zz))
      landfall_lon(0,zz,ii) = interp_lon(ii,IX(zz))
      landfall_wind(0,zz,ii) = interp_wind(ii,IX(zz))
      landfall_pres(0,zz,ii) = interp_pres(ii,IX(zz))
      landfall_lat(1,zz,ii) = interp_lat(ii,1)
      landfall_lon(1,zz,ii) = interp_lon(ii,1)
    end if
  end do

  if (debug) then
    print("       ")
    print(landfall_lat(:,ii)+" "+landfall_lon(:,ii))
  end if

  delete(latClean)
  delete(lonClean)
  end if
end do

print(num(landfall_lat(0,0,:)))

;===========================================================================================


;--------------------------------------------------------
print("Beginning plot sequence")
if (plot_gen) then
  wks  = gsn_open_wks(out_type,"land_gen."+thefile)
else
  wks  = gsn_open_wks(out_type,"landfall."+thefile)
end if
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
  
if (plot_gen) then
  res@mpMinLatF             = 3
  res@mpMaxLatF             = 48
  res@mpMinLonF             = 261
  res@mpMaxLonF             = 355
else
  res@mpMinLatF             = 7
  res@mpMaxLatF             = 48
  res@mpMinLonF             = 261
  res@mpMaxLonF             = 305
end if

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
dum1 = dum
dum2 = dum
dum3 = dum

; output file
quote = inttochar(34)
delim = ","
txtfilename="LF."+thefile
system("rm "+txtfilename)

do j = 0,nstorms-1
do i = 0,npossLF-1



thisWind=landfall_wind(0,i,j)
thisLat=landfall_lat(0,i,j)
thisLon=landfall_lon(0,i,j)
genLat=landfall_lat(1,i,j)
genLon=landfall_lon(1,i,j)

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

  if (plot_gen) then
    dum2(i,j) = gsn_add_polymarker(wks,map,genLon,genLat,polyresback)
    dum3(i,j) = gsn_add_polymarker(wks,map,genLon,genLat,polyres)  
  else
    dum1(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyresback)
    dum(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyres) 
  end if

  system("echo "+quote+   thisLon+delim+thisLat+delim+thisWind+delim+genLon+delim+genLat   +quote+" >> "+txtfilename)
  
 
end if

end do
end do
  
print("Drawing plot")

resP = True
if (plot_gen)
  resP@gsnPanelMainString = "CAM landfall genesis ()"     ; set main title
else
  resP@gsnPanelMainString = "CAM landfalls ()"     ; set main title
end if
resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end


exit
