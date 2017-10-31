;========================================================
; This script subse
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

refpath = "/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_climo_h0.all.nc"
unipath = "/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_climo_h0.all.nc_regrid.nc"
  
reffile = addfile(refpath,"r")
unifile = addfile(unipath,"r")

minlon = 260
maxlon = 355

;minlon = 180
;maxlon = 230

ref_prec = reffile->T850(0,:,{minlon:maxlon})
uni_prec = unifile->T850(0,:,{minlon:maxlon})

ref_prec_zonal = dim_avg_n_Wrap(ref_prec,1)
uni_prec_zonal = dim_avg_n_Wrap(uni_prec,1)

int_lat = fspan(-90,90,360)

ref_prec_zonal_int = linint1_Wrap(ref_prec_zonal&lat,ref_prec_zonal,True,int_lat,0)
uni_prec_zonal_int = linint1_Wrap(uni_prec_zonal&lat,uni_prec_zonal,True,int_lat,0)

data = new((/2,dimsizes(ref_prec_zonal_int)/),float)
data(0,:) = ref_prec_zonal_int
data(1,:) = uni_prec_zonal_int

wks  = gsn_open_wks("x11","zonal")                ; Opens a ps file 

res            = True                            ; plot mods desired

res@xyLineThicknesses = (/4.0,4.0/)               ; make 2nd lines thicker
res@xyLineColors      = (/"blue","red"/)          ; change line color

  res@pmLegendDisplayMode    = "Always"            ; turn on legend

  res@pmLegendSide           = "Top"               ; Change location of 
  res@pmLegendParallelPosF   = .45                 ; move units right
  res@pmLegendOrthogonalPosF = 0.0                ; move units down

  res@pmLegendWidthF         = 0.10                ; Change width and
  res@pmLegendHeightF        = 0.10                ; height of legend.
  res@lgLabelFontHeightF     = .02                 ; change font height
  res@xyExplicitLegendLabels = (/"ref","uni"/)         ; explicit labels

plot=gsn_csm_xy(wks,int_lat,data,res)       ; plot zonal ave

end
