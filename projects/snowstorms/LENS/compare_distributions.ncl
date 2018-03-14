;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
;========================================================
begin

out_type="pdf"

do_non_snow=False

PRECTSNOW="PRECT"
trajfile=(/"/home/zarzycki/snow/snow-tracking/LES_tracking/traj/tempest.LENS.1990.CAT","/home/zarzycki/snow/snow-tracking/LES_tracking/traj/tempest.LENS.2026.CAT","/home/zarzycki/snow/snow-tracking/LES_tracking/traj/tempest.LENS.2071.CAT"/)
RSIfile = (/"/loan/hires/zarzycki/tarfolder/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/loan/hires/zarzycki/tarfolder/stats/RSI.SNOW.LENS.2026.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/loan/hires/zarzycki/tarfolder/stats/RSI.SNOW.LENS.2071.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv"/)
modelcolors=(/"blue2","green2","red2"/)
labelsArr=(/"  1990-2005","  2026-2035","  2071-2080"/)
ncols = 9                     ; assign number of columns

delim = ","

ncases = dimsizes(trajfile)
print("Doing "+ncases+"  number of cases")

maxStorms = 50000

if (do_non_snow) then
  minPresArray = new((/2,ncases,maxStorms/),"float")
else
  minPresArray = new((/1,ncases,maxStorms/),"float")
end if

do z = 0,ncases-1
  
  maxLines = -1
  traj_data = getTrajectories(trajfile(z),ncols,maxLines)

  lines = asciiread(RSIfile(z),-1,"string")

  ;member   = str_get_field(lines,1,delim)
  ;stormID  = tointeger(str_get_field(lines,2,delim))
  ;RSIval   = tofloat(str_get_field(lines,3,delim))
  RSIcat   = tointeger(str_get_field(lines,7,delim))

  ndims = dimsizes(traj_data)
  nstorms = ndims(0)
  ncols   = ndims(1)
  ntimes  = ndims(2)

  traj_data_NOSNOW=traj_data

  do i = 0,nstorms-1
    if (RSIcat(i) .lt. 1)
      traj_data(i,:,:) = traj_data@_FillValue
    else
      traj_data_NOSNOW(i,:,:) = traj_data@_FillValue
    end if
  end do

  ;lon = traj_data(:,2,:)
  ;lat = traj_data(:,3,:)
  ;pres = traj_data(:,4,:)/100.
  ;wind = traj_data(:,5,:)*.8
  ;yyyy = traj_data(:,6,:)
  ;mm = traj_data(:,7,:)
  ;dd = traj_data(:,8,:)
  ;hh = traj_data(:,9,:)


  minPresArray(0,z,0:nstorms-1) = dim_min_n_Wrap(traj_data(:,4,:)/100.,1)
  if (do_non_snow) then
    minPresArray(1,z,0:nstorms-1) = dim_min_n_Wrap(traj_data_NOSNOW(:,4,:)/100.,1)
  end if

  delete(traj_data)
  delete(traj_data_NOSNOW)
  delete(lines)
  delete(RSIcat)
  delete(nstorms)

  opt = True
  opt@PrintStat = True
  stats = stat_dispersion(minPresArray(0,z,:), opt)

end do

;print("Mean min pressure RSI>=1 0: "+avg(minPresArray(0,0,:)))
;print("Mean min pressure RSI>=1 1: "+avg(minPresArray(0,1,:)))
;print("Mean min pressure RSI<=1 0: "+avg(minPresArray(1,0,:)))
;print("Mean min pressure RSI<=1 1: "+avg(minPresArray(1,1,:)))

binSettings=True
binSettings@bin_min=930.0
binSettings@bin_max=1020.0
nbins=9

if (do_non_snow) then
  nVar = ncases*2
else
  nVar = ncases
end if

xx=new ( (/nVar, nbins/), "double")
yy=new ( (/nVar, nbins/), "double")

do z = 0,ncases-1
  ap = pdfx(minPresArray(0,z,:), nbins, binSettings)
  yy(z,:) = ap
  xx(z,:) = ap@bin_center
  delete(ap)
  if (do_non_snow) then
    bp = pdfx(minPresArray(0,z,:), nbins, binSettings)
    yy((z+ncases),:) = bp
    xx((z+ncases),:) = bp@bin_center
    delete(bp)
  end if
end do

wks  = gsn_open_wks (out_type,"MSLP_freq_comp_"+PRECTSNOW)

plot = new(1,graphic)

res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/8.0,8.0,8.0,4.0,4.0,4.0/)
res@xyLineColors             = modelcolors
res@xyMonoDashPattern        = False              ; all solid
res@xyDashPatterns = (/0,0,0,1,1,1/)
res@tiYAxisString            = "Frequency (%)"
res@tiXAxisString            = "Minimum central pressure (hPa)"

res@trXMinF           = 935.
res@trXMaxF           = 1015.
plot(0) = gsn_csm_xy (wks, xx, yy, res)

lgres                    = True
lgres@lgLabelFontHeightF = .1
lgres@vpWidthF           = 0.15
lgres@vpHeightF          = 0.08
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgItemType         = "Lines"
lgres@lgLineColors     = res@xyLineColors
lgres@lgDashIndexes = res@xyDashPatterns
lgres@lgMonoLineThickness = False
lgres@lgLineThicknesses = res@xyLineThicknesses
lbid = gsn_create_legend(wks,3,labelsArr,lgres)


amres = True
amres@amParallelPosF   = -0.48    ; This is the left edge of the plot.
amres@amOrthogonalPosF = -0.48    ; This is the top edge of the plot.
amres@amJust           = "TopLeft"
annoid1 = gsn_add_annotation(plot,lbid(0),amres)   ; add legend to plot

resP = True
gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot

end
