;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/bootstrap.ncl"
;========================================================
begin
; metric=TK_ERR
; whatPlot=cam_sst
; ncl errorStats.ncl 'metric="'${metric}'"' 'whatPlot="'${whatPlot}'"'

;whatPlot = "cam_sst" ; all_ts, all_hurr, cam_resolution, cam_sst, cam_sens, camm_clubb
;metric="WIND_BIAS" ; TK_ERR, WIND_ERR, WIND_BIAS

leadString="statline"
outType = "pdf"

path_to_met_files = "/glade/u/home/zarzycki/work/met_files/"

; Bootstrap settings
do_bootstrap=False
do_ttest=True
nReps = 10000
alpha = .80

;========================================================================================

; Checks
plot_normalized=False
if (metric .eq. "TK_ERR" .or. metric .eq. "WIND_ERR") then
  plot_normalized=True
end if

if (do_bootstrap .and. plot_normalized .eq. False)
  print("Cannot do bootstrap beyond 120 hours")
  print("Normalization must be on")
  exit
end if

splitPlot=str_split_by_length(whatPlot,(/3,10/))
whatTypePlot=splitPlot(0)

;************************************************************

if (whatPlot .eq. "all_ts") then
  filename = path_to_met_files+"/all_ts"
  models = (/"----","CAM","GFDL","GFSO","HWRF","CMC"/)
  whichbasin = ""
  ; CMC doesn't have intensity in a-deck
  if (metric .ne. "TK_ERR" .and. metric .ne. "TK_ALL") then
    models_new = models(0:dimsizes(models)-2)
    delete(models)
    models = models_new
    delete(models_new)
  end if
end if

if (plot_normalized .eq. True .or. whatTypePlot .eq. "all") then
  filename = path_to_met_files+"/"+"filter_"+whatPlot+".tcst"
else
  filename = path_to_met_files+"/"+"filter_"+whatPlot+"_nostat.tcst"
end if

if (whatPlot .eq. "all_hurr") then
  models = (/"----","CAM","GFDL","GFSO","HWRF","CMC"/)
  whichbasin = ""
  if (metric .ne. "TK_ERR" .and. metric .ne. "TK_ALL") then
    models_new = models(0:dimsizes(models)-2)
    delete(models)
    models = models_new
    delete(models_new)
  end if
end if

if (whatPlot .eq. "cam_sens") then
  models = (/"----","CAM","CAMW","CAMX","CAMY","CAMZ"/)
  whichbasin = ""
end if

if (whatPlot .eq. "cam_resolution") then
  models = (/"----","CAM","CAM6"/)
  whichbasin = ""
end if

if (whatPlot .eq. "cam_sst") then
  models = (/"----","CAM","CAMC"/)
  whichbasin = ""
end if

if (whatPlot .eq. "cam_clubb") then
  models = (/"----","CAM","CAMZ"/)
  whichbasin = ""
end if

if (whatPlot .eq. "cam_highres") then
  models = (/"----","CAM","CAMH"/)
  whichbasin = ""
end if

outputString = leadString+"_"+whatPlot+"_"+metric
statsTableString = outputString

; replace empty string with corresponding statistical model
if (metric .eq. "TK_ERR" .or. metric .eq. "TK_ALL") then
  models(0) = "CLP5" 
  basemodel = (/"CLP5"/)
end if
if (metric .eq. "WIND_ERR" .or. metric .eq. "WIND_BIAS" .or. metric .eq. "MSLP_ERR" .or. metric .eq. "WIND_ALL") then
  models(0) = "SHF5" 
  basemodel = (/"SHF5"/)
end if

; get rid of SHF5 and CLP5 if we are not normalizing
if (.not. plot_normalized) then
  models_new = models(1:dimsizes(models)-1)
  delete(models)
  models = models_new
  delete(models_new)
end if

;************************************************************

nmodels=dimsizes(models)
ncolors=dimsizes(models)

if (metric .eq. "WIND_BIAS" .and. plot_normalized)
  print("Cannot use SHF5 to normalize by bias, exiting....")
  exit()
end if

lines = asciiread(filename,-1,"string")

if(plot_normalized) then
  leadTimes = (/12,24,36,48,72,96,120/)
else
  leadTimes = (/12,24,36,48,72,96,120,144,168,192/)
end if


means = new((/dimsizes(models),dimsizes(leadTimes),30/),"float")
baseline = new((/1,dimsizes(leadTimes),30/),"float")

baseline_prob = new(dimsizes(models),"float")
means_prob = new((/dimsizes(leadTimes),dimsizes(models),dimsizes(models)/),"float")

bootDiff = new((/dimsizes(leadTimes),dimsizes(models),dimsizes(models)/),"integer")

;print(lines)

delim = " "

;VERSION AMODEL BMODEL STORM_ID BASIN CYCLONE STORM_NAME INIT            LEAD    VALID           INIT_MASK VALID_MASK LINE_TYPE TOTAL INDEX LEVEL WATCH_WARN INITIALS ALAT     ALON       BLAT     BLON      TK_ERR     X_ERR       Y_ERR       ALTK_ERR    CRTK_ERR    ADLAND      BDLAND     AMSLP BMSLP AMAX_WIND BMAX_WIND AAL_WIND_34 BAL_WIND_34 ANE_WIND_34 BNE_WIND_34 ASE_WIND_34 BSE_WIND_34 ASW_WIND_34 BSW_WIND_34 ANW_WIND_34 BNW_WIND_34 AAL_WIND_50 BAL_WIND_50 ANE_WIND_50 BNE_WIND_50 ASE_WIND_50 BSE_WIND_50 ASW_WIND_50 BSW_WIND_50 ANW_WIND_50 BNW_WIND_50 AAL_WIND_64 BAL_WIND_64 ANE_WIND_64 BNE_WIND_64 ASE_WIND_64 BSE_WIND_64 ASW_WIND_64 BSW_WIND_64 ANW_WIND_64 BNW_WIND_64
;V4.1    CARQ   BEST   AL012012 AL    01      ALBERTO    20120519_120000 -120000 20120519_000000 NA        NA         TCMPR     3     1     LO    NA         X        33.10000 -76.80000  33.10000 -77.00000 10.05247   10.05247    0.00000     -2.70744    -9.67913    80.55836    73.46449   NA    1010  25        25        0.00000     NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA

;VERSION = str_get_field(lines,1,delim)
AMODEL = str_get_field(lines,2,delim)
BMODEL = str_get_field(lines,3,delim)
;STORM_ID = str_get_field(lines,4,delim)
BASIN = str_get_field(lines,5,delim)
;CYCLONE = str_get_field(lines,6,delim)
;STORM_NAME = str_get_field(lines,7,delim)
INIT = str_get_field(lines,8,delim)
LEAD = toint(str_get_field(lines,9,delim))/10000
VALID = str_get_field(lines,10,delim)
;INIT_MASK  = str_get_field(lines,11,delim)
;VALID_MASK = str_get_field(lines,12,delim)
;LINE_TYPE = str_get_field(lines,13,delim)
;TOTAL = toint(str_get_field(lines,14,delim))
;INDEX = toint(str_get_field(lines,15,delim))
LEVEL = str_get_field(lines,16,delim)
;WATCH_WARN = str_get_field(lines,17,delim)
;INITIALS = str_get_field(lines,18,delim)
;ALAT = tofloat(str_get_field(lines,19,delim))
;ALON = tofloat(str_get_field(lines,20,delim))
;BLAT = tofloat(str_get_field(lines,21,delim))
;BLON = tofloat(str_get_field(lines,22,delim))
TK_ERR = tofloat(str_get_field(lines,23,delim))
;X_ERR = tofloat(str_get_field(lines,24,delim))
;Y_ERR = tofloat(str_get_field(lines,25,delim))
ALTK_ERR = tofloat(str_get_field(lines,26,delim))
CRTK_ERR = tofloat(str_get_field(lines,27,delim))
;ADLAND = tofloat(str_get_field(lines,28,delim))
;BDLAND = tofloat(str_get_field(lines,29,delim))
AMSLP = tofloat(str_get_field(lines,30,delim))
BMSLP = tofloat(str_get_field(lines,31,delim))
AMAX_WIND = tofloat(str_get_field(lines,32,delim))
BMAX_WIND = tofloat(str_get_field(lines,33,delim))
;AAL_WIND_34 = tofloat(str_get_field(lines,34,delim))
;BAL_WIND_34 = tofloat(str_get_field(lines,35,delim))

ms_to_kts = 1.94384449
nm_to_km = 1.852
; Post calculated
TK_ERR = TK_ERR*nm_to_km
WIND_ERR = (abs(AMAX_WIND-BMAX_WIND))/ms_to_kts
WIND_BIAS = (AMAX_WIND-BMAX_WIND)/ms_to_kts
MSLP_ERR = abs(AMSLP-BMSLP)
MSLP_BIAS = AMSLP-BMSLP

nrecords = dimsizes(AMODEL)

fullRecords = new((/dimsizes(models),dimsizes(leadTimes),nrecords/),"float")

if (metric .eq. "TK_ERR") then
  VAR = TK_ERR
else if (metric .eq. "WIND_ERR")
  VAR = WIND_ERR
else if (metric .eq. "WIND_BIAS")
  VAR = WIND_BIAS
else if (metric .eq. "MSLP_BIAS")
  VAR = MSLP_BIAS
else if (metric .eq. "MSLP_ERR")
  VAR = MSLP_ERR
else if (metric .eq. "TK_ALL")
  VAR = TK_ERR
else if (metric .eq. "WIND_ALL")
  VAR = WIND_ERR
end if
end if
end if
end if
end if
end if
end if

do j = 0,dimsizes(leadTimes)-1
thisTime = leadTimes(j)
print("Doing: baseline at this leadtime: "+thisTime)
stats = where(AMODEL .eq. basemodel,VAR,VAR@_FillValue)
stats = where(LEAD .eq. thisTime,stats,stats@_FillValue)
if (whichbasin .eq. "AL" .or. whichbasin .eq. "EP") then
  stats = where(BASIN .eq. whichbasin,stats,stats@_FillValue)
end if

fullRecords(0,j,:) = stats

opt = True
opt@PrintStat = False
statb = stat_dispersion(stats, opt )

baseline(0,j,:) = statb(:)
;baseline(0,j,1) = variance(stats)

delete(statb)
delete(stats)
delete(thisTime)
end do


do i = 0,dimsizes(models)-1
do j = 0,dimsizes(leadTimes)-1
thisModel = models(i)
thisTime = leadTimes(j)
print("Doing: "+thisModel+" at this leadtime: "+thisTime)
stats = where(AMODEL .eq. thisModel,VAR,VAR@_FillValue)
stats = where(LEAD .eq. thisTime,stats,stats@_FillValue)
if (whichbasin .eq. "AL" .or. whichbasin .eq. "EP") then
  stats = where(BASIN .eq. whichbasin,stats,stats@_FillValue)
end if

fullRecords(i,j,:) = stats

opt = True
opt@PrintStat = False
statb = stat_dispersion(stats, opt )


means(i,j,:) = statb(:)
;print(" "+means(i,j,1))
;means(i,j,1) = variance(stats)
;print(" "+means(i,j,1))

delete(statb)
delete(stats)
delete(thisModel)
delete(thisTime)

end do
end do

baseline_relative = means(:,:,0)
baseline_relative = means@_FillValue
do i = 0,dimsizes(models)-1
  baseline_relative(i,:) = 100*(baseline(0,:,0)-means(i,:,0))/baseline(0,:,0)
end do

if (do_ttest) then

do i = 0,dimsizes(models)-1
j = 5 ; 5 =120 hr
siglvl = 0.05
aveX = means(i,j,0)
aveY = baseline(0,j,0)
varX = means(i,j,1)
varY = baseline(0,j,1)
sX   = means(i,j,19)
sY   = baseline(0,j,19)
;print("avg "+aveX+" "+aveY)
;print("var "+varX+" "+varY)
;print("s "+sX+" "+sY)
iflag= False
prob = ttest(aveX,varX,sX, aveY,varY,sY, iflag, False)
baseline_prob(i) = prob
end do

do j = 0,dimsizes(leadTimes)-1
do i = 0,dimsizes(models)-1
do k = 0,dimsizes(models)-1
siglvl = 0.05
aveX = means(i,j,0)
aveY = means(k,j,0)
varX = means(i,j,1)
varY = means(k,j,1)
sX   = means(i,j,19)
sY   = means(k,j,19)
;print("avg "+aveX+" "+aveY)
;print("var "+varX+" "+varY)
;print("s "+sX+" "+sY)
iflag= False
prob = ttest(aveX,varX,sX, aveY,varY,sY, iflag, False)
means_prob(j,i,k) = prob
end do
end do

;print(models)
opt  = True
;"means_prob_"+sprinti("%0.3i", leadTimes(j))+".txt"
opt@fout = "stats/stats_ttest_"+sprinti("%0.3i", leadTimes(j))+"_"+outputString
write_matrix((1.-means_prob(j,:,:)),"7f7.2",opt) 
end do


end if

if (do_bootstrap) then
  do j = 0,dimsizes(leadTimes)-1
  do i = 0,dimsizes(models)-1
  do k = 0,dimsizes(models)-1
  print("---------")
  print("testing "+models(i)+" and "+models(k))
 ; 5 =120 hr
  pctiles = bootstrap_testmeans(fullRecords(i,j,:),fullRecords(k,j,:),nReps,alpha)
  ;print(pctiles)
  if(pctiles(0) .lt. 0 .and. pctiles(1) .gt. 0) then
    bootDiff(j,i,k) = 0
  else
    bootDiff(j,i,k) = 1
  end if
  end do
  end do
  opt  = True
  opt@fout = "boot_prob.txt"
  print("================== "+leadTimes(j)+" hrs ==========================")
  write_matrix(bootDiff(j,:,:),"7I5",False) 
  end do
end if

; Getting output
statsOutFile = "stats/stats_means_"+outputString
tmpFileName = "append.tmp"
asciiwrite(tmpFileName,models) 
system("cat "+tmpFileName+" lineFile.txt > "+statsOutFile)
asciiwrite(tmpFileName,leadTimes)
system("cp "+statsOutFile+" "+statsOutFile+".tmp")
system("cat "+statsOutFile+".tmp "+tmpFileName+" lineFile.txt > "+statsOutFile)
do k = 0,nmodels-1
  asciiwrite(tmpFileName,means(k,:,0)) 
  system("cp "+statsOutFile+" "+statsOutFile+".tmp")
  system("cat "+statsOutFile+".tmp "+tmpFileName+" lineFile.txt > "+statsOutFile)
end do
system("rm "+tmpFileName+" "+statsOutFile+".tmp")


;======= do line colors
print("figuring out line colors and dashing")
print("===========================")
linecolors = models
do k = 0,nmodels-1
  thisModel=models(k)
  linecolors(k) = "gold2"
  if (thisModel .eq. "----") then
    linecolors(k) = "blue"
  end if
  if (thisModel .eq. "CAM") then
    linecolors(k) = "black"
  end if
  if (thisModel .eq. "CAM6") then
    linecolors(k) = "green"
  end if
  if (thisModel .eq. "CAMC") then
    linecolors(k) = "darkseagreen3"
  end if
  if (thisModel .eq. "CAMX") then
    linecolors(k) = "peachpuff3"
  end if
  if (thisModel .eq. "CAMY") then
    linecolors(k) = "olivedrab3"
  end if
  if (thisModel .eq. "CAMZ") then
    linecolors(k) = "tomato"
  end if
  if (thisModel .eq. "CAMW") then
    linecolors(k) = "purple"
  end if
  if (thisModel .eq. "CMC") then
    linecolors(k) = "purple"
  end if
  if (thisModel .eq. "GFDL") then
    linecolors(k) = "orange"
  end if
  if (thisModel .eq. "GFSO") then
    linecolors(k) = "red"
  end if
  if (thisModel .eq. "HWRF") then
    linecolors(k) = "brown"
  end if
  if (thisModel .eq. "CAMH") then
    linecolors(k) = "green"
  end if
  
  print(thisModel+" -> "+linecolors(k))
end do
print("===========================")





 wks   = gsn_open_wks (outType,"statline/"+outputString)                  ; open workstation

 res                   = True                      ; plot mods desired
 res@gsnDraw = False
 res@gsnFrame = False

 res@vpWidthF = 0.77
 res@vpHeightF = 0.62

  res@tmYLFormat="& 5;*f" 
  res@tmYLLabelConstantSpacingF=0.95

  res@tmXBLabelConstantSpacingF=0.95

 res@xyLineThicknessF = 5.0

  res@tmXBMode        = "Explicit"	
  res@tmXBValues      = leadTimes
  res@tmXBLabels      = "" + res@tmXBValues 

; =================
  mainStringTitle=""
  if (metric .eq. "TK_ERR") then
    mainStringTitle = "Track Skill"
    panelLabel = "a."
  else if (metric .eq. "WIND_ERR")
    mainStringTitle = "Wind Skill"
    panelLabel = "b."
  else if (metric .eq. "WIND_BIAS")
    mainStringTitle = "Wind Bias"
    panelLabel = "d."
  else if (metric .eq. "MSLP_BIAS")
    panelLabel = "d."
  else if (metric .eq. "MSLP_ERR")
    panelLabel = "e."
  else if (metric .eq. "TK_ALL")
    panelLabel = "c."
    mainStringTitle = "Track Error"
  else if (metric .eq. "WIND_ALL")
    panelLabel = "f."
  end if
  end if
  end if
  end if
  end if
  end if
  end if

  res@tiMainString = mainStringTitle
; ==================

; res@xyMarkLineMode = "MarkLines"    ; Markers *and* lines
; res@xyMarker = 16
; res@xyMarkerColors = res@xyLineColors  ; 3 different colors

if (plot_normalized) then
  legendLoc = "TopLeft"
  panelLabelLoc = "TopRight"
else
  legendLoc = "BottomRight"
  panelLabelLoc = "BottomRight"
end if




; -------------------------------------------------------------------------------------

legModels = models
do z = 0,dimsizes(legModels)-1
  if (legModels(z) .eq. "CAMC")
    legModels(z) = "CAM-CLIMO"
  end if
  if (legModels(z) .eq. "CAM6")
    legModels(z) = "CAM-UNI55"
  end if
  if (legModels(z) .eq. "CAMZ")
    legModels(z) = "CAM-CLUBB"
  end if
  if (legModels(z) .eq. "CAMY")
    legModels(z) = "CAM-NODEEP"
  end if
  if (legModels(z) .eq. "CAMW")
    legModels(z) = "CAM-NEWTAU"
  end if
  if (legModels(z) .eq. "CAMX")
    legModels(z) = "CAM-DT450"
  end if
  if (legModels(z) .eq. "CAMH")
    legModels(z) = "CAM-UNI14"
  end if
end do

;;; LEGEND
  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of 

  res@pmLegendWidthF         = 0.13                ; Change width and
  res@pmLegendHeightF        = 0.14                ; height of legend.
  res@lgPerimOn              = False               ; turn off box around
  res@lgLabelFontHeightF     = .019                 ; label font height

; the use of a verticalFactor is a total kludge when you add a title to the plot
; It should be set to zero if there is no main string
; Otherwise, guess and check sets it
if (legendLoc .eq. "TopLeft") then
  verticalFactor = 0.07
  res@pmLegendParallelPosF   = res@pmLegendWidthF + 0.05  ; 0.05 moves legend towards right
  res@pmLegendOrthogonalPosF = 0.0 - (2*res@pmLegendHeightF) - verticalFactor
else if (legendLoc .eq. "BottomRight") then
  ; Add moveLegendFactor hack so we can put panel label in bottom right corner
  ; otherwise, the factor = 1
  moveLegendFactor = 1.9
  verticalFactor = 0.09
  res@pmLegendParallelPosF   = 1.0 - res@pmLegendWidthF*moveLegendFactor - .05 ;-0.05 moves legend towards left
  res@pmLegendOrthogonalPosF = -1.-verticalFactor                      ; move units down

end if
end if

res@tiYAxisFontHeightF=0.023
res@tiXAxisFontHeightF=0.023
res@tiMainFontHeightF=0.024

res@tiXAxisString = "Forecast hour"

;res@tiYAxisOffsetXF = -0.05
;res@tmYLAutoPrecision=False

if (plot_normalized) then
  res@trXMinF=0
  res@trXMaxF=120
  ;res@trYMaxF=max(baseline_relative(1:nmodels-1,:))*1.2
  res@tiYAxisString="Skill relative to "+basemodel(0)+" (%)"

  res@xyExplicitLegendLabels = legModels(1:nmodels-1)
  res@xyLineColors = linecolors(1:ncolors-1)
  plot  = gsn_csm_xy (wks,leadTimes,baseline_relative(1:nmodels-1,:),res) ; create plot
else
  ;res@trYMinF=0
  overage=(max(means(:,:,0))-min(means(:,:,0)))*.3
  res@trYMaxF=max(means(:,:,0))+overage

  res@trXMinF=0
  res@trXMaxF=max(leadTimes)
  if (metric .eq. "TK_ERR" .or. metric .eq. "TK_ALL") then
    res@tiYAxisString="Track error (km)"
  else if (metric .eq. "WIND_ERR" .or. metric .eq. "WIND_ALL") then
    res@tiYAxisString="10-m wind error (m s~S~-1~N~)"
  else if (metric .eq. "WIND_BIAS") then
    res@tiYAxisString="10-m wind bias (m s~S~-1~N~)"
  else if (metric .eq. "MSLP_ERR") then
    res@tiYAxisString="MSLP error (hPa)"
  else
    res@tiYAxisString="Error"
  end if
  end if
  end if
  end if

  res@xyExplicitLegendLabels = legModels
  res@xyLineColors = linecolors
  plot  = gsn_csm_xy (wks,leadTimes,means(:,:,0),res) ; create plot
end if

;=============================================================================
;whatPlot = "cam_sst" ; all_ts, all_hurr, cam_resolution, cam_sst, cam_sens, camm_clubb
;metric="WIND_BIAS" ; TK_ERR, WIND_ERR, WIND_BIAS
if (whatPlot .eq. "all_ts" .and. metric .eq. "TK_ERR")
  res@trYMaxF=75.
  res@trYMinF=-40.
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.65   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "all_ts" .and. metric .eq. "TK_ALL")
  res@trYMaxF=1350.
  res@trYMinF=0.
end if
if (whatPlot .eq. "all_ts" .and. metric .eq. "WIND_ERR")
  res@trYMaxF=62.
  res@trYMinF=-100.
end if
if (whatPlot .eq. "all_hurr" .and. metric .eq. "TK_ERR")
  res@trYMaxF=85.
  res@trYMinF=-40.
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.65   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "all_hurr" .and. metric .eq. "WIND_ERR")
  res@trYMaxF=92.
  res@trYMinF=-155.
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.85   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "all_hurr" .and. metric .eq. "TK_ALL")
  res@trYMaxF=1100.
  res@trYMinF=0.
end if
if (whatPlot .eq. "all_hurr" .and. metric .eq. "WIND_BIAS")
  res@trYMaxF=14.
  res@trYMinF=-12.
end if
if (whatPlot .eq. "cam_resolution" .and. metric .eq. "WIND_ERR")
  res@trYMaxF=30.
  res@trYMinF=-160.
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.65   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "cam_sst" .and. metric .eq. "TK_ERR")
  res@trYMaxF=58.
  res@trYMinF=16.
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.65   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "cam_sst" .and. metric .eq. "WIND_ERR")
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.65   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "cam_sens" .and. metric .eq. "TK_ERR")
  res@trYMaxF=-5.
  res@trYMinF=70.
  res@pmLegendParallelPosF   = 0.6
  res@pmLegendOrthogonalPosF = -0.75   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "cam_sens" .and. metric .eq. "WIND_ERR")
  res@trYMaxF=-350.
  res@trYMinF=100.
  res@pmLegendParallelPosF   = 0.3
  res@pmLegendOrthogonalPosF = -0.75   ;(negative is up, positive is down)
end if
if (whatPlot .eq. "cam_sens" .and. metric .eq. "TK_ALL")
  res@trYMaxF=1425.
  res@trYMinF=0.
end if
if (whatPlot .eq. "cam_sens" .and. metric .eq. "WIND_BIAS")
  res@trYMaxF=45.
  res@trYMinF=-8.
  res@pmLegendParallelPosF   = 0.21
  res@pmLegendOrthogonalPosF = -0.77   ;(negative is up, positive is down)
end if
;=============================================================================

if (plot_normalized) then
  plot  = gsn_csm_xy (wks,leadTimes,baseline_relative(1:nmodels-1,:),res) ; create plot
else
  plot  = gsn_csm_xy (wks,leadTimes,means(:,:,0),res) ; create plot
end if

delete(legModels)

   getvalues plot
     "trYMinF"              : ymin
     "trYMaxF"              : ymax
   end getvalues

; -------------------------------------------------------------------------------------
; ZERO LINE

if ((plot_normalized .and. ymin .ne. 0) .or. metric .eq. "WIND_BIAS") then
  zlineres = True
  zlineres@gsLineColor = "black"
  zlineres@gsLineThicknessF = 5.0
  dummy = gsn_add_polyline(wks,plot,(/-10,500/),(/0,0/),zlineres)
end if


; -------------------------------------------------------------------------------------


;;; LABELS
  ; If normalized, don't label CLP/SHF
  if (plot_normalized) then
    stindx = 1
    numEventsBottom = True
  else
    stindx = 0
    numEventsBottom = False
  end if

  txres               = True
  txres@txFontHeightF = 0.018   ;0.015 and 0.013 before
  txres@txBackgroundFillColor="White"

  deltay = ymax-ymin
  deltay = deltay/40. ; I have tuned for 60 ---> lower spreads out more

  if (numEventsBottom) then
    yst = ymin+1.3*deltay
    ydel = 2*deltay
  else
    yst = ymax-1.3*deltay
    ydel = 2*deltay
  end if

  numlabels = new((/dimsizes(models),dimsizes(leadTimes)/),"graphic")
  do i = stindx,dimsizes(models)-1
  do j = 0,dimsizes(leadTimes)-1
    txres@txFontColor=linecolors(i)
    xloc=leadTimes(j)

    ; Shift rightmost count labels so they don't straddle plot border
    if (plot_normalized) then
        if(leadTimes(j) .eq. 120)
          xloc = 115
        end if
    else
        if(leadTimes(j) .eq. max(leadTimes))
          xloc = max(leadTimes) - 7 ; was 5
        end if
    end if

  if (numEventsBottom) then
    numlabels(i,j) = gsn_add_text(wks,plot,tostring(toint(means(i,j,19))),xloc,(yst+ydel*(i-stindx)),txres)
  else
    numlabels(i,j) = gsn_add_text(wks,plot,tostring(toint(means(i,j,19))),xloc,(yst-ydel*(i-stindx)),txres)
  end if

  end do
  end do

;
; Remove this text string, and create some new ones to add.
;
;  NhlRemoveAnnotation(plot,annoid)

  amres = True
  txres@txBackgroundFillColor = -1
  ;txres@txFont                = "helvetica-bold"
  txres@txFontHeightF = .035
  txres@txFontColor = "Black"
  txres@txPerimOn = True

  txid1 = gsn_create_text(wks,panelLabel, txres)


  amres@amParallelPosF   = 0.48    ; This is the right edge of the plot.
  amres@amOrthogonalPosF = 0.48    ; This is the bottom edge of the plot.
  if (panelLabelLoc .eq. "TopRight") then
    amres@amOrthogonalPosF = amres@amOrthogonalPosF*-1
  end if
;
; By default, the center of the string is what's placed at the position
; indicated by amParallelPosF and amOrthogonalPosF. You can use amJust
; to change this to any one of 9 positions: "CenterCenter" (default),
; "TopCenter", "TopRight", "CenterRight", "BottomRight", "BottomCenter",
; "BottomLeft", "CenterLeft", "TopLeft".
;
  amres@amJust           = panelLabelLoc

  annoid1 = gsn_add_annotation(plot, txid1, amres)

; -------------------------------------------------------------------------------------

draw(plot)
frame(wks)



end

