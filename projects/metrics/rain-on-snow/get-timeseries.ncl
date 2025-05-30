;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "~/ncl/functions/getTrajectoriesGeneric.ncl"

begin

testLat=42.
testLon=285.
threshold=10.

thefile="tempest.LENS.1990.002"  ; trajectory file full path
ncols = -1 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres  = traj_data(:,4,:)/100.
xyyyy = traj_data(:,5,:)
xmm = traj_data(:,6,:)
xdd = traj_data(:,7,:)
xhh = traj_data(:,8,:)

xzero=xmm
xzero=0.

units="days since 1920-01-01 00:00:00"
opt=0
opt@calendar="noleap"

xtime = cd_inv_calendar(xyyyy,xmm,xdd,xzero,xzero,xzero,units,opt)

dims=dimsizes(xlon)
nstorms=dims(0)
ntimes=dims(1)

iz = ind(.not.ismissing(ndtooned(xlon))) 

lon = ndtooned(xlon)
lon := lon(iz)

lat = ndtooned(xlat)
lat := lat(iz)

time = ndtooned(xtime)
time := time(iz)

sttime=cd_inv_calendar(1990,1,1,0,0,0,units,opt)
entime=cd_inv_calendar(2006,1,1,0,0,0,units,opt)
print(sttime+" "+entime)

seqtimes=fspan(sttime,entime,toint(entime-sttime+1))
seqtimes@units=units
seqtimes@calendar=opt@calendar

isStorm=new(dimsizes(seqtimes),"logical")
isStorm=False

do ii = 0,dimsizes(seqtimes)-1
  thisTime:=seqtimes(ii)
  if (any(time.eq.thisTime))
    whichTimes := ind(time.eq.thisTime)
    whichLats  := lat(whichTimes)
    whichLons  := lon(whichTimes)
    whichDists := gc_latlon(testLat,testLon,whichLats,whichLons,2,2)
    if (any(whichDists .lt. threshold))
      print("match!")
      isStorm(ii)=True
    else
      print("can't find one nearby")
    end if
  else
    print("no match")
  end if
end do

print(cd_calendar(seqtimes,-2)+" "+isStorm)
 fname = "example2.txt"
 write_table(fname, "w", [/cd_calendar(seqtimes,-2), isStorm/], "%d%s")

end