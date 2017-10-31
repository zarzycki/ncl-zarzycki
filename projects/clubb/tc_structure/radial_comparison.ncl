;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "../../radial_plots/radialAvg.ncl"
;========================================================
begin

models = (/"cam5","clubb"/)
figure_colors = models
nfiles = dimsizes(models)
whattime = 0
nlev = 30
stride = 2
topLev = 100
botLev = 1015
eps=1e-16 ; prevent div 0

all_files = "/glade/u/home/zarzycki/scratch/cam5_work/tc_cam5_ne120/camrun.cam.h2.2000-01-09-00000.nc"
in1      = addfile (all_files, "r")
lev = in1->lev({topLev:botLev})
lev@units = "hPa"
nlev = dimsizes(lev)

array3D = new((/nfiles,nlev/),"float")


;figure_labels = (/"control","slab","modtau900","clubb","nodeep"/)
figure_labels = models
;figure_colors = (/"red","blue","green","orange","purple"/)
figure_linethck = (/9.0,9.0,9.0,9.0,9.0/)

do filepick = 0,nfiles-1
thisModel = models(filepick)

print("Doing file number: "+(filepick+1)+" of: "+nfiles)

if( thisModel .eq. "cam5" ) then 
  all_files = "/glade/u/home/zarzycki/scratch/cam5_work/tc_cam5_ne120/camrun.cam.h2.2000-01-09-00000.nc"
  in1      = addfile (all_files, "r")
  figure_colors(filepick) = "red"
end if
if( thisModel .eq. "clubb" ) then 
  all_files = "/glade/u/home/zarzycki/scratch/cam5_work/tc_clubb_ne120/camrun.cam.h2.2000-01-09-00000.nc"
  in1      = addfile (all_files, "r")
  figure_colors(filepick) = "blue"
end if


lat = in1->lat(::stride)
lon = in1->lon(::stride)
nlat = dimsizes(lat)
nlon = dimsizes(lon)

U = in1->U(whattime,{topLev:botLev},::stride,::stride)
V = in1->V(whattime,{topLev:botLev},::stride,::stride)
T = in1->T(whattime,{topLev:botLev},::stride,::stride)
PRECT = in1->PRECT(whattime,::stride,::stride)
PRECT = PRECT*86400*1000 ; convert to mm/day
PRECL = in1->PRECL(whattime,::stride,::stride)
PRECL = PRECL*86400*1000 ; convert to mm/day
PRECC = in1->PRECC(whattime,::stride,::stride)
PRECC = PRECC*86400*1000 ; convert to mm/day
PS1 = in1->PS(whattime,::stride,::stride)
FLUT = in1->FLUT(whattime,::stride,::stride)
SST = in1->SST(whattime,::stride,::stride)
U10 = in1->U10(whattime,::stride,::stride)
DTCOND = in1->DTCOND(whattime,{topLev:botLev},::stride,::stride)
DTCOND = DTCOND*3600
CLOUD = in1->CLOUD(whattime,{topLev:botLev},::stride,::stride)
OMEGA = in1->OMEGA(whattime,{topLev:botLev},::stride,::stride)
OMEGA850 = in1->OMEGA(whattime,{850},::stride,::stride)
OMEGA500 = in1->OMEGA(whattime,{500},::stride,::stride)
Q = in1->Q(whattime,{topLev:botLev},::stride,::stride)

PRECRAT=PRECT
PRECRAT=PRECC/(PRECT+eps)

;---FIND LOCATIONS OF PSMIN and WINDMAX
;---Convert to 1D
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
;---Resolve the 1D indices back to their original 3D array.
a_indices  = ind_resolve(minind(a1D),dsizes_a)
;---Convert index to lat/lon points
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))
delete([/a_indices,dsizes_a,a1D,a/])

print("calculating wind")
WIND = U
WIND = sqrt(U^2+V^2)

print("Calculating temp anamoly")
Tanom = T
Tref = T(:,{psminlat},{psminlon-5.})
Tanom = T - conform(T,Tref,0)
delete(Tref)

Qanom = Q
Qref = Q(:,{psminlat},{psminlon-5.})
Qanom = Q - conform(Q,Qref,0)
delete(Qref)

radius_3D=300.
var_radint = radialInt3D(tofloat(DTCOND),tofloat(lat),tofloat(lon),tofloat(lev),psminlat,psminlon,radius_3D)
array3D(filepick,:) = var_radint
delete(array3D@long_name) 
delete(array3D@units) 

radius_2D=750.
rad_var = radialAvg2D(PRECT,lat,lon,psminlat,psminlon,radius_2D,True)
if (filepick .eq. 0) then
  nrad=dimsizes(rad_var)
  array2D = new((/nfiles,nrad/),"float")
  radius = rad_var&radius
end if
array2D(filepick,:) = tofloat(rad_var)

delete([/var_radint,FLUT,Q,SST,OMEGA,OMEGA500,OMEGA850,CLOUD,WIND,U,V,PS1,T,Tanom,Qanom,PRECT,PRECL,PRECC,PRECRAT,DTCOND,U10,psminlat,psminlon,lat,lon/])

end do

wks   = gsn_open_wks ("pdf","pdf/2D_PRECT_conv")                   ; open workstation
res                   = True                       ; plot mods desired
res@tiMainString      = "PRECT radial average"             ; add title
res@xyExplicitLegendLabels = figure_labels ; create explicit labels 
res@xyLineColors       = figure_colors  ; 4 different color
res@xyLineThicknesses  = figure_linethck               ; change line thickness
res@pmLegendDisplayMode    = "Always"                      ; turn on legend
res@lgAutoManage = False
res@pmLegendSide           = "Bottom"                      ; Change location of 
res@pmLegendParallelPosF   = .60                           ; move units right
res@pmLegendOrthogonalPosF = -.60                         ; move units down
res@pmLegendWidthF         = 0.1                          ; Change width and
res@pmLegendHeightF        = 0.1                           ; height of legend.
res@lgPerimOn              = False                         ; turn off box around
res@lgLabelFontHeightF     = .015                          ; label font height
plot  = gsn_csm_xy (wks,radius,array2D,res) ; create plot

;==================================================================================

wks   = gsn_open_wks ("pdf","pdf/vert_DTCOND_conv")                   ; open workstation
res                   = True                       ; plot mods desired
res@tiMainString      = "DTCOND integrated "+radius_3D+" km"           ; add title
res@trYReverse        = True                       ; reverse Y-axis
res@xyYStyle          = "Log"
res@tmYLMode          = "Explicit"                ; explicit labels
res@tmYLValues        = (/1000,925,850,725,600,500,400,300,200,100/)
res@tmYLLabels        = ""+res@tmYLValues         ; make strings

res@xyExplicitLegendLabels = figure_labels ; create explicit labels 
res@xyLineColors       = figure_colors  ; 4 different color
res@xyLineThicknesses  = figure_linethck               ; change line thickness
res@pmLegendDisplayMode    = "Always"                      ; turn on legend
res@lgAutoManage = False
res@pmLegendSide           = "Bottom"                      ; Change location of 
res@pmLegendParallelPosF   = .20                           ; move units right
res@pmLegendOrthogonalPosF = -.60                         ; move units down
res@pmLegendWidthF         = 0.1                          ; Change width and
res@pmLegendHeightF        = 0.1                           ; height of legend.
res@lgPerimOn              = False                         ; turn off box around
res@lgLabelFontHeightF     = .015                          ; label font height

printVarSummary(array3D)
printVarSummary(lev)

plot  = gsn_csm_xy (wks,array3D,lev,res) ; create plot






end

