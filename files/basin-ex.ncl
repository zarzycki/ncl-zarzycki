
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/global/homes/c/czarzyck/ncl-zarzycki/functions/mask_tc.ncl"
; ================================================;
begin

out_type="png"
in = addfile("USGS_gtopo30_0.23x0.31_remap_c180612_PHIS_LANDFRAC.nc","r")
var  = in->LANDFRAC
lat = var&lat
lon = var&lon

themask = var
do ii = 0,dimsizes(lat)-1
  do jj = 0,dimsizes(lon)-1
    themask(ii,jj) = mask_tc_latlon(lat(ii),lon(jj))
  end do
end do

wks = gsn_open_wks(out_type,"basins")          ; send graphics to PNG file

res                   = True
res@mpGridLatSpacingF = 30.               ; spacing for lat lines
res@mpGridLonSpacingF = 30.               ; spacing for lon lines
res@mpFillOn          = False

res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines

contour = gsn_csm_contour_map(wks,themask,res)  ; create the plot
  
end
