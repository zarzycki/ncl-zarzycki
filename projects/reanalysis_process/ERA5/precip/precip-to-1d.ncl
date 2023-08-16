;fname = "/glade/collections/rda/data/ds633.0/e5.oper.fc.sfc.meanflux/201303/e5.oper.fc.sfc.meanflux.235_055_mtpr.ll025sc.2013030106_2013031606.nc"
f=addfile(fname,"r")

; get basename, define outdir, create if not existing, define outfile
basename = systemfunc("echo $(basename -- "+fname+")")
outdir = "/glade/scratch/$LOGNAME/ERA5-tmp/"
system("mkdir -p "+outdir)   ; remove any pre-existing file
outfile = outdir+"/"+basename

; get stuff from ERA5 file
var = f->MTPR
inits = f->forecast_initial_time
leads = f->forecast_hour
latitude = f->latitude
longitude = f->longitude
ninits=dimsizes(f->forecast_initial_time)
nleads=dimsizes(f->forecast_hour)
nlat=dimsizes(f->latitude)
nlon=dimsizes(f->longitude)

; define new arrays
ntimes = ninits * nleads
precip_1D = new((/ntimes,nlat,nlon/),typeof(var))
timedim = new(ntimes,typeof(ninits))

; loop and reshape
do ii = 0,ninits-1
  do jj = 0,nleads-1
    ix = ii*nleads + jj
    timedim(ix) = inits(ii) + leads(jj)
    print(ix+" "+timedim(ix))
    precip_1D(ix,:,:) = var(ii,jj,:,:)
  end do
end do

; define coords and atts
timedim!0 = "time"
timedim@units = inits@units

precip_1D!0 = "time"
precip_1D!1 = "latitude"
precip_1D!2 = "longitude"

precip_1D&time = timedim
precip_1D&latitude = latitude
precip_1D&longitude = longitude

copy_VarAtts(var,precip_1D)


; write file

system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@source_file   =  fname
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True)

ncdf->MTPR  = precip_1D
