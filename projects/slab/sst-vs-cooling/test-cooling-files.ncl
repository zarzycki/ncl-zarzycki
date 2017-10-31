;========================================================
; Reads a trajectory file and calculates the fraction of CW
; under TC center due to new parameterization and due to fluxes
; outputs a NetCDF file which contains these fractions to be plotted
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

; =========================================================
af=addfile("dSST_offline_SSTA_slab_.nc","r")

a_pres=af->traj_pres
a_wind=af->traj_wind
a_SST=af->SST
a_dSST=af->dSST

 wks = gsn_open_wks ("x11","scatter")            ; open workstation

 res                   = True                     ; plot mods desired
 res@gsnMaximize       = True

 res@tiMainString      = "least-squares polynomial fit (lspoly)"
 res@xyMarkLineModes   = (/"Markers"/)

 res@xyMarker          =  16                  ; Change type, size, and
 res@xyMarkerSizeF     = 0.008                ; color of marker
 res@xyMarkerColor     = "purple4"

 plot = gsn_csm_xy (wks, a_wind(::10), a_dSST(::10), res)


end

