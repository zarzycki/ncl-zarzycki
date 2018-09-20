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

;yyyy=1993
yrm1=yyyy-1
yrp1=yyyy+1

fils = systemfunc ("ls /glade2/collections/rda/data/ds526.0/gridded/NorAm.{"+yrm1+","+yyyy+","+yrp1+"}.daily.SNOW.gridded.nc") ; file paths
nyrs = dimsizes(fils)
print(nyrs)
f1   = addfiles (fils, "r")   
ListSetType (f1, "cat")        ; concatenate (=default)
;fname="./NorAm.1993.daily.SNOW.gridded.nc"
;f1=addfile(fname,"r")

flat=f1[0]->lat
flon=f1[0]->lon
fsnow=f1[:]->snow
ftime=f1[:]->time

fsnow = fsnow * 0.393701 / 10. ; mm to inches

mintime=min(ftime)
maxtime=max(ftime)

print(mintime+" "+maxtime)
newtime = fspan(mintime,maxtime+0.75,dimsizes(ftime)*4)
copy_VarAtts(ftime,newtime)

exStDate=cd_inv_calendar(yyyy,01,01,00,00,00000,newtime@units,0)
exEnDate=cd_inv_calendar(yyyy,12,31,18,00,00000,newtime@units,0)

print(exStDate+" "+exEnDate)
;=================== Create grid ==================================

gridsize=1.

latS = min(flat)-1.
latN = max(flat)+1.
lonW = min(flon)-1.
lonE = max(flon)+1.

dlat =  gridsize
dlon =  gridsize

nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)
ztim = dimsizes(ftime)

lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)

lat@units = "degrees_north"
lon@units = "degrees_east"

count     = new( (/ztim,nlat,mlon/), "float", 1e20)
count!0   = "time"
count!1   = "lat"
count!2   = "lon"
count&time = ftime
count&lat =  lat
count&lon =  lon

printVarSummary(count)

;=================== Count data ==================================

do zz = 0,dimsizes(flat)-1
  print("doing "+zz+" of "+(dimsizes(flat)-1))
  thisLat=flat(zz)
  thisLon=flon(zz)
  count(:,{thisLat},{thisLon})=(/fsnow(:,zz)/)
end do

nscan = 2000             ; usually *much* fewer
eps   = 0.001            ; variable depended
guess = 0                ; use zonal means
relc  = 0.6              ; standard relaxation coef
opt   = 0
gtype = False            ; regional ... not cyclic in lon
poisson_grid_fill( count, gtype, guess, nscan, eps, relc, opt)

countTMP = count
countTMP = countTMP/4.

countnew = linint1_n_Wrap(ftime,countTMP,False,newtime,0,0)

; shiftcountnew
SHIFT=-2
STIXO=SHIFT             ; orig index
ENIXO=dimsizes(newtime)-1-STIXO
STIXS=STIXO-SHIFT   ; index when shifted
ENIXS=ENIXO-SHIFT   

print(STIXO+" "+ENIXO)
print(STIXS+" "+ENIXS)

printVarSummary(newtime)
STIXO=STIXO+2
STIXS=STIXS+2
ENIXO=ENIXO-8
ENIXS=ENIXS-8

countnew(STIXS:ENIXS,:,:)=countnew(STIXO:ENIXO,:,:)
countnew!0="time"
countnew&time=newtime

count_sum = dim_sum_n_Wrap(count({exStDate:exEnDate},:,:),0)
countnew_sum = dim_sum_n_Wrap(countnew({exStDate:exEnDate},:,:),0)

system("/bin/rm -f /glade/scratch/zarzycki/snow/NorAm."+yyyy+".daily.SNOW.gridded.nc")   ; remove any pre-existing file
ncdf = addfile("/glade/scratch/zarzycki/snow/NorAm."+yyyy+".daily.SNOW.gridded.nc" ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(ncdf,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================
ncdf->SNOW=countnew({exStDate:exEnDate},:,:)

ncdf->SUM1=count_sum
ncdf->SUM2=countnew_sum

end


