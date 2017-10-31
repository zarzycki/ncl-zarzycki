;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/bearing.ncl"
load "/glade/u/home/zarzycki/ncl/functions/LLfromDistBear.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

;---------------User settings----------------------------

slab1File="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab.txt_CATTED.nc"
slab2File="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab3.txt_CATTED.nc"
labStr1="SLAB"
labStr2="THERMO"

out_type = "pdf"

stormType="as" ; hurr or as

if (stormType .eq. "hurr") then
  minWind=32.0
  maxWind=999.0
  stormTypeStr="hurr."
else if (stormType .eq. "as") then
  minWind=0.0
  maxWind=999.0
  stormTypeStr="TCs"
else
  print("invalid storm type")
  exit
end if
end if

latBox=1.0

f1=addfile(slab1File,"r")
SSTanom1=f1->SSTanom(:,:,:,{latBox})
traj_wind1=f1->traj_10m_wind
voverf1=f1->voverf
offsetArr1=SSTanom1&time

f2=addfile(slab2File,"r")
SSTanom2=f2->SSTanom(:,:,:,{latBox})
traj_wind2=f2->traj_10m_wind
voverf2=f2->voverf
offsetArr2=SSTanom2&time

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

SSTanom1_all=SSTanom1
SSTanom1_slow=SSTanom1
SSTanom1_fast=SSTanom1
SSTanom1_td=SSTanom1
SSTanom1_ts=SSTanom1
SSTanom1_c1=SSTanom1
SSTanom1_c2=SSTanom1
SSTanom1_c3=SSTanom1
SSTanom1_c4=SSTanom1
SSTanom1_c5=SSTanom1

do j = 0,dimsizes(SSTanom1&time)-1
  SSTanom1_all(j,:,:)=where(traj_wind1 .ge. minWind .and. traj_wind1 .le. maxWind,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_slow(j,:,:)=where(traj_wind1 .ge. minWind .and. traj_wind1 .le. maxWind .and. voverf1 .lt. 1.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_fast(j,:,:)=where(traj_wind1 .ge. minWind .and. traj_wind1 .le. maxWind .and. voverf1 .gt. 1.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_td(j,:,:) = where(traj_wind1 .ge. 000.0 .and. traj_wind1 .lt. 017.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_ts(j,:,:) = where(traj_wind1 .ge. 017.0 .and. traj_wind1 .lt. 032.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_c1(j,:,:) = where(traj_wind1 .ge. 032.0 .and. traj_wind1 .lt. 042.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_c2(j,:,:) = where(traj_wind1 .ge. 042.0 .and. traj_wind1 .lt. 049.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_c3(j,:,:) = where(traj_wind1 .ge. 049.0 .and. traj_wind1 .lt. 058.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_c4(j,:,:) = where(traj_wind1 .ge. 058.0 .and. traj_wind1 .lt. 070.0,SSTanom1(j,:,:),SSTanom1@_FillValue)
  SSTanom1_c5(j,:,:) = where(traj_wind1 .ge. 070.0                           ,SSTanom1(j,:,:),SSTanom1@_FillValue)
end do

SSTanom2_all=SSTanom2
SSTanom2_slow=SSTanom2
SSTanom2_fast=SSTanom2
SSTanom2_td=SSTanom2
SSTanom2_ts=SSTanom2
SSTanom2_c1=SSTanom2
SSTanom2_c2=SSTanom2
SSTanom2_c3=SSTanom2
SSTanom2_c4=SSTanom2
SSTanom2_c5=SSTanom2

do j = 0,dimsizes(SSTanom2&time)-1
  SSTanom2_all(j,:,:)=where(traj_wind2 .ge. minWind .and. traj_wind2 .le. maxWind,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_slow(j,:,:)=where(traj_wind2 .ge. minWind .and. traj_wind2 .le. maxWind .and. voverf2 .lt. 1.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_fast(j,:,:)=where(traj_wind2 .ge. minWind .and. traj_wind2 .le. maxWind .and. voverf2 .gt. 1.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_td(j,:,:) = where(traj_wind2 .ge. 000.0 .and. traj_wind2 .lt. 017.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_ts(j,:,:) = where(traj_wind2 .ge. 017.0 .and. traj_wind2 .lt. 032.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_c1(j,:,:) = where(traj_wind2 .ge. 032.0 .and. traj_wind2 .lt. 042.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_c2(j,:,:) = where(traj_wind2 .ge. 042.0 .and. traj_wind2 .lt. 049.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_c3(j,:,:) = where(traj_wind2 .ge. 049.0 .and. traj_wind2 .lt. 058.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_c4(j,:,:) = where(traj_wind2 .ge. 058.0 .and. traj_wind2 .lt. 070.0,SSTanom2(j,:,:),SSTanom2@_FillValue)
  SSTanom2_c5(j,:,:) = where(traj_wind2 .ge. 070.0                           ,SSTanom2(j,:,:),SSTanom2@_FillValue)
end do

;======================================================================================

print("num fast moving points: "+num(SSTanom1_fast(0,:,:)))
avgSSTfast1=dim_avg_n_Wrap(SSTanom1_fast,(/1,2/))

print("num slow moving points: "+num(SSTanom1_slow(0,:,:)))
avgSSTslow1=dim_avg_n_Wrap(SSTanom1_slow,(/1,2/))

print("all points: "+num(SSTanom1_all(0,:,:)))
avgSSTall1=dim_avg_n_Wrap(SSTanom1_all,(/1,2/))



print("num fast moving points: "+num(SSTanom2_fast(0,:,:)))
avgSSTfast2=dim_avg_n_Wrap(SSTanom2_fast,(/1,2/))

print("num slow moving points: "+num(SSTanom2_slow(0,:,:)))
avgSSTslow2=dim_avg_n_Wrap(SSTanom2_slow,(/1,2/))

print("all points: "+num(SSTanom2_all(0,:,:)))
avgSSTall2=dim_avg_n_Wrap(SSTanom2_all,(/1,2/))

;======================================================================================

; GET DATA
ncol = 2
data_as = readAsciiTable("../lvas.txt", ncol, "float", 0)
data_c1 = readAsciiTable("../lvc1.txt", ncol, "float", 0)
data_c2 = readAsciiTable("../lvc2.txt", ncol, "float", 0)
data_c3 = readAsciiTable("../lvc3.txt", ncol, "float", 0)
data_c4 = readAsciiTable("../lvc4.txt", ncol, "float", 0)
data_c5 = readAsciiTable("../lvc5.txt", ncol, "float", 0)

do zz = 0,2

if (zz .eq. 0) then
  speed="slow"
  avgSSTvTIME1=avgSSTslow1
  avgSSTvTIME2=avgSSTslow2
  plot_refs=True
  panelStr="c."
  plotTitle = "SSTA - slow "+stormTypeStr
else if (zz .eq. 1) then
  speed="fast"
  avgSSTvTIME1=avgSSTfast1
  avgSSTvTIME2=avgSSTfast2
  plot_refs=False
  panelStr="b."
  plotTitle = "SSTA - fast "+stormTypeStr
else
  speed="all"
  avgSSTvTIME1=avgSSTall1
  avgSSTvTIME2=avgSSTall2
  plot_refs=False
  panelStr="a."
  plotTitle = "SSTA - all "+stormTypeStr
end if
end if

wks   = gsn_open_wks ("pdf","SSTvTIME_"+speed+"_"+minWind+"_"+maxWind)

res                   = True
res@gsnMaximize      = True
res@gsnPaperOrientation = "portrait"
res@gsnDraw          = False
res@gsnFrame         = False
;res@tiMainString      = "SST rel. to TC passage; slab1; "+speed+" "+minWind+"_"+maxWind+" m/s"
res@tiMainString = plotTitle

;res@xyLineColor      = "blue"
res@tiXAxisString = "Time relative to passage (days)"
res@tiYAxisString = "SST anom. (K)"

;res@trYMinF = min((/-2.0,min(avgSSTvTIME1)/))-0.25
if (stormType .eq. "hurr") then
  res@trYMinF = min((/-2.0,min(avgSSTvTIME1)/))-0.25  
else
  res@trYMinF = min(avgSSTvTIME1)-0.25
end if
;res@trYMaxF = 0.5
res@trYMaxF = abs(res@trYMinF)*.2
res@trXMinF = -20
res@trXMaxF = 40

res@xyLineThicknessF = 4.0
res@xyLineColor     = "blue"
plot = gsn_csm_xy(wks,offsetArr1,avgSSTvTIME1,res)

res@xyLineThicknessF = 4.0
res@xyLineColor     = "red"
plot2 = gsn_csm_xy(wks,offsetArr2,avgSSTvTIME2,res)
overlay(plot,plot2)

if(plot_refs)
  res@xyLineThicknessF = 1.0

  res@xyLineColor      = "darkgreen"
  plot1  = gsn_csm_xy (wks,data_c1(:,0),data_c1(:,1),res) ; create plot
  overlay(plot,plot1)

  res@xyLineColor      = "darkgreen"
  plotc2  = gsn_csm_xy (wks,data_c2(:,0),data_c2(:,1),res) ; create plot
  overlay(plot,plotc2)

  res@xyLineColor      = "darkgreen"
  plotc3  = gsn_csm_xy (wks,data_c3(:,0),data_c3(:,1),res) ; create plot
  overlay(plot,plotc3)

  res@xyLineColor      = "darkgreen"
  plotc4  = gsn_csm_xy (wks,data_c4(:,0),data_c4(:,1),res) ; create plot
  overlay(plot,plotc4)

  res@xyLineColor      = "darkgreen"
  plotc5  = gsn_csm_xy (wks,data_c5(:,0),data_c5(:,1),res) ; create plot
  overlay(plot,plotc5)

  res@xyLineColor      = "darkgreen"
  ;plotas  = gsn_csm_xy (wks,data_as(:,0),data_as(:,1),res) ; create plot
  ;overlay(plot,plotas)
end if

zlineres = True
zlineres@gsLineColor = "gray90"
zlineres@gsLineThicknessF = 4.0
zlineres@tfPolyDrawOrder = "Draw" ;Force polylines to be behind plot
dummy_horiz = gsn_add_polyline(wks,plot,(/-1000,1000/),(/0,0/),zlineres)
dummy_vert = gsn_add_polyline(wks,plot,(/0,0/),(/-1000,1000/),zlineres)

;***********************************************
; legend resources
;***********************************************

lgres                    = True

lgres@lgMonoDashIndex = False
lgres@lgMonoLineThickness = False
lgres@lgItemType         = "Lines"
if(plot_refs)
  labelStr=(/"LV2011",labStr1,labStr2/)
  lgres@lgLineColors     = (/"darkgreen","blue","red"/)
  lgres@lgLineThicknesses   = (/1.0,4.0,4.0/)
  lgres@lgDashIndexes = (/0,0,0/)
else
  labelStr=(/labStr1,labStr2/)
  lgres@lgLineColors     = (/"blue","red"/)
  lgres@lgLineThicknesses   = (/4.0,4.0/)
  lgres@lgDashIndexes = (/0,0/)
end if
lgres@lgLabelFontHeightF = .08            ; set the legend label font thickness
lgres@vpWidthF           = 0.15           ; width of legend (NDC)
lgres@vpHeightF          = 0.1            ; height of legend (NDC)
lgres@lgPerimColor       = "Black"       ; draw the box perimeter in orange
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lbid = gsn_create_legend(wks,dimsizes(labelStr),labelStr,lgres)

amres = True
amres@amParallelPosF   = 0.35		    ; move legend to the right
amres@amOrthogonalPosF = 0.05             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

txres               = True
txres@txFontHeightF = 0.045
txres@txBackgroundFillColor="White"
txres@txPerimOn=True
txres@txPerimColor="Black"
txres@amJust           = "BottomRight"
text1 = gsn_add_text(wks,plot,panelStr,res@trXMaxF,res@trYMinF,txres)

draw(plot)
frame(wks)

delete(plot)
delete(lgres)
delete(res)
delete(amres)
delete(dummy_horiz)
delete(dummy_vert)
delete(zlineres)
delete(wks)
delete(labelStr)

end do


;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

