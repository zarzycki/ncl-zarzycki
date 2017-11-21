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

filename="CV_stats.csv"
out_type="x11"

print("ACE_CV  NUM_AS_CV NUM_HT_CV  HR_HU_CV HR_TS FA_AS")

;outputVars=(/"ACE_CV","NUM_AS_CV","NUM_HT_CV","HR_HU_CV","HR_TS","FA_AS"/)
outputVars=(/"COUNT","TCDAYS","ACE","HR_TS","HR_HU","FA_AS"/)



  numVars=dimsizes(outputVars)

print("Reading CSV file...")
lines = asciiread(filename,-1,"string")
delim = ","

print("Parsing CSV file...")
ACE_CV=tofloat(str_get_field(lines,1,delim))
nrows=dimsizes(ACE_CV)
NUM_AS_CV=tofloat(str_get_field(lines,2,delim))
NUM_HT_CV=tofloat(str_get_field(lines,3,delim))
HR_HU_CV=tofloat(str_get_field(lines,4,delim))
HR_TS_CV=tofloat(str_get_field(lines,5,delim))
FA_AS_CV=tofloat(str_get_field(lines,6,delim))
delete(lines)
print("... end parsing file")


INDEXARR=ispan(1,nrows,1)


  wks   = gsn_open_wks (out_type,"cv-testing-")            ; open workstation

res                   = True                     ; plot mods desired
res@gsnDraw=False
res@gsnFrame=False

  res@tiMainString      = "CV by output for all MM experiments"
  res@trYMinF=0.0
  res@trYMaxF=2.0

  ;res@vpHeightF=0.6  ; default is 0.6
  ;res@vpWidthF=0.35

  res@xyMarkLineMode    = "Markers"                ; choose to use markers
  res@xyMarker       = 16                       ; choose type of marker
  res@xyMarkerSizeF     = 0.01                     ; Marker size (default 0.01)

  res@tiYAxisString = "Coefficient of variation"

  numData=6
  xyArr=new((/numData,nrows/),"float")

  do jj = 0,numData-1
      if (jj .eq. 2) then
        print(ACE_CV)
        xyArr(jj,:) = ACE_CV
      else if (jj .eq. 0) then
        print(NUM_AS_CV)
        xyArr(jj,:) = NUM_AS_CV
      else if (jj .eq. 1) then
        print(NUM_HT_CV)
        xyArr(jj,:) = NUM_HT_CV
      else if (jj .eq. 4) then
        print(HR_HU_CV)
        xyArr(jj,:) = HR_HU_CV
      else if (jj .eq. 3) then
        print(HR_TS_CV)
        xyArr(jj,:) = HR_TS_CV
      else if (jj .eq. 5) then
        print(FA_AS_CV)
        xyArr(jj,:) = FA_AS_CV
      end if
      end if
      end if
      end if
      end if
      end if
  end do

  eps=0.1
  random_setallseed(36484749, 9494848)
  xlow   =  1.0-eps
  xhigh  =  1.0+eps
  xArr   = random_uniform(xlow, xhigh, dimsizes(xyArr)) ; uniform(10, 64, 128)
  res@trXMinF=0.0
  res@trXMaxF=tofloat(numData) + 1.0

  xax_mon = ispan(1,numData,1)
  res@tmXBMode = "Explicit"
  res@tmXBValues = xax_mon
  res@tmXBLabels = outputVars
  res@tmXBLabelAngleF=35.0

  res@xyMonoMarkerColor = True
  res@xyMarkerColor    = "black"           ; Marker color
  plot = gsn_csm_xy(wks,xArr(0,:),xyArr(0,:),res)                    ; create plot

  do kk = 1,numData-1
    if (kk .ge. 1 .and. kk .le. 2)
      res@xyMarkerColor    = "black"           ; Marker color
    else if (kk .ge. 3 .and. kk .le. 4)
      res@xyMarkerColor    = "red"           ; Marker color
    else if (kk .ge. 5)
      res@xyMarkerColor    = "blue"           ; Marker color
    end if
    end if
    end if
    xArr = xArr+1.0
    plot_new = gsn_csm_xy(wks,xArr(kk,:),xyArr(kk,:),res)                    ; create plot
    overlay(plot,plot_new)
    delete(plot_new)
  end do










  draw(plot)
  frame(wks)



end

