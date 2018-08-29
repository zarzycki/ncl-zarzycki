; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "../../../functions/radialAvg.ncl"

begin

f1=addfile("/glade/u/home/zarzycki/scratch/RCE.QPC6.ne0np4tcfplane.ne15x8/run/newcyclone30x4_clubb_k10-0.6-CDFLAT/tmp.nc","r")
f2=addfile("/glade/u/home/zarzycki/scratch/CLUBB/CAM5-TC-test-VR/newcyclone30x8_CAM5/tmp.nc","r")

U10_1=f1->U10
U10_2=f2->U10
U10_1D_1=ndtooned(U10_1)
U10_1D_2=ndtooned(U10_2)

CD_1=f1->CD
CD_2=f2->CD
CD_1D_1=ndtooned(CD_1)*1000
CD_1D_2=ndtooned(CD_2)*1000

 wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file

 res                  = True                     ; plot mods desired
 res@tiMainString     = "Basic XY plot"          ; add title
 res@xyMarkLineModes   = "Markers"                ; choose which have markers
 res@xyMarkers         =  16                      ; choose type of marker  
 res@xyMarkerColor     = "red"                    ; Marker color
 res@xyMarkerSizeF     = 0.01                     ; Marker size (default 0.01)

 stride=8
 plot  = gsn_csm_xy (wks,U10_1D_1(::stride),CD_1D_1(::stride),res) ; create plot

end
