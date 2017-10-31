;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

ncol = 2
modeldata = readAsciiTable("test.txt", ncol, "float", 0)
data_c1 = readAsciiTable("lvc1.txt", ncol, "float", 0)
data_c2 = readAsciiTable("lvc2.txt", ncol, "float", 0)
data_c3 = readAsciiTable("lvc3.txt", ncol, "float", 0)
data_c4 = readAsciiTable("lvc4.txt", ncol, "float", 0)
data_c5 = readAsciiTable("lvc5.txt", ncol, "float", 0)

modeldata(22,1)=-6

wks   = gsn_open_wks ("x11","xy")                  ; open workstation

res                   = True
res@gsnMaximize      = True
res@gsnPaperOrientation = "portrait"
res@gsnDraw          = False
res@gsnFrame         = False
;res@tiMainString      = "Multiple XY plot"
res@xyLineThicknessF = 4.0
res@xyLineColor      = "blue"
res@tiXAxisString = "Time (days)"
res@tiYAxisString = "SST anom. (K)"

res@trYMinF = min(modeldata(:,1))-0.25
res@trYMaxF = 0.5
res@trXMinF = -20
res@trXMaxF = 20

plot  = gsn_csm_xy (wks,data_c1(:,0),data_c1(:,1),res) ; create plot
plotc2  = gsn_csm_xy (wks,data_c2(:,0),data_c2(:,1),res) ; create plot
overlay(plot,plotc2)
plotc3  = gsn_csm_xy (wks,data_c3(:,0),data_c3(:,1),res) ; create plot
overlay(plot,plotc3)
plotc4  = gsn_csm_xy (wks,data_c4(:,0),data_c4(:,1),res) ; create plot
overlay(plot,plotc4)
plotc5  = gsn_csm_xy (wks,data_c5(:,0),data_c5(:,1),res) ; create plot
overlay(plot,plotc5)

res@xyLineColor     = "red"
plot1 = gsn_csm_xy(wks,modeldata(:,0),modeldata(:,1),res)
overlay(plot,plot1)

zlineres = True
zlineres@gsLineColor = "gray"
zlineres@gsLineThicknessF = 4.0
zlineres@tfPolyDrawOrder = "Draw" ;Force polylines to be behind plot
dummy_horiz = gsn_add_polyline(wks,plot,(/-1000,1000/),(/0,0/),zlineres)
dummy_vert = gsn_add_polyline(wks,plot,(/0,0/),(/-1000,1000/),zlineres)

draw(plot)
frame(wks)

exit

end
