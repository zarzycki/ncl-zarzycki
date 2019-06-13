;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;filename="/glade/u/home/zarzycki/rda/ds630.0/e5.oper.an.sfc/201601/e5.oper.an.sfc.128_151_msl.regn320sc.2016010100_2016013123.nc"
outdir="/glade/scratch/zarzycki/ERA5/"
;VARIN="MSL"
;VAROUT="PSL"

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

accumvar=new( (/ntim,nlat,nlon/), "float")
accumvar!0="time"
accumvar!1="lat"
accumvar!2="lon"
accumvar&time=time
accumvar&lat=lat
accumvar&lon=lon

do ii = 0,ntim-1
  ix = ind(fcst_init .eq. time(ii))
  var=f->$VARIN$(ix,::-1,:)
  accumvar(ii,:,:)  =(/var/)
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

ncdf->PSL  = accumvar           

end
