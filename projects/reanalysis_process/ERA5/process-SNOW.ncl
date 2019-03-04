;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

;filename="/glade/u/home/zarzycki/rda/ds630.0/e5.oper.fc.sfc.accumu/201601/e5.oper.fc.sfc.accumu.128_144_sf.regn320sc.2016011606_2016020112.nc"
outdir="/glade/scratch/zarzycki/ERA5/"

; figure out output naming convention
basename=systemfunc("basename "+filename)
basename = str_sub_str(basename,"128_144_sf.regn320sc","6hr.PRECT_SNOW")
outfile=outdir+"/"+basename

f=addfile(filename,"r")

fcst_init=f->forecast_initial_time
lat=f->latitude
lon=f->longitude

timedelta=6.   ; 6 hourly data
mininittime=tofloat(min(fcst_init))
maxinittime=tofloat(max(fcst_init))

minaccumtime=mininittime+timedelta
maxaccumtime=maxinittime+(timedelta*2)
ntimes=(maxaccumtime-minaccumtime)/timedelta + 1
time=fspan(minaccumtime,maxaccumtime,toint(ntimes))

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

do ii = 0,dimsizes(fcst_init)-1
  var=f->SF(ii,0:11,:,:)
  accumvar(2*ii,:,:)  =(/dim_sum_n_Wrap(var(0:5,:,:),0)/)
  accumvar(2*ii+1,:,:)=(/dim_sum_n_Wrap(var(6:11,:,:),0)/)
  if (ii .eq. 0) then
    ; copy attributes from var on ERA5 file to post-processed file for posterity
    copy_VarAtts(var,accumvar)
  end if
end do


;===================================================================
; Write file
;===================================================================

system("mkdir -p "+outdir)
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 

ncdf->SNOW  = accumvar           

end
