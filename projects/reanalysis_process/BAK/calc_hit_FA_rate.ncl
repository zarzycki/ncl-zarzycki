;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
;========================================================
begin

if (.not. isdefined("inputParms"))
  print("defining input parms")
  inputParms=""
end if

if (.not. isdefined("whichCase"))
  print("defining whichCase")
  whichCase="NA"
end if

;summaryFileName
; implement check to see if zero lines
quote = inttochar(34)
totLines = systemfunc("grep -r start "+traj_dir+"/"+traj_filename+" | wc -l")
if (totLines .lt. 1) then
  system("echo "+quote+ 0+","+0+","+0+","+0+","+0+","+0+","+0+quote+" >> "+traj_dir+"/"+summaryFileName)
  exit
end if
delete(totLines)

;trajOutFormat="tempest" ; tempest or gfdl

ibstyr=2007
ibenyr=2007

;traj_dir = "/glade/p/work/zarzycki/tempestextremes/"
;traj_filename = "traj.txt"

factor=1.0
ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

wcStrt     = systemfunc("date")

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"

ibfile = addfile(ibdir+ibfilename,"r")



;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

iblat = ibfile->lat_for_mapping(stix:enix,:)*.01
iblon = ibfile->lon_for_mapping(stix:enix,:)*.01
ibyear = toint(ibfile->season(stix:enix))
ibtype = toint(ibfile->nature_for_mapping(stix:enix,:))
ibwind = ibfile->source_wind(stix:enix,:,:)*.1/ms_to_kts
ibtime = ibfile->source_time(stix:enix,:)
ibnamechar = ibfile->name(stix:enix,:)
;ibname = conform(ibwind,ibnamesingle,0)

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

; Need to convert char to str for name
ibname = new(dimsizes(ibyear),"string")
do i = 0,dimsizes(ibyear)-1
  ibname(i)=oneDtostring(ibnamechar(i,:))
  ibname(i)=str_sub_str(ibname(i),",","")
end do
  
; Average over all centers -- for plotting, this is ok even if there
; are small discrepancies
ibwind_ = dim_avg_n_Wrap(ibwind,2)

; Convert to 1-D data structures
onedwind = ndtooned(ibwind_)
onedlat = ndtooned(iblat)
onedlon = ndtooned(iblon)
onedtype = ndtooned(ibtype)
;onedyear = ndtooned(conform_dims(dimsizes(iblat),ibyear,0))
onedtime = ndtooned(ibtime)
onedname = ndtooned(conform_dims(dimsizes(iblat),ibname,0))

ib_nrows = dimsizes(onedwind)

onedwind = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedwind,onedwind@_FillValue)
onedlat = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedlat,onedlat@_FillValue)
onedlon = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedlon,onedlon@_FillValue)
onedtime = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedtime,onedtime@_FillValue)
onedname = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedname,onedname@_FillValue)
;onedyear = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedyear,onedyear@_FillValue)

; Correct for non-standard times
onedwind = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedwind@_FillValue,onedwind)
onedlat = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedlat@_FillValue,onedlat)
onedlon = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedlon@_FillValue,onedlon)
onedtime = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedtime@_FillValue,onedtime)
onedname = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedname@_FillValue,onedname)
;onedyear = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedyear@_FillValue,onedyear)

if (1 .eq. 0) then
  printVarSummary(onedwind)
  printVarSummary(onedlat)
  printVarSummary(onedlon)
  printVarSummary(onedtime)
  printVarSummary(onedname)
  ;printVarSummary(onedyear)

  iz = ind(.not.ismissing(onedwind))
  onedwind_ = onedwind(iz)
  delete(onedwind)
  onedwind = onedwind_
  delete(onedwind_)

  iz = ind(.not.ismissing(onedlat))
  onedlat_ = onedlat(iz)
  delete(onedlat)
  onedlat = onedlat_
  delete(onedlat_)

  iz = ind(.not.ismissing(onedlon))
  onedlon_ = onedlon(iz)
  delete(onedlon)
  onedlon = onedlon_
  delete(onedlon_)

  iz = ind(.not.ismissing(onedtime))
  onedtime_ = onedtime(iz)
  delete(onedtime)
  onedtime = onedtime_
  delete(onedtime_)

  iz = ind(.not.ismissing(onedname))
  onedname_ = onedname(iz)
  delete(onedname)
  onedname = onedname_
  delete(onedname_)

  ;iz = ind(.not.ismissing(onedyear))
  ;onedyear_ = onedyear(iz)
  ;delete(onedyear)
  ;onedyear = onedyear_
  ;delete(onedyear_)
end if

;onedwind = where(onedyear.gt.ibenyr,onedwind@_FillValue,onedwind)
;onedlat = where(onedyear.gt.ibenyr,onedlat@_FillValue,onedlat)
;onedlon = where(onedyear.gt.ibenyr,onedlon@_FillValue,onedlon)
;onedtime = where(onedyear.gt.ibenyr,onedtime@_FillValue,onedtime)
;onedname = where(onedyear.gt.ibenyr,onedname@_FillValue,onedname)
;onedwind = where(onedyear.lt.ibstyr,onedwind@_FillValue,onedwind)
;onedlat = where(onedyear.lt.ibstyr,onedlat@_FillValue,onedlat)
;onedlon = where(onedyear.lt.ibstyr,onedlon@_FillValue,onedlon)
;onedtime = where(onedyear.lt.ibstyr,onedtime@_FillValue,onedtime)
;onedname = where(onedyear.lt.ibstyr,onedname@_FillValue,onedname)

;=============================================================================
; Now we do manually tracked data
;=============================================================================

totnumstorms = systemfunc("grep -r start "+traj_dir+"/"+traj_filename+" | wc -l")
randDate = systemfunc("date +%s%N")  
traj_cleanfile = "traj_filt_clean."+randDate+".TMP"

if (trajOutFormat .eq. "gfdl") then
  print("Removing text headers from trajectories")
  system("grep -v '^start' "+ traj_dir+"/"+traj_filename +" > "+traj_cleanfile+"")
;  290.50   34.25   24.15  992.25  1980     1    23     6

  traj_ncols = numAsciiCol(traj_cleanfile)
  ; Given the # of columns, we can use readAsciiTable to read this file.
  traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  
  print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
        " columns of data.")
  
  print("Removing temporary file:"+traj_cleanfile)
  system("rm -rf "+traj_cleanfile)

  trackwind = traj_data(:,2)*factor
  tracklon = traj_data(:,0)
  tracklat = traj_data(:,1)
  trackpres = traj_data(:,3)
  trackyear = toint(traj_data(:,4))
  trackmonth = toint(traj_data(:,5))
  trackday = toint(traj_data(:,6))
  trackhour = toint(traj_data(:,7))
  trackmin = trackhour
  tracksec = trackhour
  trackmin = 0
  tracksec = 0
end if

if (trajOutFormat .eq. "tempest") then
  print("Removing text headers from trajectories")
  system("grep -v '^start' "+ traj_dir+"/"+traj_filename +" > "+traj_cleanfile+"")
  traj_ncols = numAsciiCol(traj_cleanfile)
  traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
     " columns of data.")
  print("Removing temporary file:"+traj_cleanfile)
  system("rm -rf "+traj_cleanfile)

  trackwind = traj_data(:,5)*factor
  tracklon = traj_data(:,3)
  tracklat = traj_data(:,4)
  trackpres = traj_data(:,7)
  trackyear = toint(traj_data(:,8))
  trackmonth = toint(traj_data(:,9))
  trackday = toint(traj_data(:,10))
  trackhour = toint(traj_data(:,11))
  trackmin = trackhour
  tracksec = trackhour
  trackmin = 0
  tracksec = 0
end if

tracktime = new(dimsizes(trackhour),"double")

do i = 0,dimsizes(trackhour)-1
  tracktime(i) = cd_inv_calendar(trackyear(i),trackmonth(i),trackday(i),trackhour(i),0,0,ibtime@units,0)
end do

;=============================================================================
; False alarm calculations!
; We will first see if the tracked data matches ANY point in the ibtracs array
;=============================================================================

wcFAStrt     = systemfunc("date")

FAarr=new(dimsizes(tracktime),"integer")
FAarr=1
namesTracked=new(dimsizes(tracktime),"string")
namesTracked="..."
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
          namesTracked(ix)=onedname(jx)
        end if
      end do
    end if
    delete(indices)
;     do i = 0,dimsizes(tracktime)-1
;       if(tracktime(i) .eq. onedtime(j)) then
;       tklat = tracklat(i)
;       tklon = tracklon(i)
;         if(gc_latlon(obslat,obslon,tklat,tklon,2,2) .le. 2.0)
;           FAarr(i)=FAarr@_FillValue
;           break
;         end if
;       end if
;     end do
  ;end if
end do
delete(jndices)

wallClockElapseTime(wcFAStrt, "False alarm calculation", 0)

; Figure out how many storms we tracked
nameCount=0
do z = 0,dimsizes(ibname)-1
  if (any(namesTracked .eq. ibname(z)))
    nameCount=nameCount+1
  end if
end do
print("Tracked: "+nameCount+" of "+(dimsizes(ibname)-1))

;=============================================================================
; Hit race calculations!
; We will first see if the tracked data matches ANY point in the ibtracs array
;=============================================================================


wcHRStrt     = systemfunc("date")
HRarray = new(dimsizes(ibcutwindArr),"float")

; Make any "pre-cuts" based on storm type, etc.
; Only cut out tropical storms
print("Cutting out non-tropical storm points")
onedwind = where(onedtype.ge.1,onedwind@_FillValue,onedwind)
onedlat = where(onedtype.ge.1,onedlat@_FillValue,onedlat)
onedlon = where(onedtype.ge.1,onedlon@_FillValue,onedlon)
onedtime = where(onedtype.ge.1,onedtime@_FillValue,onedtime)
onedname = where(onedtype.ge.1,onedname@_FillValue,onedname)

do b = 0,dimsizes(ibcutwindArr)-1
ibcutwind=ibcutwindArr(b)
if (ibcutwind .gt. 0) then
  onedwind = where(onedwind.lt.ibcutwind,onedwind@_FillValue,onedwind)
  onedlat = where(onedwind.lt.ibcutwind,onedlat@_FillValue,onedlat)
  onedlon = where(onedwind.lt.ibcutwind,onedlon@_FillValue,onedlon)
  onedtime = where(onedwind.lt.ibcutwind,onedtime@_FillValue,onedtime)
  onedname = where(onedwind.lt.ibcutwind,onedname@_FillValue,onedname)
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
    ;do i = 0,dimsizes(tracktime)-1
    ;  if(tracktime(i) .eq. onedtime(j)) then
    ;  tklat = tracklat(i)
    ;  tklon = tracklon(i)
    ;    if(gc_latlon(obslat,obslon,tklat,tklon,2,2) .le. 2.0)
    ;      hit = hit+1
    ;      tcfound=True
    ;      print("+++++"+onedname(j)+" "+obslat+" "+obslon+" "+tklat+" "+tklon+" "+trackyear(i)+" "+trackmonth(i)+" "+trackday(i)+" "+trackhour(i))
    ;      break
    ;    end if
    ;  end if
    ;end do

    if (tcfound .eq. False) then
      ;print("-----"+onedname(jx)+" "+obslat+" "+obslon+" "+trackyear(ix)+" "+trackmonth(ix)+" "+trackday(ix)+" "+trackhour(ix))
    end if

    ; Reset tcFound to false
    tcfound=False
end do
delete(jndices)

;do j = 0,dimsizes(onedtime)-1
;  if .not.ismissing(onedtime(j)) then
;    if (onedname(j) .eq. "WILMA") then
;      obslat = onedlat(j)
;      obslon = onedlon(j)
;      print("+++++"+onedname(j)+" "+obslat+" "+obslon+" "+onedtime(j))
;    end if
;  end if
;end do

numObs = num(.not.ismissing(onedtime))
numTracked = num(.not.ismissing(tracktime))
HRarray(b) = hit/tofloat(numObs)
print("windcut: "+ibcutwind+"    HR: "+HRarray(b))

end do

wallClockElapseTime(wcHRStrt, "Hit rate calculation", 0)

  print("=======================================================")
  print("totnumstorms: "+totnumstorms)
  print("num obs: "+numObs)
  print("num hits: "+hit)
  print("total number of tracked storms "+numTracked)
  print("false alarms: "+(numTracked-hit))
  print("FA2: "+sum(FAarr))

if(all(ismissing(FAarr))) then
  FAR = 0
else
  FAR = tofloat(sum(FAarr)/tofloat(numTracked))
end if

  print("=======================================================")
  print("FAR: "+FAR)

HRstr=""
do h = 0,dimsizes(HRarray)-1
  ;if (h .lt. dimsizes(HRarray)-1)
    HRstr=HRstr+","+HRarray(h)
  ;else
  ;  HRstr=HRstr+" "+HRarray(h)
  ;end if
end do

system("echo "+quote+ totnumstorms+HRstr+","+FAR+","+numTracked+","+whichCase+","+inputParms+quote+" >> "+traj_dir+"/"+summaryFileName)
  
wallClockElapseTime(wcStrt, "Total run time", 0)

exit

end
  
