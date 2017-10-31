;========================================================
; Load a h1 file from AMIP run and test TC tracker
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================

begin

debug=False

year=1992
month=09
day=17
hour=18
cen_lat=20.25
cen_lon=268.25
plot_off = 10.0

; Do stuff automatically
filedir="/glade/u/home/zarzycki/scratch/h1files/atl30x4/1992/TEST/"
filename="atl_30_x4_refine_nochem.cam.h1.1992-09-17-00000.nc"
thefile=addfile(filedir+"/"+filename,"r")
timestep=toint(hour/3)

; Get data
PSL=thefile->PSL(timestep,:,:)
U850=thefile->U850(timestep,:,:)
V850=thefile->V850(timestep,:,:)
VR850=thefile->VR850(timestep,:,:)

VR850 = VR850*10^5

;VR850 = V850
;VR850 = uv2vrF(U850,V850)
VR850 = smth9_Wrap(VR850, 0.50, 0.50, False)

;printVarSummary(PSL)

;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("x11","testtracker")               ; open workstation
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")   ; choose colormap
  res                     = True         ; plot modifications desired
  res@gsnDraw		= False		; Don't draw plots
  res@gsnFrame		= False		; Don't advance frame
  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@cnFillOn            = True         ; Turn on contour fill
  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels
  
  resVR=res
  resVR@cnLevelSelectionMode = "ManualLevels"  ; set explicit contour levels
  resVR@cnMinLevelValF  = -50.
  resVR@cnMaxLevelValF  = 50.
  resVR@cnLevelSpacingF = 5.
  
  map1 = gsn_csm_contour(wks,VR850({cen_lat-plot_off:cen_lat+plot_off},{cen_lon-plot_off:cen_lon+plot_off}),resVR)
  res@cnFillOn = False
  res@cnLinesOn = True
  map2 = gsn_csm_contour(wks,PSL({cen_lat-plot_off:cen_lat+plot_off},{cen_lon-plot_off:cen_lon+plot_off}),res)

  overlay(map1,map2)
  
  draw(map1)
  frame(wks)

end
