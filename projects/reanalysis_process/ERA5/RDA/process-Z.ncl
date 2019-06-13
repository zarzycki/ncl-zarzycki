;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;filename="/glade/u/home/zarzycki/rda/ds630.0/e5.oper.an.pl/201601/e5.oper.an.pl.128_129_z.regn320sc.2016012200_2016012223.nc"
outdir="/glade/scratch/zarzycki/ERA5/"
;VARIN="Z"
;VAROUT="Z"

levels=tofloat((/300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 775, 800, 825, 850, 875, 900, 925, 950, 975, 1000/))

f=addfile(filename,"r")

fcst_init=f->time
lat=f->latitude(::-1)
lon=f->longitude

time=tofloat(fcst_init(::6))
time@units=fcst_init@units
time@calendar=fcst_init@calendar

nlat=dimsizes(lat)
nlon=dimsizes(lon)
ntim=dimsizes(time)
nlev=dimsizes(levels)

accumvar=new( (/ntim,nlev,nlat,nlon/), "float")
accumvar!0="time"
accumvar!1="lev"
accumvar!2="lat"
accumvar!3="lon"
accumvar&time=time
accumvar&lev=levels
accumvar&lat=lat
accumvar&lon=lon

linlog=2

do ii = 0,ntim-1
  ix = ind(fcst_init .eq. time(ii))
  varin=f->$VARIN$(ix,:,::-1,:)
  if (VARIN .eq. "Z") then
    varin = varin / 9.80665
  end if
  var = int2p_n(varin&level,varin,levels,linlog,0)
  accumvar(ii,:,:,:)  =(/var/)
  if (ii .eq. 0) then
    ; copy attributes from var on ERA5 file to post-processed file for posterity
    copy_VarAtts(var,accumvar)
  end if
end do

;===================================================================
; Write file
;===================================================================

FIRSTDATE=cd_calendar(time(0),-3)
LASTDATE=cd_calendar(time(ntim-1),-3)
DATES=tostring(FIRSTDATE)+"_"+tostring(LASTDATE)
outname="ERA5."+VAROUT+"."+DATES
outfile=outdir+"/"+outname+".nc"

;===================================================================
; Write file
;===================================================================

system("mkdir -p "+outdir)
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
print("writing....    "+outfile)
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 

ncdf->$VAROUT$  = accumvar           

end
