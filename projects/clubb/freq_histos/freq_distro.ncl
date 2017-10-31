;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

;---------------User settings----------------------------

out_type = "pdf"
whatVar="PRECT"

wind_factor = "log"
traj_a_dir = "/glade/scratch/zarzycki/clubb-tracking/CAM5/"
traj_a_filename = "trajectories.txt.CAM5"
traj_a_name="CAM5"
traj_b_dir = "/glade/scratch/zarzycki/clubb-tracking/CLUBB/"
traj_b_filename = "trajectories.txt.CLUBB"
traj_b_name="CLUBB"



ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"


colorArray = (/"blue","red","springgreen4"/)

markerTypes = (/2,5,1/)

threshWind = 20.0 ; threshold wind in m/s

;----------------Constants-----------------------------------

nEntries=50000
ms_to_kts = 1.94384449
ms_to_mmday = 8.64e7

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;--------------------------------------------------------

print("Read in TC locations from CAM")

ncols = 13                     ; assign number of columns
maxLines = -1

traj_a_data = getTrajectories(traj_a_dir+"/"+traj_a_filename,ncols,maxLines)
traj_a_lon = traj_a_data(:,1,:)
traj_a_lat = traj_a_data(:,2,:)
traj_a_pres = traj_a_data(:,3,:)/100.
traj_a_wind = traj_a_data(:,5,:)*factor
traj_a_prect = traj_a_data(:,7,:)*ms_to_mmday
traj_a_tmq  = traj_a_data(:,8,:)

maxLines = -1
traj_b_data = getTrajectories(traj_b_dir+"/"+traj_b_filename,ncols,maxLines)
traj_b_lon = traj_b_data(:,1,:)
traj_b_lat = traj_b_data(:,2,:)
traj_b_pres = traj_b_data(:,3,:)/100.
traj_b_wind = traj_b_data(:,5,:)*factor
traj_b_prect = traj_b_data(:,7,:)*ms_to_mmday
traj_b_tmq  = traj_b_data(:,8,:)

numberBins=30

if (whatVar .eq. "PRECT") then
  aph = pdfx(traj_a_prect, numberBins, False)
  bph = pdfx(traj_b_prect, numberBins, False)
else if (whatVar .eq. "TMQ") then
  aph = pdfx(traj_a_tmq, numberBins, False)
  bph = pdfx(traj_b_tmq, numberBins, False)
else
  print("invalid var")
  exit
end if
end if

;------------------------------------------------
;
;------------------------------------------------
  nVar    = 2
  nBin    = aph@nbins          ; retrieve the number of bins

  xx      = new ( (/nVar, nBin/), typeof(aph))

  xx(0,:) = aph@bin_center
  xx(1,:) = bph@bin_center

  yy      = new ( (/nVar, nBin/), typeof(aph))
  yy(0,:) = (/ aph /)
  yy(1,:) = (/ bph /)

  wks  = gsn_open_wks (out_type,"freq_histo_"+whatVar)
  res  = True
  res@xyLineThicknesses        = (/4.0,4.0/)
  res@xyLineColors             = (/"blue","red"/)
  res@xyMonoDashPattern        = True              ; all solid
  res@tiYAxisString            = "PDF (%)"

  res@gsnXYBarChart            = True              ; Create bar plot
  res@gsnXYBarChartOutlineOnly = True

  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of
  res@pmLegendParallelPosF   = .25                 ; move units right
  res@pmLegendOrthogonalPosF = -0.8                ; move units down
  res@pmLegendWidthF         = 0.125               ; Change width and
  res@pmLegendHeightF        = 0.15                ; height of legend.
  res@lgPerimOn              = True                ; turn off/on box around
  res@lgLabelFontHeightF     = .015                ; label font height
  res@xyExplicitLegendLabels = (/"CAM5","CAM5.5"/)  ; create explicit labels

if (whatVar .eq. "PRECT") then
  xx = where(xx.le.0, 1.e-10, xx)
  yy = where(yy.le.0, 1.e-10, yy)
  res@trXMinF           = 20.
  res@trXMaxF           = 4000.
  res@trYMinF           = 10.^-2
  res@trYMaxF           = 20.
  res@xyXStyle          = "Log"
  res@xyYStyle          = "Log"
  res@pmLegendOrthogonalPosF = -0.8                ; move units down
  res@pmLegendWidthF         = 0.125               ; Change width and
end if

if (whatVar .eq. "TMQ") then
  res@trXMinF           = 15.
  res@trXMaxF           = 110.
  res@trYMinF           = 10.^-2
  res@trYMaxF           = 50.
  res@xyXStyle          = "Linear"
  res@xyYStyle          = "Log"
  res@pmLegendParallelPosF   = .6                 ; move units right
  res@pmLegendOrthogonalPosF = -1.0                ; move units down
end if

  res@tiMainString           = "Max. "+whatVar+" freq."
  plot = gsn_csm_xy (wks, xx, yy, res)
end
