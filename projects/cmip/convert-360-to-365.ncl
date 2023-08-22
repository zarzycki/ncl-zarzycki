begin

;filename="/glade/scratch/abolivar/tc_risk/input/HadGEM3-LM/r1i3p1f1/ua_day_HadGEM3-GC31-LM_highresSST-present_r1i3p1f1_gn_19790101-19791230.nc"
;va_day_HadGEM3-GC31-HM_highresSST-present_r1i1p1f1_gn_20120101-20120630.nc
;va_day_HadGEM3-GC31-HM_highresSST-present_r1i1p1f1_gn_20120701-20121230.nc
;hus_Amon_HadGEM3-GC31-HM_highresSST-present_r1i1p1f1_gn_197901-197912.nc

outdir="/glade/scratch/zarzycki/for-ana/"
filenopath=systemfunc("basename "+filename)
splitfilenopath=str_split(filenopath,"_")
var=splitfilenopath(0)

; read file into memory
f = addfile(filename,"r")

; get old time array
oldtime = f->time

; find out how many times are in time coord
old_ntimes = dimsizes(oldtime)

; load old var into memory
oldvar = f->$var$





; check to see time frequency
testtime = cd_convert(oldtime(0:1),"days since 0001-01-01 00:00")
timedelta = testtime(1) - testtime(0)

if (timedelta .eq. 1) then
  datafreq="daily"
else if (timedelta .eq. 0.25) then
  datafreq="sixhourly"
else if (timedelta .ge. 28 .and. timedelta .le. 31) then
  datafreq="monthly"
else
  print("unknown data freq")
end if
end if
end if
print("Found datafreq: "+datafreq)

; convert the 360_day calendar to yyyy,mm,dd etc.
mytime=cd_calendar(oldtime,0)
mm = toint(mytime(:,1))
dd = toint(mytime(:,2))
hh = toint(mytime(:,3))
mn = toint(mytime(:,4))
yyyy = toint(mytime(:,0))
yyyy@calendar="360"

; get the "day of year" for the 360_day calendar
doy = day_of_year(yyyy,toint(mm),toint(dd))

; check if we are at the end or beginning of a file so we can make sure we have 365 days in a year
pad_start = False
pad_end = False
if (any(doy.eq.1)) then
  print("We have to start the year")
  pad_start=True
end if
if (any(doy.eq.360)) then
  print("we have to end the year")
  pad_end=True
end if

; Shift day of year by 2 and reset calendar
; we'll pad 2 days in jan and 3 days in dec
yyyy@calendar="365"
doy = doy+2
; get new dates parsed
new_mm = monthday(yyyy,doy)/100
new_dd = mod(monthday(yyyy,doy),100)

; figure out how many new times we need (i.e., 0, 2, 3, or 5 for daily)
new_ntimes = old_ntimes
if (pad_start) then
  if (datafreq .eq. "daily")
    new_ntimes = new_ntimes + 2
  end if
end if
if (pad_end) then
  if (datafreq .eq. "daily")
    new_ntimes = new_ntimes + 3
  end if
end if

print(new_ntimes+" "+old_ntimes)

; what were the original dimensions?
orig_dims = dimsizes(oldvar)
numvardims = dimsizes(orig_dims)

; assume time = firstdim, what is our new size?
new_dims = orig_dims
new_dims(0) = new_ntimes

; create a new 4D var and new time array
newvar = new((/new_dims/),typeof(oldvar))
newtime = new(new_ntimes,typeof(oldtime))

; get the 360_day values in 365_day format using doy as an intermediary
opt = 0
opt@calendar="365_day"
zeros = new_dd
zeros = 0
halftime = cd_inv_calendar(yyyy,new_mm,new_dd,zeros,zeros,zeros,oldtime@units,opt)

print("newvar "+dimsizes(newvar))
print("oldvar "+dimsizes(oldvar))
print("new_ntimes "+new_ntimes+"    old_ntimes "+old_ntimes)

; define a front padded counter. If the data has pad_start *and* pad_end it means we have
; a full year of 360 day data and need to account for the fact that the time coordinate
; needs to be shifted +2 days when padding at the end. If pad_start is not tripped, then
; the end pad assumes we are starting mid-year (e.g., July 1) and there is no need to
; offset the day since nothing was padded in that file.
frontpadded=0

; if pad start, add at beginning
if (pad_start) then
  if (datafreq .eq. "daily")
    print("padding beginning")
    stnewix=2
    ennewix=2+old_ntimes-1
    stoldix=0
    enoldix=old_ntimes-1
    print("stnewix "+stnewix+"   ennewix "+ennewix)
    print("stoldix "+stoldix+"   enoldix "+enoldix)
    frontpadded=stnewix  ; update front padded to make sure we shift if end padding, too
    if (numvardims .eq. 4) then
      newvar(stnewix:ennewix,:,:,:) = oldvar(stoldix:enoldix,:,:,:)
      newvar(1,:,:,:) = oldvar(0,:,:,:)
      newvar(0,:,:,:) = oldvar(0,:,:,:)
    else
      newvar(stnewix:ennewix,:,:) = oldvar(stoldix:enoldix,:,:)
      newvar(1,:,:) = oldvar(0,:,:)
      newvar(0,:,:) = oldvar(0,:,:)
    end if
    ; walk backwards
    newtime(stnewix:ennewix) = halftime(stoldix:enoldix)
    newtime(1) = min(newtime) - 1.
    newtime(0) = min(newtime) - 1.
  end if
end if
if (pad_end) then
  if (datafreq .eq. "daily")
    print("padding end")
    stnewix=0+frontpadded
    ennewix=new_ntimes-1-3
    stoldix=0
    enoldix=old_ntimes-1
    print("stnewix "+stnewix+"   ennewix "+ennewix)
    print("stoldix "+stoldix+"   enoldix "+enoldix)
    ; plop the "valid" values in the new array up until the padding location
    if (numvardims .eq. 4) then
      newvar(stnewix:ennewix,:,:,:) = oldvar(stoldix:enoldix,:,:,:)
      newvar(new_ntimes-3,:,:,:) = oldvar(old_ntimes-1,:,:,:)
      newvar(new_ntimes-2,:,:,:) = oldvar(old_ntimes-1,:,:,:)
      newvar(new_ntimes-1,:,:,:) = oldvar(old_ntimes-1,:,:,:)
    else
      newvar(stnewix:ennewix,:,:) = oldvar(stoldix:enoldix,:,:)
      newvar(new_ntimes-3,:,:) = oldvar(old_ntimes-1,:,:)
      newvar(new_ntimes-2,:,:) = oldvar(old_ntimes-1,:,:)
      newvar(new_ntimes-1,:,:) = oldvar(old_ntimes-1,:,:)
    end if
    newtime(stnewix:ennewix) = halftime(stoldix:enoldix)
    ; walk forwards
    newtime(new_ntimes-3) = max(newtime) + 1.
    newtime(new_ntimes-2) = max(newtime) + 1.
    newtime(new_ntimes-1) = max(newtime) + 1.
  end if
end if

; if we pad nothing, we just adopt the shifted doy
if (.not. pad_end .and. .not. pad_start) then
  newvar = oldvar
  newtime = halftime
end if

; assign new dimensions
newtime@calendar="365_day"
newtime@units=oldtime@units
newvar!0="time"
if (numvardims .eq. 4) then
  newvar!2="lat"
  newvar!3="lon"
  newvar!1="plev"
  newvar&plev=oldvar&plev
else
  newvar!1="lat"
  newvar!2="lon"
end if
newvar&time=newtime
newvar&lat=oldvar&lat
newvar&lon=oldvar&lon

; write new var to file

system("mkdir -p "+outdir)
outfile = outdir+"/"+filenopath
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
print("Writing "+outfile)
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True)

ncdf->$var$ = newvar

end
