;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;system("cd /glade/proj3/mich1098/zarzycki/plot_files")

;hsitarball = "h3.1982-07-29-to-1983-02-06.tar"
;system("htar -xv -f "+hsitarball+" atl_30_x4_refine_nochem.cam.h3.1982-09-02-00000.nc")
;system("htar -xv -f h1.1982-07-29-to-1983-02-06.tar atl_30_x4_refine_nochem.cam.h1.1982-09-02-00000.nc")
 
h1file = addfile("/glade/proj3/mich1098/zarzycki/plot_files/atl_30_x4_refine_nochem.cam.h1.1982-09-02-00000.nc","r")
h3file = addfile("/glade/proj3/mich1098/zarzycki/plot_files/atl_30_x4_refine_nochem.cam.h3.1982-09-02-00000.nc","r")

horizstride = 8

lev  = h3file->lev
timeh3 = h3file->time
lat = h3file->lat(::horizstride)
lon = h3file->lon(::horizstride)

SST = h1file->SST(:,::horizstride,::horizstride)

time = 2

T = h3file->T(time,{800:400},::horizstride,::horizstride)
Tlev = h3file->lev({800:400})
T600 = int2p_n_Wrap(Tlev,T,(/ 600. /),2,0)
;T850 = rm_single_dims(T850)
delete(T)
delete(Tlev)

Q = h3file->Q(time,{800:400},::horizstride,::horizstride)
Qlev = h3file->lev({800:400})
Q600 = int2p_n_Wrap(Qlev,Q,(/ 600. /),2,0)
delete(Q)
delete(Qlev)

U = h3file->U(time,{1000:100},::horizstride,::horizstride)
Ulev = h3file->lev({1000:100})
U200 = int2p_n_Wrap(Ulev,U,(/ 200. /),2,0)
U850 = int2p_n_Wrap(Ulev,U,(/ 850. /),2,0)
delete(U)
delete(Ulev)

V = h3file->V(time,{1000:100},::horizstride,::horizstride)
Vlev = h3file->lev({1000:100})
V200 = int2p_n_Wrap(Vlev,V,(/ 200. /),2,0)
V850 = int2p_n_Wrap(Vlev,V,(/ 850. /),2,0)
delete(V)
delete(Vlev)

P600 = conform(T600,600.*100.,-1)
P600@_FillValue = 9.969209968386869e+36

RH600 = relhum(T600(0,:,:),Q600(0,:,:),P600(0,:,:))
RH600 = RH600 < 100

USHEAR = U850
VSHEAR = V850
USHEAR = U850 - U200
VSHEAR = V850 - V200
TOTSHEAR = U850
TOTSHEAR = sqrt(USHEAR^2 + VSHEAR^2)

;************************************************
; calculate vorticity on a Fixed Grid
; scale for visual convenience
;************************************************

;vr = U(:,0,:,:)
;vr = uv2dv_cfd(U(:,0,:,:),V(:,0,:,:),tofloat(lat),tofloat(lon),3)*10^5

VR850 = V850
VR850 = uv2vr_cfd(U850,V850,lat,lon,2)

AVR850 = VR850
omega = 7.2921e-5
pi = 3.1415926



; MPI

A = 28.2
B = 55.8
C = 0.1813
VPOT = V850
VPOT(0,:,:) = A + B * exp(C*(SST(0,:,:)-303.15))

GPI = VPOT

printVarSummary(AVR850)
printVarSummary(VR850)

do i = 0,dimsizes(lat)-1
do j = 0,dimsizes(lon)-1
AVR850(0,i,j) = VR850(0,i,j) + tofloat(2*omega*sin(lat(i)*(pi/180.)))
end do
end do

GPI(0,:,:) = abs(1e5*AVR850(0,:,:))^(3/2) * (RH600(:,:)/50)^(3) * (VPOT(0,:,:)/70)^(3) * (1 + 0.1*TOTSHEAR(0,:,:))^(-2)
;GPI(0,:,:) = TOTSHEAR(0,:,:)

;print(max(vr))
;print(min(vr))
;vr@long_name = "vorticity"
;vr@units     = "scaled"

;**************** PLOT

 plot_type  = "x11"   ; plot types: ps,x11
 plot_name  = "vorticity"
 wks = gsn_open_wks(plot_type,plot_name)

;----------- Global resources -----------------------------------------
  
  res                 = True
  res@cnFillOn		  = True
  res@cnLinesOn   = False
  
  res@mpMaxLatF                   = 30           ; choose subregion           
  res@mpMinLatF                   = 0
  res@mpMinLonF = 250. 
  res@mpMaxLonF = 320. 
  
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 0
  res@cnMaxLevelValF        = 20
  res@cnLevelSpacingF       = 2      ; contour spacing
  
  res@gsnSpreadColors = True
  
;  gsn_define_colormap(wks,"BlWhRe")              ; choose colormap
  gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap

  plot = gsn_csm_contour_map(wks,GPI(0,:,:),res)    
  
end
