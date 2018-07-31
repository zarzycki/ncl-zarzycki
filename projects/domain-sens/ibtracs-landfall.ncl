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

thedir="/global/homes/c/czarzyck/ncl-zarzycki/files/"
thefile="Allstorms.ibtracs_wmo.v03r10.nc"

out_type="pdf"

npossLF=3

hrsbase=6
hrsinterp=0.25

windThresh=17.5

ibstyr=1955
ibenyr=2016

numyears=tofloat(ibenyr-ibstyr+1)

factor=1.0
ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

wcStrt     = systemfunc("date")

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")
ibdir = thedir
ibfilename=thefile

ibfile = addfile(ibdir+ibfilename,"r")

;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

iblat = ibfile->lat_wmo(stix:enix,:)*.01
iblon = ibfile->lon_wmo(stix:enix,:)*.01
ibtype = toint(ibfile->nature_wmo(stix:enix,:))
ibwind_ = ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts
ibpres = ibfile->pres_wmo(stix:enix,:)*.1*100.
ibtime = ibfile->time_wmo(stix:enix,:)
ibnamechar = ibfile->name(stix:enix,:)

iblon=where(iblon.lt.0,iblon+360.,iblon)

ibbasin = byte2flt(ibfile->sub_basin(stix:enix,:))

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

ibstormcount=dimsizes(ibfile->season(stix:enix))
ibsizes = dimsizes(iblat)
ibntimes = ibsizes(1)

; Need to convert char to str for name
ibnamesingle = new(ibstormcount,"string")
do i = 0,ibstormcount-1
  ibnamesingle(i)=oneDtostring(ibnamechar(i,:))
  ibnamesingle(i)=str_sub_str(ibnamesingle(i),",","")
end do

ibname = conform(ibwind_,ibnamesingle,0)

; Needed to correct for weird IBTrACS issues with .0000000005 times, etc.
ibtime = decimalPlaces(ibtime,3,True)

ibwind_ = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibwind_,ibwind_@_FillValue)
ibpres = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibpres,ibpres@_FillValue)
iblat = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblat,iblat@_FillValue)
iblon = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblon,iblon@_FillValue)
ibtime = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibtime,ibtime@_FillValue)
ibname = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibname,ibname@_FillValue)

; Correct for non-standard times
eps=0.00001
ibwind_ = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibwind_@_FillValue,ibwind_)
ibpres = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibpres@_FillValue,ibpres)
iblat  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblat@_FillValue,iblat)
iblon  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblon@_FillValue,iblon)
ibtime = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibtime@_FillValue,ibtime)
ibname = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibname@_FillValue,ibname)



delete(i)






ndims = dimsizes(iblon)
nstorms = ndims(0)
ntimes = ndims(1)

;===========================================================================================

landfall_lat=new((/npossLF,nstorms/),typeof(iblat))
landfall_lon=new((/npossLF,nstorms/),typeof(iblon))
landfall_wind=new((/npossLF,nstorms/),typeof(ibwind_))
landfall_pres=new((/npossLF,nstorms/),typeof(ibpres))

;===========================================================================================

interp_lat  = new((/nstorms,10000/),typeof(iblat))
interp_lon  = new((/nstorms,10000/),typeof(iblon))
interp_wind = new((/nstorms,10000/),typeof(ibwind_))
interp_pres = new((/nstorms,10000/),typeof(ibpres))

do ii = 0,nstorms-1
  if (num(iblat(ii,:)) .gt. 1) then
    tmp=interp_traj(strip_missing(iblat(ii,:)),hrsbase,hrsinterp,False)
    ntimesm1=dimsizes(tmp)-1
    interp_lat(ii,0:ntimesm1)=tmp
    delete(tmp)

    tmp=interp_traj(strip_missing(iblon(ii,:)),hrsbase,hrsinterp,False)
    ntimesm1=dimsizes(tmp)-1
    interp_lon(ii,0:ntimesm1)=tmp
    delete(tmp)

    tmp=interp_traj(strip_missing(ibwind_(ii,:)),hrsbase,hrsinterp,False)
    ntimesm1=dimsizes(tmp)-1
    interp_wind(ii,0:ntimesm1)=tmp
    delete(tmp)

    tmp=interp_traj(strip_missing(ibpres(ii,:)),hrsbase,hrsinterp,False)
    ntimesm1=dimsizes(tmp)-1
    interp_pres(ii,0:ntimesm1)=tmp
    delete(tmp)
  end if
end do

;interp_lat =interp_traj(iblat,hrsbase,hrsinterp,False)
;interp_lon =interp_traj(iblon,hrsbase,hrsinterp,False)
;interp_wind=interp_traj(ibwind_,hrsbase,hrsinterp,False)
;interp_pres=interp_traj(ibpres,hrsbase,hrsinterp,False)

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
  ;print(iblat(ii,:) + " " + iblon(ii,:) +" "+ibtime(ii,:))
  print("STORM NUMBER: "+ii+" "+ibname(ii,0))

  if (.not.ismissing(interp_lat(ii,0))) then
    latClean=strip_missing(interp_lat(ii,:))
    lonClean=strip_missing(interp_lon(ii,:))
    windClean=strip_missing(interp_wind(ii,:))
    presClean=strip_missing(interp_pres(ii,:))

    IX = find_landfalls(latClean,lonClean,1,12,0.5,npossLF,verbosity)

    do zz = 0,npossLF-1
      if(.not.ismissing(IX(zz)))
        landfall_lat(zz,ii) = latClean(IX(zz))
        landfall_lon(zz,ii) = lonClean(IX(zz))
        landfall_wind(zz,ii) = windClean(IX(zz))
        landfall_pres(zz,ii) = presClean(IX(zz))
      end if
    end do

    if (debug) then
      print("       ")
      print(landfall_lat(:,ii)+" "+landfall_lon(:,ii))
    end if

    delete(latClean)
    delete(lonClean)
    delete(windClean)
    delete(presClean)
  end if

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

  polyres@gsMarkerSizeF = 0.024           ; select size to avoid streaking
  if (thisWind .lt. 17)
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
  else if (thisWind .ge. 17 .and. thisWind .lt. 33)
    polyres@gsMarkerColor = (/"green3"/)
    lineres@gsLineColor = (/"green3"/)
  else if (thisWind .ge. 33 .and. thisWind .lt. 43)
    polyres@gsMarkerColor = (/"yellow2"/)
    lineres@gsLineColor = (/"yellow2"/)
  else if (thisWind .ge. 43 .and. thisWind .lt. 49)
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
  else if (thisWind .ge. 49 .and. thisWind .lt. 58)
    polyres@gsMarkerColor = (/"darkorange3"/)
    lineres@gsLineColor = (/"darkorange3"/)
  else
    polyres@gsMarkerColor = (/"red"/) 
    lineres@gsLineColor = (/"red"/)
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

;******************
; Plot a legend   *
;******************

lgres                    = True

lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.20       ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.20       ; was 0.08        ; height of legend (NDC)
; lgres@lgBottomMarginF    = 0.17     ; was 0.25

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

;lgres@lgOrientation = "Horizontal"

; lgres@lgBoxMajorExtentF  = 0.4
lgres@lgBoxMinorExtentF  = 0.2  ; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

; lgres@lgBoxBackground    = "PaleTurquoise3"

lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
lgres@lgMonoMarkerIndex     = False
lgres@lgMonoLineThickness   = False
lgres@lgMonoMarkerThickness = False
lgres@lgMonoMarkerSize      = False

;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.15
lgres@lgLabelFontAspectF      = 1.5
lgres@lgLabelConstantSpacingF = 0.0

legendType = "Markers"
markerSize = .008
markerIndex = 16

if (windThresh .ge. 17) then
  lgres@lgItemCount        = 5
  lgres@lgItemTypes        = (/legendType,legendType,legendType,legendType,legendType/)
  lgres@lgMarkerIndexes    = (/markerIndex,markerIndex,markerIndex,markerIndex,markerIndex/)
  lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
  lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow2",   "green3" /) ; colors for legend lines
  legend_labels = (/"Category 4/5","Category 3","Category 2",\
                 "Category 1","Tropical Storm"/)
else
  lgres@lgItemCount        = 6
  lgres@lgItemTypes        = (/"Markers","Markers","Markers","Markers","Markers","Markers"/)
  lgres@lgMarkerIndexes    = (/      16,      16,      16,      16,      16,      16/)
  lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
  lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow",   "green",    "blue"    /) ; colors for legend lines
  legend_labels = (/"Cat. 4/5","Cat. 3","Cat. 2",\
                 "Cat. 1","TS","TD"/)
end if


legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
amres@amJust="CenterRight"
amres@amParallelPosF   =  0.49             ; move legend to the right .37 formerly
amres@amOrthogonalPosF =  0.0             ; move the legend down


annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot

  
print("Drawing plot")

resP = True
resP@gsnPanelMainString = "IBTrACS landfalls ("+ibstyr+"-"+ibenyr+")"     ; set main title
resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end


exit
