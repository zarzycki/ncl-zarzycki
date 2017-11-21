load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin
  wks = gsn_open_wks("pdf","gsn_merge_colormaps")
;
; Merge two pre-defined colormaps;
;
  gsn_merge_colormaps(wks,"BlAqGrYeOrReVi200","rainsnowradar")
  gsn_draw_colormap(wks)

end