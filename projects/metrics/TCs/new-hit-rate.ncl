;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"
load "./taylor_diagram_cam.ncl"

begin

;=================== User Settings ================================

out_type = "pdf"
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms

;======================= Constants ================================
ms_to_kts = 1.94384449

dq       = str_get_dq()
date_cmd = "date +" + dq + "%a %b %d %H:%M:%S %Z %Y" + dq


; this is really only for correlations
styr=1980
enyr=2014
nyears=enyr-styr+1



thefile:="dev/ibtracs-1980-2015-GLOB.txt"
;thefile:="dev/ibtracs-1998-2008-GLOB.txt"
;thefile:="dev/test.txt"

ncols := 11 ; number of columns in non-header rows of trajectory file
maxLines := -1  ; set to -1 for auto-detection
traj_data := getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres  = tofloat(traj_data(:,4,:))/100.
xwind  = traj_data(:,5,:)*1.0
xyear  = toint(traj_data(:,7,:))
xmonth  = toint(traj_data(:,8,:))
xday  = toint(traj_data(:,9,:))
xhour  = toint(traj_data(:,10,:))
timeunits="days since 1900-01-01 00:00"
xzero=xhour
xzero=0
xtime = cd_inv_calendar(xyear,xmonth,xday,xhour,xzero,xzero,timeunits,0)
; get nstorms + ntimes (max) from dims of one of the returned arrays
xdims=dimsizes(xlon)
xnstorms=xdims(0)
xntimes=xdims(1)

; =====

;thefile:="dev/traj.ab.0105"
thefile:="TRAJ_FINAL/trajectories.txt.MERRA2"

ncols := 11 ; number of columns in non-header rows of trajectory file
maxLines := -1  ; set to -1 for auto-detection
traj_data := getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
ylon  = traj_data(:,2,:)
ylat  = traj_data(:,3,:)
ypres  = tofloat(traj_data(:,4,:))/100.
ywind  = traj_data(:,5,:)*1.0
yyear  = toint(traj_data(:,7,:))
ymonth  = toint(traj_data(:,8,:))
yday  = toint(traj_data(:,9,:))
yhour  = toint(traj_data(:,10,:))
yzero=yhour
yzero=0
ytime = cd_inv_calendar(yyear,ymonth,yday,yhour,yzero,yzero,timeunits,0)

; get nstorms + ntimes (may) from dims of one of the returned arrays
ydims=dimsizes(ylon)
ynstorms=ydims(0)
yntimes=ydims(1)


; cleanup
delete(traj_data)

stDateIBUnits=cd_inv_calendar(styr,1,1,0,0,0,timeunits,0)
enDateIBUnits=cd_inv_calendar(enyr,12,31,23,0,0,timeunits,0)

tracktime=ndtooned(ytime)
tracklat=ndtooned(ylat)
tracklon=ndtooned(ylon)

onedtime=ndtooned(xtime)
onedlat=ndtooned(xlat)
onedlon=ndtooned(xlon)
onedwind=ndtooned(xwind)

print(num(.not.ismissing(onedtime)))
print(num(.not.ismissing(tracktime)))
print(stDateIBUnits+" "+enDateIBUnits)
tracktime=where(tracktime .ge. stDateIBUnits .and. tracktime .le. enDateIBUnits,tracktime,tracktime@_FillValue)
onedtime=where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedtime,onedtime@_FillValue)
print(num(.not.ismissing(onedtime)))
print(num(.not.ismissing(tracktime)))

; THIS IS THE OLD ZARZYCKI AND ULLRICH CODE
; FALSE ALARM POINT BY POINT

wcStrtFAPBP = systemfunc(date_cmd)



FAarr=new(dimsizes(tracktime),"integer")
FAarr=where(ismissing(tracktime),FAarr@_FillValue,1)
jndices = ind(.not.ismissing(onedtime))



do j = 0,dimsizes(jndices)-1
  jx = jndices(j)
  obslat = onedlat(jx)
  obslon = onedlon(jx)
  indices = ind(tracktime .eq. onedtime(jx))
  if(.not.all(ismissing(indices))) then 
    do i = 0,dimsizes(indices)-1
      ix = indices(i)
      tklat = tracklat(ix)
      tklon = tracklon(ix)
      if(gc_latlon(obslat,obslon,tklat,tklon,2,2) .le. 2.0)
        FAarr(ix)=FAarr@_FillValue
      end if
    end do
  end if
  delete(indices)
end do
delete(jndices)

numTracked = num(.not.ismissing(tracktime))
if(all(ismissing(FAarr))) then
FAR = 0
else
FAR = tofloat(sum(FAarr)/tofloat(numTracked))
end if
print("=======================================================")
print("FAR: "+FAR)

wallClockElapseTime(wcStrtFAPBP, "Point by point false alarm", 0)




; HR point by point

wcStrtHRPBP = systemfunc(date_cmd)

ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!
do b = 0,dimsizes(ibcutwindArr)-1
ibcutwind=ibcutwindArr(b)
if (ibcutwind .gt. 0) then
  onedlat = where(onedwind.lt.ibcutwind,onedlat@_FillValue,onedlat)
  onedlon = where(onedwind.lt.ibcutwind,onedlon@_FillValue,onedlon)
  onedtime = where(onedwind.lt.ibcutwind,onedtime@_FillValue,onedtime)
end if

hit = 0
tcfound=False
jndices = ind(.not.ismissing(onedtime))
do j = 0,dimsizes(jndices)-1
  jx = jndices(j)
  obslat = onedlat(jx)
  obslon = onedlon(jx)
  indices = ind(tracktime .eq. onedtime(jx))
  if(.not.all(ismissing(indices))) then 
    do i = 0,dimsizes(indices)-1
      ix = indices(i)
      tklat = tracklat(ix)
      tklon = tracklon(ix)
      if(gc_latlon(obslat,obslon,tklat,tklon,2,2) .le. 2.0)
        hit = hit+1
        tcfound=True
        ;print("+++++"+onedname(jx)+" "+obslat+" "+obslon+" "+tklat+" "+tklon+" "+trackyear(ix)+" "+trackmonth(ix)+" "+trackday(ix)+" "+trackhour(ix))
        break ; Need to break out of this loop in case we double count storms close by
      end if
    end do
  end if
  delete(indices)
  if (tcfound .eq. False) then
    ;print("-----"+onedname(jx)+" "+obslat+" "+obslon+" "+trackyear(ix)+" "+trackmonth(ix)+" "+trackday(ix)+" "+trackhour(ix))
  end if
  ; Reset tcFound to false
  tcfound=False
end do
delete(jndices)
numObs = num(.not.ismissing(onedtime))
numTracked = num(.not.ismissing(tracktime))
HRarray = hit/tofloat(numObs)
print("windcut: "+ibcutwind+"    HR: "+HRarray)
end do

wallClockElapseTime(wcStrtHRPBP, "Point by point hit rate", 0)


; =========================================================================================




;   DO FILTERS
analyzeObsStorm = new(xnstorms,"logical")

analyzeObsStorm=True

; filter by intensity
xmwind=dim_max_n_Wrap(xwind,1)
analyzeObsStorm=where(xmwind.gt.17.0,analyzeObsStorm,False)

;filter by year
xgyear=xyear(:,0)
analyzeObsStorm=where(xgyear.ge.styr .and. xgyear.le.enyr, analyzeObsStorm, False)





; HIT RATE

wcStrtHR = systemfunc(date_cmd)

xhitRateArray = new(xnstorms,"logical")
do ii = 0,xnstorms-1
  if (analyzeObsStorm(ii)) then
    isHit=False
    do jj = 0,xntimes-1
      ;print(ii+" "+jj)
      if (.not.isHit .and. .not.ismissing(xtime(ii,jj)) ) then
        matchedTimes = where(ytime.eq.xtime(ii,jj),ytime,ytime@_FillValue)
        if (any(matchedTimes.ne.matchedTimes@_FillValue)) then
          ;print("possible match? storm "+ii)
          ; find non-zero indices

          matchedTimes1D = ndtooned(matchedTimes)     ; only do this once
          indMax := ind_resolve(ind(matchedTimes1D.ne.matchedTimes1D@_FillValue),dimsizes(matchedTimes))  ; locations of max
          delete (matchedTimes1D)
          potentialMatchDims = dimsizes(indMax)
          potentialStormsNum = potentialMatchDims(0)
          if (.not.ismissing(potentialStormsNum)) then
            xlatSingle = xlat(ii,jj)
            xlonSingle = xlon(ii,jj)
            do zz = 0,potentialStormsNum-1
              ylatSingle=ylat(indMax(zz,0),indMax(zz,1))
              ylonSingle=ylon(indMax(zz,0),indMax(zz,1))
              if (gc_latlon(xlatSingle,xlonSingle,ylatSingle,ylonSingle,2,2) .le. 2.0) then
                ;print("Found match to: "+xlatSingle+" "+xlonSingle+"   at "+ylatSingle+" "+ylonSingle+" on "+cd_calendar(xtime(ii,jj),-3))
                isHit=True
                break
              end if
            end do
          end if
        else
          continue
        end if
      else
        break
      end if
    end do
    xhitRateArray(ii) = isHit
  end if
end do

numhits=tofloat(num(xhitRateArray.eq.True))
nummisses=tofloat(num(xhitRateArray.eq.False))
HR = numhits / (numhits + nummisses)
print("HR "+HR)

wallClockElapseTime(wcStrtHR, "Storm hit rate", 0)


; FALSE ALARM RATE

wcStrtFA = systemfunc(date_cmd)

yFalseAlarmArray = new(ynstorms,"logical")
do ii = 0,ynstorms-1
  isFA=True
  do jj = 0,yntimes-1
    ; if still flagged as potential FA and a valid ytime exists, keep looping
    if (isFA .and. .not.ismissing(ytime(ii,jj)) ) then
      matchedTimes := where(xtime.eq.ytime(ii,jj),xtime,xtime@_FillValue)
      if (any(matchedTimes.ne.matchedTimes@_FillValue)) then
        matchedTimes1D = ndtooned(matchedTimes)     ; only do this once
        indMax := ind_resolve(ind(matchedTimes1D.ne.matchedTimes1D@_FillValue),dimsizes(matchedTimes))  ; locations of max
        delete (matchedTimes1D)
        potentialMatchDims = dimsizes(indMax)
        potentialStormsNum = potentialMatchDims(0)
        if (.not.ismissing(potentialStormsNum)) then
          ylatSingle = ylat(ii,jj)
          ylonSingle = ylon(ii,jj)
          do zz = 0,potentialStormsNum-1
            xlatSingle=xlat(indMax(zz,0),indMax(zz,1))
            xlonSingle=xlon(indMax(zz,0),indMax(zz,1))
            if (gc_latlon(ylatSingle,ylonSingle,xlatSingle,xlonSingle,2,2) .le. 2.0) then
              ;print("Found match to: "+ylatSingle+" "+ylonSingle+"   at "+xlatSingle+" "+xlonSingle+" on "+cd_calendar(ytime(ii,jj),-3))
              isFA=False
              break
            end if
          end do
        end if
      else
        continue
      end if
    else
      break
    end if
  end do
  yFalseAlarmArray(ii) = isFA
end do

numalarms=tofloat(num(yFalseAlarmArray.eq.True))
nummatches=tofloat(num(yFalseAlarmArray.eq.False))
FARS = numalarms/(numalarms+nummatches)
print("FAR "+FARS)

wallClockElapseTime(wcStrtFA, "Storm false alarm", 0)





 
end
