f = addfile("NLDAS_2_VIC.1985-2005.daily.nc","w")

time=f->time

ntimes=dimsizes(time)

timeArr = todouble(ispan(0,ntimes-1,1))

timeArr@units="days since 1985-01-01"

print(timeArr)

f->time=timeArr