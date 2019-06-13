
begin

STYR="1990"
ENSMEM="001"
STORMFILT="False"

if (STYR .eq. "1990")
  NYEARS=16.
else
  NYEARS=10.
end if

fswe=addfile("./data/H2OSNO_"+ENSMEM+"_"+STYR+".nc","r")
fpre=addfile("./data/PRECT_"+ENSMEM+"_"+STYR+".nc","r")
frun=addfile("./data/QRUNOFF_"+ENSMEM+"_"+STYR+".nc","r")
stormfile="./find-storms/dailyfilter_"+ENSMEM+"_"+STYR+".txt"

;ST=330
;EN=450
;swe=fswe->H2OSNO(ST:EN)
;pre=fpre->PRECT(ST:EN)
;run=frun->QRUNOFF(ST:EN)
;time=fswe->time(ST:EN)

swe=fswe->H2OSNO
pre=fpre->PRECT
run=frun->QRUNOFF
time=fswe->time

ntimes=dimsizes(time)

dswe = swe
dswe = 0.
dswe(0:ntimes-2) = swe(1:ntimes-1) - swe(0:ntimes-2)

;print(max(run))
;print(dswe+" "+pre+" "+run)


lines = asciiread(stormfile,-1,"string")
delim = " "
datevar  =  toint(str_get_field(lines,1,delim))
tfvar = str_get_field(lines,2,delim)
dtime_map = (/4,2,2/)
splitDate = str_split_by_length(datevar,dtime_map)
yyyystr=splitDate(:,0)
mmstr=splitDate(:,1)
ddstr=splitDate(:,2)
zerostr=toint(ddstr)
zerostr=0

opt=0
opt@calendar=time@calendar
stormcal=cd_inv_calendar(toint(yyyystr),toint(mmstr),toint(ddstr),zerostr,zerostr,zerostr,time@units,opt)
minstormcal=min(stormcal)
maxstormcal=max(stormcal)

;************************************************
; plotting parameters
;************************************************
  wks   = gsn_open_wks ("png","xy")               ; send graphics to PNG file
 
  res                   = True                     ; plot mods desired
  res@gsnMaximize       = True                     ; maximize plot
  res@gsnPaperOrientation = "portrait"

; PANEL PLOT SPECIFIC RESOURCES
  res@gsnDraw               = False
  res@gsnFrame              = False            ; don't advance frame

; TURN OFF TICKMARKS AND TOP LABELS FOR SPACING (TURN THEM ON INDIVIDUALLY)
  res@tmXTOn                = False            ; turn off top labels
  res@tmYROn                = False            ; turn off right labels

; X AND Y LABELS
  Font = 0.015
  Position = 0.005
  res@tmYLLabelFontHeightF = Font
  res@tmXBLabelFontHeightF = Font
  res@tmXTLabelFontHeightF = Font
  res@tiMainFontHeightF    = Font
  res@tiYAxisFontHeightF   = Font
  res@tiXAxisFontHeightF   = Font
  res@tiMainFontHeightF    = Font
  res@tiMainOffsetYF = Position       ; Move text up or down from plot boundary

; SET MARKERS
  res@xyMarkLineMode    = "Markers"                ; choose to use markers
  res@xyMarkerSizeF     = Font*1.25                    ; Marker size (default 0.01)

  res@gsnXRefLine                 = 0

; SET X-AXIS
  res@trYMinF       = 0    ; 0 inches
  res@trYMaxF       = 75 ; +3 inches

; SET Y-AXIS
  res@trXMinF       = -30 ; -1/2 inch
  res@trXMaxF       = 30 ; +1/2 inch


; TICKMARK SETTINGS
  res@tmXBMode         = "Manual"
  res@tmYLMode         = "Manual"
  res@tmYLTickSpacingF = 10
  res@tmXBTickSpacingF = 3

; SET PERIOD SPECIFIC DETAILS (MAKE SURE TO PUT RESOURCES FOR ALL PLOTS ABOVE THIS)
  res = res
  res@xyMarkerColors     = "white"               ; Marker color
  res@xyMarkers         =  7                      ; choose type of marker (7 = up triangle)
  res@xyMarkerOpacityF = 0.0 ; make markers transparent = 0.0

  res@tiXAxisString      = "+0 day dSWE (mm/day)"
  res@tiYAxisString      = "Precipitation (mm/day)"
  res@tiMainString      = "LENS001~C~SusquehannaRiverBasin"           ; add title

  plot  = gsn_csm_xy (wks,dswe,dswe,res)

; Create xy marker array
  markers = new(ntimes,graphic)

; Plot each xy marker individually now based on variable 3 magnitude (e.g., runoff)

ROSCOUNT=0
HIGHROFCOUNT=0
HIGHPRECTCOUNT=0

do ii=0,ntimes-1

if (time(ii) .ge. minstormcal .and. time(ii) .le. maxstormcal)

iz = ind(time(ii) .eq. stormcal)
stormTF = tfvar(iz)

if (stormTF .eq. STORMFILT)


; Set marker size based on variable 3 (e.g., runoff)
   marker_res = True
   marker_res@gsMarkerColor = "blue"

 if (.not.all(ismissing(run(ii)))) then
   if (run(ii) .ge. 0 .and. run(ii) .lt. 2) then
     marker_res@gsMarkerIndex         =  4                      ; choose type of marker (7 = up triangle)
     marker_res@gsMarkerSizeF = 0.005
   else if (run(ii) .ge. 2 .and. run(ii) .lt. 4) then
     marker_res@gsMarkerIndex         =  4                      ; choose type of marker (7 = up triangle)
     marker_res@gsMarkerSizeF = 0.010
   else if (run(ii) .ge. 4 .and. run(ii) .lt. 6) then
     marker_res@gsMarkerIndex         =  4                      ; choose type of marker (7 = up triangle)
     marker_res@gsMarkerSizeF = 0.015
   else if (run(ii) .ge. 6 .and. run(ii) .lt. 8) then
     marker_res@gsMarkerIndex         =  4                      ; choose type of marker (7 = up triangle)
     marker_res@gsMarkerSizeF = 0.020
   else if (run(ii) .ge. 8 .and. run(ii) .lt. 10) then
     marker_res@gsMarkerIndex         =  4                      ; choose type of marker (7 = up triangle)
     marker_res@gsMarkerSizeF = 0.025
   else if (run(ii) .ge. 10) then
     marker_res@gsMarkerIndex         =  4                      ; choose type of marker (7 = up triangle)
     marker_res@gsMarkerSizeF = 0.04
   else
     print("TRO magnitude is not yet supported = ")
   end if
   end if
   end if
   end if
   end if
   end if

  end if

; Plot markers individually

 if (.not.all(ismissing(dswe(ii)))) then
  if (abs(dswe(ii)) .gt. 0.01 ) then
    if (dswe(ii) .lt. 0) then
  ; dSWE is negative, plot red
     marker_res@gsMarkerColor = "red"
  ; Plot markers individually
     markers(ii) = gsn_add_polymarker(wks,plot,dswe(ii),pre(ii),marker_res)
    else
  ; dSWE is positive, plot blue
     marker_res@gsMarkerColor = "blue"
  ; Plot markers individually
     markers(ii) = gsn_add_polymarker(wks,plot,dswe(ii),pre(ii),marker_res)
    end if

    if (dswe(ii) .lt. -5. .and. pre(ii) .gt. 5. .and. run(ii) .gt. 5.) then
      ROSCOUNT=ROSCOUNT+1
    else if (pre(ii) .gt. 5. .and. run(ii) .gt. 5.) then
      HIGHROFCOUNT=HIGHROFCOUNT+1
    else if (pre(ii) .gt. 5.) then
      HIGHPRECTCOUNT=HIGHPRECTCOUNT+1
    else
    end if
    end if
    end if

  end if

 end if

end if
end if
end do

stormsPerDecade=tofloat(ROSCOUNT)/NYEARS*10.
highROFPerDecade=tofloat(HIGHROFCOUNT)/NYEARS*10.
highPRECTPerDecade=tofloat(HIGHPRECTCOUNT)/NYEARS*10.

outFileName="file.csv"
system("echo "+stormsPerDecade+","+highROFPerDecade+","+highPRECTPerDecade+","+STYR+","+ENSMEM+","+STORMFILT+      " >> "+outFileName)


draw(plot)
frame(wks)


end
