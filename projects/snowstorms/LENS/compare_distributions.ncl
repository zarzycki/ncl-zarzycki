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

do_non_snow=True

trajfile=(/"/home/zarzycki/snow/snow-tracking/LES_tracking/traj/tempest.LENS.1990.CAT","/home/zarzycki/snow/snow-tracking/LES_tracking/traj/tempest.LENS.2071.CAT"/)
RSIfile = (/"/home/zarzycki/snow/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv.SNOW.tempest.csv","/home/zarzycki/snow/LES-snow/stats/RSI.SNOW.LENS.2071.ALL.5e-9_12.csv.SNOW.tempest.csv"/)
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

print("Mean min pressure RSI>=1 0: "+avg(minPresArray(0,0,:)))
print("Mean min pressure RSI>=1 1: "+avg(minPresArray(0,1,:)))

print("Mean min pressure RSI<=1 0: "+avg(minPresArray(1,0,:)))
print("Mean min pressure RSI<=1 1: "+avg(minPresArray(1,1,:)))

binSettings=True
binSettings@bin_min=930.0
binSettings@bin_max=1020.0
nbins=9

ap  = pdfx(minPresArray(0,0,:), nbins, binSettings)
bp  = pdfx(minPresArray(0,1,:), nbins, binSettings)
if (do_non_snow) then
  cp  = pdfx(minPresArray(1,0,:), nbins, binSettings)
  dp  = pdfx(minPresArray(1,1,:), nbins, binSettings)
end if


if (do_non_snow) then
  nVar = ncases*2
else
  nVar = ncases
end if

nBin    = ap@nbins          ; retrieve the number of bins
xx      = new ( (/nVar, nBin/), typeof(ap))
xx(0,:) = ap@bin_center
xx(1,:) = bp@bin_center
if (do_non_snow) then
  xx(2,:) = cp@bin_center
  xx(3,:) = dp@bin_center
end if

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap /)
yy(1,:) = (/ bp /)
if (do_non_snow) then
  yy(2,:) = (/ cp /)
  yy(3,:) = (/ dp /)
end if

wks  = gsn_open_wks (out_type,"MSLP_freq_comp")

plot = new(1,graphic)

res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/8.0,8.0,4.0,4.0/)
res@xyLineColors             = (/"red","blue","red","blue"/)
res@xyMonoDashPattern        = False              ; all solid
res@xyDashPatterns = (/0,0,1,1/)
res@tiYAxisString            = "Frequency (%)"
res@tiXAxisString            = "MSLP (hPa)"

res@trXMinF           = 935.
res@trXMaxF           = 1015.
plot(0) = gsn_csm_xy (wks, xx, yy, res)

lgres                    = True
lgres@lgLabelFontHeightF = .08
lgres@vpWidthF           = 0.22
lgres@vpHeightF          = 0.13
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgItemType         = "Lines"
lgres@lgLineColors     = res@xyLineColors(::-1)
lgres@lgDashIndexes = res@xyDashPatterns(::-1)
lgres@lgMonoLineThickness = False
lgres@lgLineThicknesses = res@xyLineThicknesses(::-1)
lbid = gsn_create_legend(wks,4,(/"2081-2090 (RSI<1)","1990-2005 (RSI<1)","2081-2090 (RSI>=1)","1990-2005 (RSI>=1)"/),lgres)


amres = True
amres@amParallelPosF   = -0.27             ; move legend to the right
amres@amOrthogonalPosF = -.36             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid(0),amres)   ; add legend to plot

resP = True
gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot

end
