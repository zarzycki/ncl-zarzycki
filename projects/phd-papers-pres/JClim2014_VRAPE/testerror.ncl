; ===========================================
; hov_5.ncl
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; ===========================================
begin

    timeStride = 4   ; number of time samples to stride by

; ;---Names of source and weight file
; ;    src_file = "/glade/p/work/mlevy/HOMME_APE/uniform_15/camrun.cam.h1.0000-10-28-00000.nc"
     src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h2_0002.ncror"
     wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"
     wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"
; 
; ;---Open files containing source HOMME and destination FV grids
     sfile = addfile(src_file,"r")

end
