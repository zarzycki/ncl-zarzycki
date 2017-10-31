;========================================================
; Reads in a trajectory data file and calculates hurricane days
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

output_type="pdf"
do_plot=True
config="slab"

factor = surfaceWindCorrFactor(-1,-1,"log")

traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
;traj_filename = "cat_traj_slab2_08_4.7_900.txt"
traj_filename = "cat_traj_fixedSST_900.txt"
ncols = 12  
maxLines = -1
traj_data = getTrajectories(traj_dir+"/"+traj_filename,ncols,maxLines)

lon = traj_data(:,3,:)
lat = traj_data(:,4,:)
wind = traj_data(:,5,:);*factor
pres = traj_data(:,7,:)/100.
month = toint(traj_data(:,9,:))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

windunits="ms"
ms_to_kts=1.94384449

if (windunits .eq. "kts") then
  cut_ts   = 34
  cut_cat1 = 64
  cut_cat2 = 83
  cut_cat3 = 96
  cut_cat4 = 114
  cut_cat5 = 135
else if (windunits .eq. "ms") then
  cut_ts   = 17
  cut_cat1 = 33
  cut_cat2 = 43
  cut_cat3 = 49
  cut_cat4 = 58
  cut_cat5 = 70
else
  print("invalid windunits")
end if
end if


if (windunits .eq. "kts") then
  maxwind = dim_max_n_Wrap(wind,1)/ms_to_kts
else if (windunits .eq. "ms") then
  maxwind = dim_max_n_Wrap(wind,1)
else
  print("invalid windunits")
  exit()
end if
end if


print("Doing histogram statistics")

; First we'll do intensity
histogramInd = ispan(0,6,1)
histogram = new((/dimsizes(histogramInd)/),integer)
histogram = 0

; Create month array
monthArray = ispan(1,12,1)
monthHisto = new((/dimsizes(monthArray)/),integer)
monthHisto = 0
monthHisto!0 = "time"
monthHisto&time = monthArray

print("Doing AMIP intensity binning")
do i = 0,nstorms-1
  if (.not.ismissing(maxwind(i)))
    if (maxwind(i) .lt. cut_ts)
      histogram(0) = histogram(0) + 1
    else if (maxwind(i) .ge. cut_ts   .and. maxwind(i) .lt. cut_cat1)
      histogram(1) = histogram(1) + 1
    else if (maxwind(i) .ge. cut_cat1 .and. maxwind(i) .lt. cut_cat2)
      histogram(2) = histogram(2) + 1
    else if (maxwind(i) .ge. cut_cat2 .and. maxwind(i) .lt. cut_cat3)
      histogram(3) = histogram(3) + 1
    else if (maxwind(i) .ge. cut_cat3 .and. maxwind(i) .lt. cut_cat4)
      histogram(4) = histogram(4) + 1
    else if (maxwind(i) .ge. cut_cat4 .and. maxwind(i) .lt. cut_cat5)
      histogram(5) = histogram(5) + 1
    else
      histogram(6) = histogram(6) + 1
    end if
    end if
    end if
    end if
    end if
    end if
  end if
end do
  
do i = 0,nstorms-1
  if (.not.ismissing(maxwind(i)))
    monthHisto({toint(month(i,0))}) = monthHisto({toint(month(i,0))}) + 1
  end if
end do

cumHistoNorm = tofloat(histogram+.1)/20.0

if (do_plot) then
  ;============================================================================
  ; Do histograms
  ;============================================================================
  labels = (/"TD","TS","Cat 1","Cat 2","Cat 3","Cat 4","Cat 5"/)
  
  i = 0
  
  wks = gsn_open_wks(output_type,"pdf/intensityHisto_"+config)
  
  ;---Set resources common to both plots
  res                       = True                 ; plot mods desired         
  res@gsnFrame              = False
  res@gsnDraw               = False
  
  res@trYMinF               = 0.0
  yAxisMax = 25.0
  res@trYMaxF = yAxisMax


                                     
  res@tmXBOn              = False
  res@tmXTOn              = False
  ;res@tmYLOn              = False
  res@tmYROn              = False
  res@tmYRLabelsOn        = False
                                      
  barres                       = res                 ; plot mods desired         
  barres@gsnFrame              = False                ; don't advance frame yet
  barres@gsnXYBarChart         = True                 ; turn on bar chart
  ;   res@gsnXYBarChartBarWidth = 0.75                 ; change bar widths
  ;   barres@gsnXYBarChartColors = barcolors          ; choose colors
  barres@gsnXYBarChartColors = (/"blue","green","yellow","orange", \
  "darkorange3","red","red4"/)    
  
  barres@tmXBOn                = False                ; turn off tickmarks at bot
  
  barres@tiMainString          = config+" (20 yrs)"
  barres@tiYAxisString          = "Number of TCs per season"
  

  bar_plot = gsn_csm_xy (wks,histogramInd,cumHistoNorm,barres)

  
  ; add labelbar
  ;---Get viewport values for bar plot
   getvalues bar_plot
     "vpXF"      : vpx
     "vpYF"      : vpy
     "vpWidthF"  : vpw
     "vpHeightF" : vph
   end getvalues
  
  lbw    = 0.4 * vpw           ; Make labelbar size a fraction of the plot.
  lbh    = 0.5 * vph
  nboxes = dimsizes(barres@gsnXYBarChartColors)
   
  lbres                    = True          ; labelbar only resources
  lbres@vpWidthF           = 0.4 * vpw     ; labelbar width
  lbres@vpHeightF          = 0.5 * vph     ; labelbar height
  lbres@lbBoxMajorExtentF  = 0.75          ; puts space between color boxes
  lbres@lbFillColors       = barres@gsnXYBarChartColors ; labelbar colors
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
  lbres@lbLabelFontHeightF = 0.02          ; font height. default is small
  lbres@lbLabelJust        = "CenterLeft"  ; left justify labels
   
  gsn_labelbar_ndc(wks,nboxes,labels,vpx+vph-lbw+0.14,0.85,lbres)
   
  ;frame(wks)
  
  resP = True
  resP@amJust           = "TopLeft"

  ;resP@gsnPanelFigureStrings= (/"X."/)
  ;resP@gsnPanelFigureStringsFontHeightF = 0.035
  
  gsn_panel(wks,bar_plot,(/1,1/),resP)             ; now draw as one plot
  delete(lbres)
  delete(res)
  delete(wks)
  delete(nboxes)
  delete(barres)
  delete(bar_plot)
  delete(resP)
  
end if

print(histogram)
      
delete([/histogramInd,histogram/])
delete([/monthArray,monthHisto/])

end

