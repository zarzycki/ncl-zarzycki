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

;tail -n +2 file.txt (remove header)
filename = "/glade/u/home/zarzycki/met_files/out_tcmpr.tcst"
;thedate = "20121023_120000"
thename="SANDY"
outtype="pdf"

date_map = (/4,2,2,1,2,4/)
dateSplit = str_split_by_length(thedate, date_map)
print(dateSplit)

yrStr=dateSplit(0)
monStr=dateSplit(1)
dayStr=dateSplit(2)
hourStr=dateSplit(4)

doLabel=True
if (.not. isdefined("panelStr"))
  print("no panel string")
  doLabel=False
end if

if (.not. isdefined("doLeg"))
  print("no legend")
  doLeg=False
end if

;sleep(5)

lines = asciiread(filename,-1,"string")


markerTypes = (/2,5,1/)

FillValue = -999.9
lineDash    = (/          0,           0,           0,           0,           0,           0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,            0,     2,    15,       0 /)
lineThick  = (/         1.0,         1.0,         1.0,         1.0,         1.0,         1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,          3.5,   4.5,   4.5,     4.5 /)
colorArray = (/"steelblue1","steelblue1","steelblue1","steelblue1","steelblue1","steelblue1","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","pink2","green2", "red4", "red2", "black" /)
models     = (/"CAM"       ,  "CAMC"    ,"CAM6"      ,"CAMX"      ,"CAMY"      ,"CAMH"      ,"AP01","AP02","AP03","AP04","AP05","AP06","AP07","AP08","AP09","AP10","AP11","AP12","AP13","AP14","AP15","AP16","AP17","AP18","AP19","AP20",      "CAMZ" ,"GFSO","AEMN",  "BEST" /)

print(dimsizes(lineThick))
print(dimsizes(colorArray))
print(dimsizes(models))

plotArrayLat = new((/dimsizes(models),50/),"float")
plotArrayLon = new((/dimsizes(models),50/),"float")

;CAMMEAN_ArrayLat = new((/1,50/),"float")
;CAMMEAN_ArrayLon = new((/1,50/),"float")
CAM_idx = (/0,1,2,3,4,5/)

ms_to_kts = 1.94384449

;print(lines)

delim = " "

;VERSION AMODEL BMODEL STORM_ID BASIN CYCLONE STORM_NAME INIT            LEAD    VALID           INIT_MASK VALID_MASK LINE_TYPE TOTAL INDEX LEVEL WATCH_WARN INITIALS ALAT     ALON       BLAT     BLON      TK_ERR     X_ERR       Y_ERR       ALTK_ERR    CRTK_ERR    ADLAND      BDLAND     AMSLP BMSLP AMAX_WIND BMAX_WIND AAL_WIND_34 BAL_WIND_34 ANE_WIND_34 BNE_WIND_34 ASE_WIND_34 BSE_WIND_34 ASW_WIND_34 BSW_WIND_34 ANW_WIND_34 BNW_WIND_34 AAL_WIND_50 BAL_WIND_50 ANE_WIND_50 BNE_WIND_50 ASE_WIND_50 BSE_WIND_50 ASW_WIND_50 BSW_WIND_50 ANW_WIND_50 BNW_WIND_50 AAL_WIND_64 BAL_WIND_64 ANE_WIND_64 BNE_WIND_64 ASE_WIND_64 BSE_WIND_64 ASW_WIND_64 BSW_WIND_64 ANW_WIND_64 BNW_WIND_64
;V4.1    CARQ   BEST   AL012012 AL    01      ALBERTO    20120519_120000 -120000 20120519_000000 NA        NA         TCMPR     3     1     LO    NA         X        33.10000 -76.80000  33.10000 -77.00000 10.05247   10.05247    0.00000     -2.70744    -9.67913    80.55836    73.46449   NA    1010  25        25        0.00000     NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA
VERSION = str_get_field(lines,1,delim)
AMODEL = str_get_field(lines,2,delim)
BMODEL = str_get_field(lines,3,delim)
STORM_ID = str_get_field(lines,4,delim)
BASIN = str_get_field(lines,5,delim)
CYCLONE = str_get_field(lines,6,delim)
STORM_NAME = str_get_field(lines,7,delim)
INIT = str_get_field(lines,8,delim)
LEAD = toint(str_get_field(lines,9,delim))/10000
VALID = str_get_field(lines,10,delim)
INIT_MASK  = str_get_field(lines,11,delim)
VALID_MASK = str_get_field(lines,12,delim)
LINE_TYPE = str_get_field(lines,13,delim)
TOTAL = toint(str_get_field(lines,14,delim))
INDEX = toint(str_get_field(lines,15,delim))
LEVEL = str_get_field(lines,16,delim)
WATCH_WARN = str_get_field(lines,17,delim)
INITIALS = str_get_field(lines,18,delim)
ALAT = tofloat(str_get_field(lines,19,delim))
ALON = tofloat(str_get_field(lines,20,delim))
BLAT = tofloat(str_get_field(lines,21,delim))
BLON = tofloat(str_get_field(lines,22,delim))
TK_ERR = tofloat(str_get_field(lines,23,delim))
X_ERR = tofloat(str_get_field(lines,24,delim))
Y_ERR = tofloat(str_get_field(lines,25,delim))
ALTK_ERR = tofloat(str_get_field(lines,26,delim))
CRTK_ERR = tofloat(str_get_field(lines,27,delim))
ADLAND = tofloat(str_get_field(lines,28,delim))
BDLAND = tofloat(str_get_field(lines,29,delim))
AMSLP = tofloat(str_get_field(lines,30,delim))
BMSLP = tofloat(str_get_field(lines,31,delim))
AMAX_WIND = tofloat(str_get_field(lines,32,delim))
BMAX_WIND = tofloat(str_get_field(lines,33,delim))
;AAL_WIND_34 = str_get_field(lines,34,delim)
;BAL_WIND_34 = str_get_field(lines,35,delim)

latChar = stringtocharacter(str_strip(str_get_field(lines,19,delim)))
lonChar= stringtocharacter(str_strip(str_get_field(lines,20,delim)))
latDir = (latChar(:,3))
lonDir = (lonChar(:,3))

latDirStr = new(dimsizes(latDir),"string")
lonDirStr = new(dimsizes(lonDir),"string")
do k = 0,dimsizes(latDir)-1
  latDirStr(k) = chartostring(latDir(k))
  lonDirStr(k) = chartostring(lonDir(k))
end do

ALAT@_FillValue = FillValue
ALON@_FillValue = FillValue
ALAT = where(latDirStr .eq. "S",-ALAT,ALAT)
ALON = where(lonDirStr .eq. "W",360.-ALON,ALON)

ALAT = where(STORM_NAME.eq.thename,ALAT,ALAT@_FillValue)
ALAT = where(INIT.eq.thedate,ALAT,ALAT@_FillValue)
ALON = where(STORM_NAME.eq.thename,ALON,ALON@_FillValue)
ALON = where(INIT.eq.thedate,ALON,ALON@_FillValue)

BLAT@_FillValue = FillValue
BLON@_FillValue = FillValue
BLAT = where(latDirStr .eq. "S",-BLAT,BLAT)
BLON = where(lonDirStr .eq. "W",360.-BLON,BLON)

BLAT = where(STORM_NAME.eq.thename,BLAT,BLAT@_FillValue)
BLAT = where(INIT.eq.thedate,BLAT,BLAT@_FillValue)
BLON = where(STORM_NAME.eq.thename,BLON,BLON@_FillValue)
BLON = where(INIT.eq.thedate,BLON,BLON@_FillValue)

LEAD = where(STORM_NAME.eq.thename,LEAD,LEAD@_FillValue)
LEAD = where(INIT.eq.thedate,LEAD,LEAD@_FillValue)


do j = 0,dimsizes(models)-1

if (j .eq. dimsizes(models)-1) then
  print("HERE")
  CMZLat = where (AMODEL .eq. "AEMN",BLAT,BLAT@_FillValue)
  CMZLon = where (AMODEL .eq. "AEMN",BLON,BLON@_FillValue)
  CMZLead = where(AMODEL .eq. "AEMN",LEAD,LEAD@_FillValue)
else
  CMZLat = where(AMODEL .eq. models(j),ALAT,ALAT@_FillValue)
  CMZLon = where(AMODEL .eq. models(j),ALON,ALON@_FillValue)
  CMZLead = where(AMODEL .eq. models(j),LEAD,LEAD@_FillValue)
end if

  do i = 0,dimsizes(CMZLat)-1
    if (.not. ismissing(CMZLead(i))) then
      if (mod(CMZLead(i),6) .eq. 0) then
        index=toint(CMZLead(i)/6)
        plotArrayLat(j,index)=CMZLat(i)
        plotArrayLon(j,index)=CMZLon(i)
      end if
    end if
  end do

  delete(CMZLat)
  delete(CMZLon)
  delete(CMZLead)
end do

; Do CAM mean
CAM_mean_lat_arr = plotArrayLat
CAM_mean_lon_arr = plotArrayLon
do z = 0,dimsizes(models)-1
  if (any(CAM_idx.eq.z))
    print(models(z)+" is a CAM member.")
  else
    CAM_mean_lat_arr(z,:) = CAM_mean_lat_arr@_FillValue
    CAM_mean_lon_arr(z,:) = CAM_mean_lon_arr@_FillValue
  end if
end do

CAM_mean_lat = dim_avg_n_Wrap(CAM_mean_lat_arr,0)
CAM_mean_lon = dim_avg_n_Wrap(CAM_mean_lon_arr,0)

delete(CAM_mean_lat_arr)
delete(CAM_mean_lon_arr)



;********************************************
   wks = gsn_open_wks(outtype,"sandytrajpdfs/sandy_traj_"+thedate)               ; open workstation
   res            = True                          ; map resources
   res@gsnDraw    = False                         ; don't draw
   res@gsnFrame   = False                         ; don't advance frame
   res@mpMaxLatF  = 50                           ; select subregion
   res@mpMinLatF  = 11 
   res@mpMinLonF  = 275
   res@mpMaxLonF  = 325

   res@mpOceanFillColor = "white"      ; orig. "lightsteelblue1"
  
   res@mpLandFillColor = "tan" ;
   res@mpInlandWaterFillColor = "white"      ; orig. "lightsteelblue1"
   res@mpOutlineOn = True
   
  ; res@mpMaxLatF  = 45                           ; select subregion
  ; res@mpMinLatF  = 25 
  ; res@mpMinLonF  = 310
  ; res@mpMaxLonF  = 325

   ;res@tiMainString    = "Sandy Numerical Forecasts"  ; title
   res@gsnCenterString = hourStr+"Z "+dayStr+" October "+yrStr ; center string
  
   map = gsn_csm_map_ce(wks,res)                         ; create map
   ;draw(map)
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

   lineres = True

   mres  = True                               ; marker resources
   first = True                               ; start of traj resources
;********************************
; counter variable
   ;do i = 0,dimsizes(lat)-1

; add markers to the trajectories
      ;mres@gsMarkerIndex  = 16           ; marker style (circle)
      ;mres@gsMarkerSizeF  = 4.0          ; marker size


     ; pres@gsMarkerColor  = markerColors(0)
     ; gsn_polymarker(wks,map,CMZLon,CMZLat,pres)

;do i = 0,dimsizes(models)-1
;      pres@gsMarkerColor  = markerColors(i)
;      gsn_polymarker(wks,map,plotArrayLon(i,:),plotArrayLat(i,:),pres)
;end do

dum1 = new((/dimsizes(models),50/),graphic)

do i = 0,dimsizes(models)-1
  lineres@gsLineColor = colorArray(i)
  lineres@gsLineThicknessF = lineThick(i)
  lineres@gsLineDashPattern = lineDash(i)
  ;if (i .eq. dimsizes(models)-1) then
  ;  lineres@gsLineDashPattern = 2
  ;end if
  do k = 0,50-2
    lon1=plotArrayLon(i,k)
    lon2=plotArrayLon(i,k+1)
    lat1=plotArrayLat(i,k)
    lat2=plotArrayLat(i,k+1)
    if (.not. ismissing(lat1) .AND. .not. ismissing(lat2)) then
      dum1(i,k) = gsn_add_polyline(wks,map,(/plotArrayLon(i,k),plotArrayLon(i,k+1)/),(/plotArrayLat(i,k),plotArrayLat(i,k+1)/),lineres)
    end if
  end do
end do

  delete(lineres@gsLineDashPattern)

dum2 = new((/1,50/),graphic)

  lineres@gsLineColor = "steelblue3"
  lineres@gsLineThicknessF = 4.5
  lineres@gsLineDashPattern = 15
  do k = 0,50-2
    lon1=CAM_mean_lon(k)
    lon2=CAM_mean_lon(k+1)
    lat1=CAM_mean_lat(k)
    lat2=CAM_mean_lat(k+1)
    if (.not. ismissing(lat1) .AND. .not. ismissing(lat2)) then
      dum2(0,k) = gsn_add_polyline(wks,map,(/lon1,lon2/),(/lat1,lat2/),lineres)
    end if
  end do

;******************
; Plot a legend   *
;******************
if (doLeg) then
lgres                    = True

lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.25      ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.25       ; was 0.08        ; height of legend (NDC)
; lgres@lgBottomMarginF    = 0.17     ; was 0.25

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

;lgres@lgOrientation = "Horizontal"

; lgres@lgBoxMajorExtentF  = 0.4
lgres@lgBoxMinorExtentF  = 0.2  ; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

; lgres@lgBoxBackground    = "PaleTurquoise3"

lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
lgres@lgMonoLineThickness   = False
lgres@lgMonoDashIndex       = False

;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.06
;lgres@lgLabelFontAspectF      = 1.2
lgres@lgLabelConstantSpacingF = 0.0

lgres@lgItemCount        = 7
;lgres@lgLineDashSegLenF  = 6.0

lgres@lgLineThicknesses  = (/4.5,4.5,1.0,4.5,1.0,4.5,3.5/) 
lgres@lgLineThicknesses = lgres@lgLineThicknesses(::-1)

lgres@lgItemTypes        = (/"Lines","Lines","Lines","Lines","Lines","Lines","Lines"/)
lgres@lgItemTypes=lgres@lgItemTypes(::-1)

lgres@lgLineColors       = (/ "black","red4","pink2","red2","steelblue3","steelblue1","green"/) ; colors for legend lines
lgres@lgLineColors =lgres@lgLineColors (::-1)

lgres@lgDashIndexes      = (/0,2,0,15,0,15,0/) ; dash indexes
lgres@lgDashIndexes =lgres@lgDashIndexes(::-1)

legend_labels =            (/"Obs.","GFS","GEFS member","GEFS mean","CAM member","CAM mean","CAM-CLUBB"/)
legend_labels=legend_labels(::-1)

legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
amres@amParallelPosF   = 0.30               ; move legend to the right
amres@amOrthogonalPosF = 0.17            ; move the legend down

annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot
end if

if (doLabel) then
  txres=True
  txres@txBackgroundFillColor = "White"
  txres@txPerimOn             = True
  txres@txFontHeightF         = 0.032

  txid = gsn_create_text(wks, panelStr, txres)
  amtxres=True
  amtxres@amParallelPosF   =  0.48    ; This is the center of the plot.
  amtxres@amOrthogonalPosF = -0.48    ; This is the top edge of the plot.
  amtxres@amJust           = "TopRight"
  annoid3 = gsn_add_annotation(map, txid, amtxres)
end if

;******************
; Plot a legend   *
;******************

draw(map)
frame(wks)    
  
end
