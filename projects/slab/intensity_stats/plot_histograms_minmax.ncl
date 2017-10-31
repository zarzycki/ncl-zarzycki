;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

plot_wind = True

ncols = 12
maxLines = 300
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
traj_filename = "cat_traj_slab_08_4.7_900.txt"
slab_data = getTrajectories(traj_dir+"/"+traj_filename,ncols,maxLines)

traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
traj_filename = "cat_traj_slab_08_2.35_900.txt"
fixedSST_data = getTrajectories(traj_dir+"/"+traj_filename,ncols,maxLines)

max_wind_slab = dim_max_n(slab_data(:,5,:)*.85,1)
min_pres_slab = dim_min_n(slab_data(:,7,:)/100.,1)

max_wind_fixedSST = dim_max_n(fixedSST_data(:,5,:)*.85,1)
min_pres_fixedSST = dim_min_n(fixedSST_data(:,7,:)/100.,1)

binSettings=True
if (plot_wind) then
  binSettings@bin_min=5.0
  binSettings@bin_max=75.0
  ap  = pdfx(max_wind_slab, 10, binSettings)
  bp  = pdfx(max_wind_fixedSST, 10, binSettings)
else
  binSettings@bin_min=900.0
  binSettings@bin_max=1020.0
  ap  = pdfx(min_pres_slab, 24, binSettings)
  bp  = pdfx(min_pres_fixedSST, 24, binSettings)
end if

print("Fractional sums slab: "+sum(ap))
print("Fractional sums fixed: "+sum(bp))
print("-----------------------")

nVar    = 2
nBin    = ap@nbins          ; retrieve the number of bins

xx      = new ( (/nVar, nBin/), typeof(ap))

xx(0,:) = ap@bin_center
xx(1,:) = bp@bin_center

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap /)
yy(1,:) = (/ bp /)

wks  = gsn_open_wks ("x11","name")
res  = True
res@xyLineThicknesses        = (/2.0,2.0/)        
res@xyLineColors             = (/"blue","red"/)  
res@xyMonoDashPattern        = True              ; all solid 
res@tiYAxisString            = "PDF (%)"

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of 
res@pmLegendParallelPosF   = .25                 ; move units right
res@pmLegendOrthogonalPosF = -0.4                ; move units down
res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height
res@xyExplicitLegendLabels = (/"slab","fixed"/)  ; create explicit labels

res@tiMainString           = "PDF: Two Distributions: 20 Bins"
plot = gsn_csm_xy (wks, xx, yy, res)

end
