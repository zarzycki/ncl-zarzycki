;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================
begin

offsetArr = fspan(-20, 20, 41)

SSTArr=(/ \
0.1823994, \
0.1876457, \
0.1986758, \
0.2017912, \
0.1317411, \
0.1252931, \
0.1352357, \
0.1491235, \
0.1631892, \
0.1667313, \
0.1603248, \
0.1550955, \
0.1612511, \
0.1642368, \
0.1567725, \
0.1398957, \
0.1267625, \
0.1137614, \
0.09344611, \
0.03018213, \
-0.9820202, \
-1.628991, \
-1.295873, \
-1.008749, \
-0.7683356, \
-0.5765313, \
-0.4203257, \
-0.3006502, \
-0.209922, \
-0.1278042, \
-0.06163583, \
-0.01431284, \
0.02694177, \
0.05266695, \
0.07637077, \
0.08661233, \
0.05927299, \
0.05734591, \
0.06422989, \
0.07578376, \
0.08883791 \
/)



wks   = gsn_open_wks ("x11","xy")                ; open workstation

res                  = True                     ; plot mods desired

plot  = gsn_csm_xy (wks,offsetArr,SSTArr,res) ; create plot

end

