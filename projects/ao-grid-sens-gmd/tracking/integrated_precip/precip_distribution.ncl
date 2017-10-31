load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"

begin 

yyyy=1986  ;max for gx1v6 is 1994 it appears
minlat=15.0
maxlat=35.0
conv=86400000.
numberBins=30
                  
ne120_ne120_files = systemfunc ("ls /glade/p/cgd/ccr/f.e13.FAMIPC5.ne120_ne120.1979_2012.002/atm/proc/tseries/hourly3_regrid/f.e13.FAMIPC5.ne120_ne120.1979_2012.002.cam.h4.PRECT."+yyyy+"010100Z-"+yyyy+"123121Z.nc")
ne120_ne120_all   = addfiles (ne120_ne120_files, "r")
ListSetType (ne120_ne120_all, "cat")
ne120_PRECT = ne120_ne120_all[:]->PRECT(:,{minlat:maxlat},:)
ne120_PRECT = ne120_PRECT*conv
printVarSummary(ne120_PRECT)
ne120 = pdfx(ne120_PRECT, numberBins, False)
delete(ne120_PRECT)

ne120_gx1v6_files = systemfunc ("ls /glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/regrid/FAMIPC5_ne120_79to05_03_omp2.cam.h4."+yyyy+"*_PRECT.nc")
ne120_gx1v6_all   = addfiles (ne120_gx1v6_files, "r")
ListSetType (ne120_gx1v6_all, "cat")
gx1v6_PRECT = ne120_gx1v6_all[:]->PRECT(:,{minlat:maxlat},:)
gx1v6_PRECT = gx1v6_PRECT*conv
printVarSummary(gx1v6_PRECT)
gx1v6 = pdfx(gx1v6_PRECT, numberBins, False)
delete(gx1v6_PRECT)

nVar    = 2
nBin    = gx1v6@nbins          ; retrieve the number of bins

xx      = new ( (/nVar, nBin/), typeof(gx1v6))

xx(0,:) = gx1v6@bin_center
xx(1,:) = ne120@bin_center

yy      = new ( (/nVar, nBin/), typeof(gx1v6))
yy(0,:) = (/ gx1v6 /)
yy(1,:) = (/ ne120 /)

wks  = gsn_open_wks ("pdf","freq_histo")
res  = True
res@xyLineThicknesses        = (/2.0,2.0,2.0,2.0/)
res@xyLineColors             = (/"blue","red"/)
res@xyMonoDashPattern        = True              ; all solid
res@tiYAxisString            = "PDF (%)"

res@gsnXYBarChart            = True              ; Create bar plot
res@gsnXYBarChartOutlineOnly = True

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of
res@pmLegendParallelPosF   = .25                 ; move units right
res@pmLegendOrthogonalPosF = -0.4                ; move units down
res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height
res@xyExplicitLegendLabels = (/"gx1v6","ne120"/)  ; create explicit labels

xx = where(xx.le.0, 1.e-10, xx)
yy = where(yy.le.0, 1.e-10, yy)
res@trXMinF           = 30.
res@trXMaxF           = 3000.
res@trYMinF           = 10.^-8
res@trYMaxF           = 100.
res@xyXStyle          = "Log"
res@xyYStyle          = "Log"

res@tiMainString           = "Precip loading, aquaplanet"
plot = gsn_csm_xy (wks, xx, yy, res)
end

