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

outfile = addfile("/glade/scratch/zarzycki/atl30x8amip/1986/atl_30_x4_refine_nochem.cam.h3.1986-01-02-00000.nc", "r")

lon=outfile->lon
lat=outfile->lat
T=outfile->T(:,0,:,:)

printVarSummary(T)



Tpivot = lonPivot(T, 180) ; reorder
printVarSummary(Tpivot)

T50 = Tpivot(:,:,{-50:60})

printVarSummary(T50)

end
