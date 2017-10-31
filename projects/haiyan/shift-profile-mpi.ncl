load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "../../functions/calc_area.ncl"
;========================================================
external EX01 "./pcmin_2013.so"
 
begin


;        SUBROUTINE PCMIN(SST,PSL,P,T,R,NA,N,PMIN,VMAX,IFL)
; C
; C   Revised on 9/24/2005 to fix convergence problems at high pressure
; C
; C   ***   This subroutine calculates the maximum wind speed        ***
; C   ***             and mimimum central pressure                   ***
; C   ***    achievable in tropical cyclones, given a sounding       ***
; C   ***             and a sea surface temperature.                 ***
; C
; C  INPUT:   SST: Sea surface temperature in C
; C
; C           PSL: Sea level pressure (mb)
; C
; C           P,T,R: One-dimensional arrays of dimension NA
; C             containing pressure (mb), temperature (C),
; C             and mixing ratio (g/kg). The arrays MUST be
; C             arranged so that the lowest index corresponds
; C             to the lowest model level, with increasing index
; C             corresponding to decreasing pressure. The temperature
; C             sounding should extend to at least the tropopause and 
; C             preferably to the lower stratosphere, however the
; C             mixing ratios are not important above the boundary
; C             layer. Missing mixing ratios can be replaced by zeros.
; C
; C           NA: The dimension of P,T and R
; C
; C           N:  The actual number of points in the sounding
; C                (N is less than or equal to NA)
; C
; C  OUTPUT:  PMIN is the minimum central pressure, in mb
; C
; C           VMAX is the maximum surface wind speed, in m/s
; C                  (reduced to reflect surface drag)
; C
; C           IFL is a flag: A value of 1 means OK; a value of 0
; C              indicates no convergence (hypercane); a value of 2
; C              means that the CAPE routine failed.

f = addfile("/glade/u/home/zarzycki/work/apply-haiyan-perturb/haiyan_48_x8_INIC_filter.nc_FULLPERT_CAM5.nc","r")
;f = addfile("/glade/u/home/zarzycki/work/apply-haiyan-perturb/haiyan_48_x8_INIC_filter.nc_NOTREAL_CAM_sfccorr.nc","r")

ix=1000
PSL = f->PS(0,ix)
T  = f->T(0,::-1,ix)
R  = f->Q(0,::-1,ix)
P0 = f->P0

hya  = f->hyam
hyb  = f->hybm

lat=f->lat
lon=f->lon


PSL = PSL/100.
T = T-273.15 ; convert to C
R = R*1000   ; convert to g/kg
NA = 22
N = 22

PMIN_2D=tofloat(PSL)
VMAX_2D=tofloat(PSL)
IFL_2D=tointeger(PSL)
copy_VarMeta(PSL,PMIN_2D)
copy_VarMeta(PSL,VMAX_2D)
copy_VarMeta(PSL,IFL_2D)


  
  P = hya*P0+hyb*(PSL*100.)
  P = P/100.
  P = P(::-1)

  SST = 29.0
  ;SST = T(0,ii,jj)+1.
  ;print(""+SST)

  PMIN = new(1,float)
  VMAX = new(1,float)
  IFL = new(1,integer)

  if (0.eq.1) then
  print(P)
  print(PSL)
  print(T)
  print(R)
  end if

  EX01::PCMIN(SST,tofloat(PSL),tofloat(P(0:21)),tofloat(T(0:21)),tofloat(R(0:21)),NA,N,PMIN,VMAX,IFL)

  print(PMIN)
  print(VMAX)
  print(IFL) ; if ne 1, error


exit

  wks = gsn_open_wks("x11" ,"ce")      ; send graphics to PNG file

  plot = new(2,graphic)                          ; create a plot array

  res                       = True     ; plot mods desired
  res@gsnDraw=False
  res@gsnFrame=False

  res@cnFillOn              = True     ; turn on color fill
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnFillPalette         = "BlAqGrYeOrRe"
  res@cnLineLabelsOn = False

  ;res@cnLevelSelectionMode =  "ManualLevels"
  ;res@cnMinLevelValF       = 880.
  ;res@cnMaxLevelValF       = 950.
  ;res@cnLevelSpacingF      =   5.0

  res@mpMaxLatF=max(lat)
  res@mpMinLatF=min(lat)
  res@mpMaxLonF=max(lon)
  res@mpMinLonF=min(lon)

  res@gsnAddCyclic          = False

  plot = gsn_csm_contour_map(wks,PMIN_2D,res)

  draw(plot)
  frame(wks)

end
