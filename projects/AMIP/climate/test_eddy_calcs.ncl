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

sixhourlyfilename = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_15/camrun.cam.h3.0001-03-01-00000.nc"
sixhourlyfile = addfile(sixhourlyfilename, "r")
monfilename = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_15/camrun.cam.h0.0001-03.nc"
monfile = addfile(monfilename, "r")

horizstride = 32

wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"

lev  = monfile->lev
time = sixhourlyfile->time

print(lev)

print("Loading the data")

T_six_native = sixhourlyfile->T(:,{850},:)
V_six_native = sixhourlyfile->V(:,{850},:)

VT_mon_native = monfile->VT(:,{850},:)
T_mon_native = monfile->T(:,{850},:)
V_mon_native = monfile->V(:,{850},:)
  
print("Regridding the data")
Opt         = True
Opt@CopyVarCoords = True
T_six_full  = ESMF_regrid_with_weights(T_six_native,wgt_file,Opt)
V_six_full  = ESMF_regrid_with_weights(V_six_native,wgt_file,Opt)
VT_mon_full  = ESMF_regrid_with_weights(VT_mon_native,wgt_file,Opt)
T_mon_full  = ESMF_regrid_with_weights(T_mon_native,wgt_file,Opt)
V_mon_full  = ESMF_regrid_with_weights(V_mon_native,wgt_file,Opt)
lat_full = T_six_full&lat
lon_full = T_six_full&lon
  
delete([/T_six_native,V_six_native,VT_mon_native/])

printVarSummary(T_six_full)

  
T_six = T_six_full(:,::horizstride,::horizstride)
print("Done with T_six")
V_six = V_six_full(:,::horizstride,::horizstride)
print("Done with V_six")
VT_mon = VT_mon_full(:,::horizstride,::horizstride)
print("Done with VT_mon")
V_mon = V_mon_full(:,::horizstride,::horizstride)
print("Done with VT_mon")
T_mon = T_mon_full(:,::horizstride,::horizstride)
print("Done with VT_mon")
lat = lat_full(::horizstride)
lon = lon_full(::horizstride)
  
;  delete([/T_full,V_full,lat_full,lon_full/])

print("Interpolating to vertical levels")

;Tlev = lev({900:800})
;print(Tlev)
;printVarSummary(T)
;T850_interp = int2p_n_Wrap(Tlev,T,(/ 850. /),2,1)
;T850 = rm_single_dims(T850_interp)
;delete(T)
;delete(Tlev)
;
;Vlev = lev({900:800})
;V850_interp = int2p_n_Wrap(Vlev,V,(/ 850. /),2,1)
;V850 = rm_single_dims(V850_interp)
;delete(V)
;delete(Vlev)

;printVarSummary(V850)

V850 = rm_single_dims(V_six)
T850 = rm_single_dims(T_six)
VTmon = rm_single_dims(VT_mon)
Vmon = rm_single_dims(V_mon)
Tmon = rm_single_dims(T_mon)

vt = fluxEddy(T850(lat|:,lon|:,time|:),V850(lat|:,lon|:,time|:))

sizes = (dimsizes(Vmon))
nlat = sizes(0)
nlon = sizes(1)

V_zonal = dim_avg_n_Wrap(Vmon,1)
T_zonal = dim_avg_n_Wrap(Tmon,1)
VT_zonal = V_zonal
VT_zonal = V_zonal*T_zonal
V_diff = Vmon
T_diff = Tmon

VTmon_ = Vmon

do i = 0,nlon-1
  V_diff(:,i) = Vmon(:,i) - V_zonal(:)
  T_diff(:,i) = Tmon(:,i) - T_zonal(:)
  ;VTmon_(:,i) = VTmon(:,i) - VT_zonal(:)
end do

VTmon_ = VTmon - Vmon*Tmon

;VTmon_ = Vmon
;VTmon_ = VTmon - 

printVarSummary(vt)

vt!0    = "lat"                      ; assign named dimensions
vt!1    = "lon"
       
vt&lat = T850&lat
vt&lon = T850&lon

  wks = gsn_open_wks("x11","eddy") 
  plot = new(2,graphic)
  gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap

  res                       = True               ; plot mods desired
  res@cnFillOn              = True               ; turn on color fill
  res@cnLinesOn             = False              ; turn off contour lines
  res@gsnDraw  = False                          ; don't draw
  res@gsnFrame = False                          ; don't advance frame

;---This resource not needed in V6.1.0
  res@gsnSpreadColors       = True               ; use full range of color map

  plot(0) = gsn_csm_contour_map_ce(wks,vt,res)
  plot(1) = gsn_csm_contour_map_ce(wks,VTmon_,res)
  
  gsn_panel(wks,plot,(/2,1/),False)
  
end
