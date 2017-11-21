;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/sorting.ncl"
;========================================================

begin

vartype="DZXXXXXX"  ; DZXXXXXX or TXXX

filename="/glade/p/work/zarzycki/reanalysis-20160803/cat.rates.txt.ALL."+vartype
out_type="pdf"

whatVar="HR_TS"  ;HRMINFA, HR_TS, FA_AS

datasets=(/"JRA","MERRA2","MERRA","CFSR"/)

if (vartype .eq. "TXXX") then
  vars=(/"T500","T400","T300"/)
else
  vars=(/"DZ300500","DZ200500","DZ400500"/)
end if
;colors=(/"orange","SteelBlue1","seagreen1"/)
colors=(/"red4","blue","green"/)

do_plot=False
do_ranking_plot=False
do_scatter_plot=True
sortDir=1    ; 1 is descending, 0 is ascending
nvars=12     ; number of sample vars

  numVars=dimsizes(vars)
  numData=dimsizes(datasets)

print("Reading CSV file...")
lines = asciiread(filename,-1,"string")
delim = ","

print("Parsing CSV file...")
NUM_AS=tointeger(str_get_field(lines,1,delim))
nrows=dimsizes(NUM_AS)
HR_AS=tofloat(str_get_field(lines,2,delim))
HR_TS=tofloat(str_get_field(lines,3,delim))
HR_HU=tofloat(str_get_field(lines,4,delim))
HR_MH=tofloat(str_get_field(lines,5,delim))
FA_AS=tofloat(str_get_field(lines,6,delim))
NUM_HT=tointeger(str_get_field(lines,7,delim))
ACE=tointeger(str_get_field(lines,8,delim))
CONFIG=str_get_field(lines,9,delim)
THEVAR=str_get_field(lines,10,delim)
ENSNUM=str_get_field(lines,11,delim)
varStruct=new((/nvars,nrows/),"float")
do i = 0,nvars-1
  ix = 12+i
  varStruct(i,:) = tofloat(str_get_field(lines,ix,delim))
end do
delete(ix)
;var01=tofloat(str_get_field(lines,10,delim))
;var02=tofloat(str_get_field(lines,11,delim))
;var03=tofloat(str_get_field(lines,12,delim))
;var04=tofloat(str_get_field(lines,13,delim))
;var05=tofloat(str_get_field(lines,14,delim))
;var06=tofloat(str_get_field(lines,15,delim))
;var07=tofloat(str_get_field(lines,16,delim))
;var08=tofloat(str_get_field(lines,17,delim))
;var09=tofloat(str_get_field(lines,18,delim))
;var10=tofloat(str_get_field(lines,19,delim))
;var11=tofloat(str_get_field(lines,20,delim))
delete(lines)
print("... end parsing file")

INDEXARR=ispan(1,nrows,1)

; Do calculations post read
HRMINFA=HR_TS-FA_AS



if (do_scatter_plot) then
  wks   = gsn_open_wks (out_type,"scatter_img/scatter-ranking-"+vartype+"-"+whatVar)            ; open workstation

  res                   = True                     ; plot mods desired
  res@gsnDraw=False
  res@gsnFrame=False

if (whatVar .eq. "HRMINFA") then
  PLOTVAR=HRMINFA
  res@tiMainString      = "Var Rankings (HR-FA)"
  res@trYMinF=-0.8
  res@trYMaxF=0.61
else if (whatVar .eq. "HR_TS") then
  PLOTVAR=HR_TS
  res@tiMainString      = "HR_TS"
  res@trYMinF=0.0
  res@trYMaxF=1.0
else if (whatVar .eq. "FA_AS") then
  PLOTVAR=FA_AS
  res@tiMainString      = "FA_AS"
  res@trYMinF=0.0
  res@trYMaxF=1.0
else
  print("incorrect whatvar... exiting...")
  exit
end if
end if
end if

  res@vpHeightF=0.6  ; default is 0.6
  res@vpWidthF=0.35

  res@xyMarkLineMode    = "Markers"                ; choose to use markers
  res@xyMarker       = 16                       ; choose type of marker
  res@xyMarkerSizeF     = 0.0021                     ; Marker size (default 0.01)


  printVarSummary(INDEXARR)

  nSamples=dimsizes(INDEXARR)/numVars/numData

  xyArr=new((/numData,numVars,(dimsizes(INDEXARR)/numData)/),"float")
  do jj = 0,numData-1
    INDVAR  = where(CONFIG.eq.datasets(jj),PLOTVAR,PLOTVAR@_FillValue)
    iz = ind(.not.ismissing(INDVAR))
    if (.not.all(ismissing(iz))) 
      TMPVARSORT = THEVAR(iz)   
      TMPSORTVAR = PLOTVAR(iz)
    else
      print ("X,Y,Z not created: all z are missing")
    end if

    do ii = 0,numVars-1
      xyArr(jj,ii,:) = where(TMPVARSORT.eq.vars(ii),TMPSORTVAR,TMPSORTVAR@_FillValue)
    end do
    delete(TMPVARSORT)
    delete(TMPSORTVAR)
    delete(INDVAR)
    delete(iz)
  end do

  ;xArr=xyArr
  ;xArr=1.0

  eps=0.35
  random_setallseed(36484749, 9494848)
  xlow   =  1.0-eps
  xhigh  =  1.0+eps
  xArr   = random_uniform(xlow, xhigh, dimsizes(xyArr)) ; uniform(10, 64, 128)
  res@trXMinF=0.0
  res@trXMaxF=tofloat(numData) + 1.0

  xax_mon = ispan(1,numData,1)
  res@tmXBMode = "Explicit"
  res@tmXBValues = xax_mon
  res@tmXBLabels = datasets
  res@tmXBLabelAngleF=25.0

  res@xyMonoMarkerColor = False
  res@xyMarkerColors    = colors           ; Marker color
  plot = gsn_csm_xy(wks,xArr(0,:,:),xyArr(0,:,:),res)                    ; create plot

  do kk = 1,numData-1
    xArr = xArr+1.0
    plot_new = gsn_csm_xy(wks,xArr(kk,:,:),xyArr(kk,:,:),res)                    ; create plot
    overlay(plot,plot_new)
    delete(plot_new)
  end do






;================================================================================

lgres                    = True
lgres@lgAutoManage       = False

lgres@vpWidthF           = 0.10       ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.10       ; was 0.08        ; height of legend (NDC)

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

lgres@lgBoxMinorExtentF  = 0.2  ; controls how wide the box holding the legend items (lines and markers) can be in relation to legend


;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.09
lgres@lgLabelFontAspectF      = 1.5
lgres@lgLabelConstantSpacingF = 0.0

legendType = "Markers"
markerSize = .008
markerIndex = 16

lgres@lgMonoMarkerIndex     = True

lgres@lgItemCount        = numVars
lgres@lgItemType        = res@xyMarkLineMode
lgres@lgMarkerIndex    = res@xyMarker
lgres@lgMarkerThicknessF  = res@xyMarkerSizeF
lgres@lgMarkerColors      = colors
legend_labels = vars

res@xyMarkLineMode    = "Markers"                ; choose to use markers
res@xyMarkers         = 16                       ; choose type of marker
res@xyMarkerSizeF     = 0.0035                     ; Marker size (default 0.01)


legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

amres = True
amres@amParallelPosF   = -0.30               ; negative left / positive right
amres@amOrthogonalPosF = .4             ; negative up / positive down

annoid1 = gsn_add_annotation(plot,legend,amres)   ; add legend to plot

;================================================================================



  draw(plot)
  frame(wks)


end if

end
