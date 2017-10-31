;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
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

;outFileName="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab_08_11.75_900.txt_CATTED.nc"
outFileName="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab3.txt_CATTED.nc"

out_type = "pdf"

minWind=0.0
maxWind=999.0
latBox=5.0

f=addfile(outFileName,"r")
SSTanom=f->SSTanom(:,:,:,{latBox})
traj_wind=f->traj_10m_wind
voverf=f->voverf
offsetArr=SSTanom&time

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

SSTanom_all=SSTanom
SSTanom_slow=SSTanom
SSTanom_fast=SSTanom
SSTanom_td=SSTanom
SSTanom_ts=SSTanom
SSTanom_c1=SSTanom
SSTanom_c2=SSTanom
SSTanom_c3=SSTanom
SSTanom_c4=SSTanom
SSTanom_c5=SSTanom

do j = 0,dimsizes(SSTanom&time)-1
  SSTanom_all(j,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_slow(j,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .lt. 1.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_fast(j,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .gt. 1.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_td(j,:,:) = where(traj_wind .ge. 000.0 .and. traj_wind .lt. 017.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_ts(j,:,:) = where(traj_wind .ge. 017.0 .and. traj_wind .lt. 032.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c1(j,:,:) = where(traj_wind .ge. 032.0 .and. traj_wind .lt. 042.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c2(j,:,:) = where(traj_wind .ge. 042.0 .and. traj_wind .lt. 049.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c3(j,:,:) = where(traj_wind .ge. 049.0 .and. traj_wind .lt. 058.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c4(j,:,:) = where(traj_wind .ge. 058.0 .and. traj_wind .lt. 070.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c5(j,:,:) = where(traj_wind .ge. 070.0                           ,SSTanom(j,:,:),SSTanom@_FillValue)
end do

maxSSTanom = new(8,"float")
maxSSTanom(0)=min(dim_avg_n_Wrap(SSTanom_all,(/1,2/)))
maxSSTanom(1)=min(dim_avg_n_Wrap(SSTanom_td,(/1,2/)))
maxSSTanom(2)=min(dim_avg_n_Wrap(SSTanom_ts,(/1,2/)))
maxSSTanom(3)=min(dim_avg_n_Wrap(SSTanom_c1,(/1,2/)))
maxSSTanom(4)=min(dim_avg_n_Wrap(SSTanom_c2,(/1,2/)))
maxSSTanom(5)=min(dim_avg_n_Wrap(SSTanom_c3,(/1,2/)))
maxSSTanom(6)=min(dim_avg_n_Wrap(SSTanom_c4,(/1,2/)))
maxSSTanom(7)=min(dim_avg_n_Wrap(SSTanom_c5,(/1,2/)))

numSSTanom = new(8,"integer")
numSSTanom(0)=num(SSTanom_all)
numSSTanom(1)=num(SSTanom_td)
numSSTanom(2)=num(SSTanom_ts)
numSSTanom(3)=num(SSTanom_c1)
numSSTanom(4)=num(SSTanom_c2)
numSSTanom(5)=num(SSTanom_c3)
numSSTanom(6)=num(SSTanom_c4)
numSSTanom(7)=num(SSTanom_c5)

print(maxSSTanom)

print("num fast moving points: "+num(SSTanom_fast(0,:,:)))
avgSSTfast=dim_avg_n_Wrap(SSTanom_fast,(/1,2/))
print(avgSSTfast)

print("num slow moving points: "+num(SSTanom_slow(0,:,:)))
avgSSTslow=dim_avg_n_Wrap(SSTanom_slow,(/1,2/))
print(avgSSTslow)

print("all points: "+num(SSTanom_all(0,:,:)))
avgSSTall=dim_avg_n_Wrap(SSTanom_all,(/1,2/))
print(avgSSTall)

;======================================================================================

outFileName="text/maxSSTanom_"+latBox+".txt"

rowsForCSV=dimsizes(maxSSTanom)
maxSSTLabelArr=new(rowsForCSV,"string")
maxSSTLabelArr=(/"AS","TD","TS","C1","C2","C3","C4","C5"/)

system("rm "+outFileName)
do j = 0,rowsForCSV-1
  system("echo "+maxSSTLabelArr(j)+","+maxSSTanom(j)+","+numSSTanom(j)+","+latBox+" >> "+outFileName)
end do

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
  avgSSTvTIME=avgSSTslow
  plot_refs=True
else if (zz .eq. 1) then
  speed="fast"
  avgSSTvTIME=avgSSTfast
  plot_refs=False
else
  speed="all"
  avgSSTvTIME=avgSSTall
  plot_refs=False
end if
end if

wks   = gsn_open_wks ("pdf","SSTvTIME_"+speed+"_"+minWind+"_"+maxWind)

res                   = True
res@gsnMaximize      = True
res@gsnPaperOrientation = "portrait"
res@gsnDraw          = False
res@gsnFrame         = False
res@tiMainString      = "SST rel. to TC passage; slab1; "+speed+" "+minWind+"_"+maxWind+" m/s"

;res@xyLineColor      = "blue"
res@tiXAxisString = "Time relative to passage (days)"
res@tiYAxisString = "SST anom. (K)"

res@trYMinF = min((/-2.0,min(avgSSTslow)/))-0.25
res@trYMaxF = 0.5
res@trXMinF = -20
res@trXMaxF = 40

res@xyLineThicknessF = 6.0
res@xyLineColor     = "blue"
plot = gsn_csm_xy(wks,offsetArr,avgSSTvTIME,res)

if(plot_refs)
  res@xyLineThicknessF = 1.25

  res@xyLineColor      = "magenta4"
  plot1  = gsn_csm_xy (wks,data_c1(:,0),data_c1(:,1),res) ; create plot
  overlay(plot,plot1)

  res@xyLineColor      = "magenta3"
  plotc2  = gsn_csm_xy (wks,data_c2(:,0),data_c2(:,1),res) ; create plot
  overlay(plot,plotc2)

  res@xyLineColor      = "magenta2"
  plotc3  = gsn_csm_xy (wks,data_c3(:,0),data_c3(:,1),res) ; create plot
  overlay(plot,plotc3)

  res@xyLineColor      = "magenta1"
  plotc4  = gsn_csm_xy (wks,data_c4(:,0),data_c4(:,1),res) ; create plot
  overlay(plot,plotc4)

  res@xyLineColor      = "magenta"
  plotc5  = gsn_csm_xy (wks,data_c5(:,0),data_c5(:,1),res) ; create plot
  overlay(plot,plotc5)

  res@xyLineColor      = "magenta"
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
  labelStr=(/"LV2011","This study"/)
  lgres@lgLineColors     = (/"magenta1","blue"/)
  lgres@lgLineThicknesses   = (/1.25,6.0/)
  lgres@lgDashIndexes = (/0,0/)
else
  labelStr=(/"This study"/)
  lgres@lgLineColors     = (/"blue"/)
  lgres@lgLineThicknesses   = (/6.0/)
  lgres@lgDashIndexes = (/0/)
end if
lgres@lgLabelFontHeightF = .08            ; set the legend label font thickness
lgres@vpWidthF           = 0.15           ; width of legend (NDC)
lgres@vpHeightF          = 0.1            ; height of legend (NDC)
lgres@lgPerimColor       = "Black"       ; draw the box perimeter in orange
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lbid = gsn_create_legend(wks,dimsizes(labelStr),labelStr,lgres)

amres = True
amres@amParallelPosF   = 0.35		    ; move legend to the right
amres@amOrthogonalPosF = 0.30             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

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

