;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
;========================================================
begin

output_type="x11"
smooth_traj=True    ; do a running average on lat/lon to produce smoother PSL trajs
underlayPop=True




;;; JRA
; 1993 blizzard -- 21,1993
; 2010 snowmaggedon -- 7,2010
; 2016 jonas,snowzilla -- 6,2016
stormID=6
year=2016
trajfile="/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/tempest.JRA."+year+"."+year
stormfile="/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.JRA."+year+"."+year+".5e-9_12.nc.tempest.nc"


;;; LENS
;ensmem="035"
;stormID=346
;year=1990
;trajfile="/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/tempest.LENS."+year+"."+ensmem
;stormfile="/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS."+year+"."+ensmem+".5e-9_12.nc.tempest.nc"

if (underlayPop) then
  popFile=addfile("/glade/u/home/zarzycki/snow-tracking/gen_pop_files/population.nc","r")
  POP=popFile->POP
  POP=POP/1000.
end if

ncols = 9                     ; assign number of columns

delim = ","

ncases = dimsizes(trajfile)
print("Doing "+ncases+"  number of cases")
  
maxLines = -1
traj_data = getTrajectories(trajfile,ncols,maxLines)

ndims = dimsizes(traj_data)
nstorms = ndims(0)
ncols   = ndims(1)
ntimes  = ndims(2)

lon = traj_data(stormID,2,:)
lat = traj_data(stormID,3,:)
pres = traj_data(stormID,4,:)/100.
yyyy = toint(traj_data(stormID,5,:))
mm = toint(traj_data(stormID,6,:))
dd = toint(traj_data(stormID,7,:))
hh = toint(traj_data(stormID,8,:))

yyyystr = sprinti("%04d",yyyy)
mmstr = sprinti("%02d",mm)
ddstr = sprinti("%02d",dd)
hhstr = sprinti("%02d",hh)

f = addfile(stormfile,"r")

SNOW=f->CUM_SNOWFALL(stormID,:,:)
SNOW=SNOW*12
SNOW=where(ismissing(SNOW),0.0,SNOW)

; Smoother?
if (smooth_traj) then
  cleanix = ind(.not.ismissing(lon))
  loncl=lon(cleanix)
  latcl=lat(cleanix)
  nave = 3
  opt = 1
  loncl = runave_Wrap(loncl,nave,opt)
  latcl = runave_Wrap(latcl,nave,opt)
  lat(min(cleanix):max(cleanix))=latcl
  lon(min(cleanix):max(cleanix))=loncl
end if

;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(output_type,"./pdf/single-storm-traj")
map = new(1,graphic)

res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "gray70"
res@mpOceanFillColor = "steelblue" ;"LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
res@mpGeophysicalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
 
res@mpMinLatF             = 30
res@mpMaxLatF             = 50
res@mpMinLonF             = 270
res@mpMaxLonF             = 300

res@mpProjection = "Orthographic"
res@mpLimitMode           = "LatLon"
res@mpCenterLatF      =  45.
res@mpCenterLonF      =  280.

res@mpOutlineDrawOrder = "Draw"

res@cnFillDrawOrder             = "PreDraw"
res@mpFillAreaSpecifiers        = (/"Land"/)
res@mpSpecifiedFillColors       = (/"transparent"/)

if (underlayPop) then
  res@lbLabelBarOn = False

  res@cnFillOn            = True         ; Turn on contour fill

  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels
  res@cnInfoLabelOn = False 

  res@cnFillMode          = "RasterFill"
  res@cnLevelSelectionMode = "ExplicitLevels"                     ; set explicit contour levels
  cmap = read_colormap_file("GMT_gray")
  res@cnFillPalette = cmap(::-1,:)     ; reverse color map
  delete(cmap)

  res@cnLevels    = (/ 10,15,25,50,100/) ; set levels
  
  map = gsn_csm_contour_map(wks,POP,res)
else
  map = gsn_csm_map(wks,res)
end if

cnres=True
cnres@gsnDraw=False
cnres@gsnFrame=False

cnres@gsnSpreadColors     = True         ; Use full colormap, but start
cnres@cnFillOn            = True         ; Turn on contour fill
cnres@cnLinesOn           = False        ; Turn off contour lines
cnres@cnLineLabelsOn      = False        ; Turn off contour line labels
cnres@cnInfoLabelOn = False 

cnres@lbLabelBarOn = False

cnres@cnFillMode          = "AreaFill"

cnres@cnFillDrawOrder             = "PreDraw"

cnres@cnLevelSelectionMode = "ExplicitLevels"
cnres@cnLevels    = (/ 1., 4., 10., 20., 30./)
if (underlayPop) then
  snowColors = (/"black","gray80","white","lightskyblue","dodgerblue3","tomato"/)
else
  snowColors = (/"gray70","gray85","white","lightskyblue","dodgerblue3","tomato"/)
end if
snowColorsRGBA=namedcolor2rgba(snowColors)
if (underlayPop) then
  ; set main opacity and then low contour opacity (i.e., sub 1" snow)
  snowColorsRGBA(:,3)=0.6
  snowColorsRGBA(0,3)=0.5
  ;snowColorsRGBA(5,3)=0.5
end if
cnres@cnFillColors=snowColorsRGBA

; plot snow and overlay onto map
mpid=gsn_csm_contour(wks,SNOW,cnres)
overlay(map,mpid)

;gsn_define_colormap(wks,"rainbow+white+gray")
polyres               = True          ; poly marker mods desired 
polyres@gsMarkerIndex = 1            ; choose circle as polymarker
polyres@gsMarkerSizeF = 0.07

polyresBack=polyres
polyresBack@gsMarkerSizeF = 0.1
polyresBack@gsMarkerColor = (/"black"/) 

polyres@tfPolyDrawOrder = "PostDraw"

dum = new((/2,ntimes/),graphic)
  ;linethicknesses = (/1.5,1.5,1.5,1.5,2.0,2.5/)
  linethicknesses = (/1.0,2.0,3.0,3.0,3.0,3.0/)
  linethicknesses = linethicknesses * 3.0

mbthresh=(/1010,1000,990,980,970/)

cmap = RGBtoCmap("cb-mono-orange-rgb.txt")
print(cmap)

do j = 0,ntimes-1

  thisPres=pres(j)

  if (.not.ismissing(thisPres))

    print(hh(j)+" "+pres(j)+" "+lon(j)+" "+lat(j))

    if (thisPres .gt. mbthresh(0))
      polyres@gsMarkerColor = cmap(0,:)
    else if (thisPres .ge. mbthresh(1) .and. thisPres .lt. mbthresh(0))
      polyres@gsMarkerColor = cmap(1,:)
    else if (thisPres .ge. mbthresh(2) .and. thisPres .lt. mbthresh(1))
      polyres@gsMarkerColor = cmap(2,:)
    else if (thisPres .ge. mbthresh(3) .and. thisPres .lt. mbthresh(2))
      polyres@gsMarkerColor = cmap(3,:)
    else if (thisPres .ge. mbthresh(4) .and. thisPres .lt. mbthresh(3))
      polyres@gsMarkerColor = cmap(4,:)
    else
      polyres@gsMarkerColor = cmap(5,:)
    end if
    end if
    end if
    end if
    end if
  
   txres               = True                            
   txres@txFontHeightF = 0.01             ; Set the font height
  
    ;if (j .ne. 0) then
    ;  dum(j) = gsn_add_polymarker(wks,map,(/lon(j),lon(j-1)/),(/lat(j),lat(j-1)/),lineres)
    ;end if

    if (j .ne. -1) then
      dum(0,j) = gsn_add_polymarker(wks,map,(/lon(j)/),(/lat(j)/),polyresBack)
      dum(1,j) = gsn_add_polymarker(wks,map,(/lon(j)/),(/lat(j)/),polyres)
    end if
  
  end if

end do


;******************
; Plot a legend   *
;******************

lgres                    = True

lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.23       ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.20       ; was 0.08        ; height of legend (NDC)

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

lgres@lgBoxMinorExtentF  = 0.2	; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
lgres@lgMonoMarkerIndex     = False
lgres@lgMonoLineThickness   = False
lgres@lgMonoMarkerThickness = False
lgres@lgMonoMarkerSize      = False

;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.09
lgres@lgLabelFontAspectF      = 1.4
lgres@lgLabelConstantSpacingF = 0.0

legendType = "Markers"
markerSize = 0.02
markerIndex = 16

lgres@lgItemCount        = 6
;lgres@lgLineDashSegLenF  = 0.8
lgres@lgItemTypes        = (/"Markers","Markers","Markers","Markers","Markers","Markers"/)
lgres@lgMarkerIndexes    = (/      16,      16,      16,      16,      16,      16/)
lgres@lgMarkerSizes  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
lgres@lgMarkerColors       = (/ cmap(5,:),     cmap(4,:),  cmap(3,:),  cmap(2,:),  cmap(1,:),    cmap(0,:)    /) ; colors for legend lines
;lgres@lgDashIndexes      = (/      0,          0,          0,         0,               0,      0      /) ; dash indexes
legend_labels = (/"<"+mbthresh(4)+"mb",""+mbthresh(4)+"-"+mbthresh(3)+"mb",""+mbthresh(3)+"-"+mbthresh(2)+"mb",\
               ""+mbthresh(2)+"-"+mbthresh(1)+"mb",""+mbthresh(1)+"-"+mbthresh(0)+"mb",">"+mbthresh(0)+"mb"/)

legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
amres@amJust = "BottomRight"
amres@amParallelPosF   = 0.49		    ; move legend to the right .37 formerly
amres@amOrthogonalPosF = 0.49             ; move the legend down

annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot
  




; label bar
nboxes = 5                            ; # of labelbar boxes

quote = inttochar(34)
lblabels    = (/"1-4"+quote,"4-10"+quote,"10-20"+quote,"20-30"+quote,"30"+quote+"+"/)

lbres                           = True
lbres@lbAutoManage              = False         ; we control label bar
lbres@lbFillColors              = snowColors(1:5)
lbres@lbMonoFillPattern         = True          ; one pattern, all solid

lbres@vpWidthF           = 0.15       ; was 0.08        ; width of legend (NDC)
lbres@vpHeightF          = 0.20       ; was 0.08        ; height of legend (NDC)

lbres@lbPerimOn = True
lbres@lbPerimFill        = 0
lbres@lbPerimFillColor   = "Background"

lbres@lbLabelFontHeightF = 0.018

lbres@lbBoxMinorExtentF  = 0.2	; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

;lbres@lbLabelFontHeightF      = 0.09
;lbres@lbLabelFontAspectF      = 1.4
;lbres@lbLabelConstantSpacingF = 0.0

lbid = gsn_create_labelbar(wks,nboxes,lblabels,lbres)

amres2=True
amres2@amJust = "BottomRight"
amres2@amParallelPosF   = 0.29		    ; move legend to the right .37 formerly
amres2@amOrthogonalPosF = 0.49             ; move the legend down

annoid2 = gsn_add_annotation(map,lbid,amres2)



print("Drawing plot")

resP = True
resP@amJust           = "TopLeft"

resP@gsnPanelFigureStrings= (/"ST: "+yyyystr(0)+"-"+mmstr(0)+"-"+ddstr(0)+" "+hhstr(0)+"Z"/)
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot





end
