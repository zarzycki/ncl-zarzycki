begin

; 1029  FILES=`find /global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/ -name "*nc" | sort -n`
; 1030  for f in $FILES; do echo $f; done
;find /global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/ -name "*nc"

;ncl create-freezing-2.ncl 'f="/global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/tgw_wrf_historical_three_hourly_2019-08-27_00_00_00.nc"'

;f="/global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/tgw_wrf_historical_three_hourly_1986-08-20_00_00_00.nc"

basename=systemfunc("basename "+f)
substrings = str_split(basename,"_")
thisdate=substrings(5)

a = addfile(f,"r")

; define constants
g = 9.80665
R = 287.052874
cp = 1004.
P0 = 100000.

; index? -1 gets all times
it = -1

print("Loading data!")
; get WRF vars
ph = wrf_user_getvar(a,"PH",it)
phb = wrf_user_getvar(a,"PHB",it)
p = wrf_user_getvar(a,"P",it)
pb = wrf_user_getvar(a,"PB",it)
qvapor = wrf_user_getvar(a,"QVAPOR",it)
theta = wrf_user_getvar(a,"T",it)
psfc = wrf_user_getvar(a,"PSFC",it)
xlat = wrf_user_getvar(a,"XLAT",it)
xlong = wrf_user_getvar(a,"XLONG",it)
times = wrf_user_getvar(a,"Times",it)
xtime = wrf_user_getvar(a,"XTIME",it)

dims = getvardims(p)        ; dimension names
lev_ix = get1Dindex(dims,"bottom_top")
dim_sizes = dimsizes(p)
nlev = dim_sizes(lev_ix)

; get zint
zint = ph
zint = (ph + phb) / g

; get pmid
pmid = p
pmid = p + pb

; convert to true potential temperature
theta = theta + 300

; convert to temperature
temp = theta
temp = theta * (pmid / P0 ) ^ (R / cp)

print("figuring out pint and zmid")
pint = zint
zmid = pmid
if ( lev_ix .eq. 0 ) then
  pint(0,:,:) = psfc(:,:)
  pint(nlev,:,:) = (/pmid(nlev-1,:,:)/)
  do ii = 0,nlev-1
    zmid(ii,:,:) = (zint(ii,:,:) + zint(ii+1,:,:)) / 2.
    if (ii .ne. 0) then
      pint(ii,:,:) = (pmid(ii,:,:) + pmid(ii-1,:,:)) / 2.
    end if
  end do
else
  pint(:,0,:,:) = psfc(:,:,:)
  pint(:,nlev,:,:) = (/pmid(:,nlev-1,:,:)/)
  do ii = 0,nlev-1
    zmid(:,ii,:,:) = (zint(:,ii,:,:) + zint(:,ii+1,:,:)) / 2.
    if (ii .ne. 0) then
      pint(:,ii,:,:) = (pmid(:,ii,:,:) + pmid(:,ii-1,:,:)) / 2.
    end if
  end do
end if

print("*** writing file")

setfileoption("nc","Format","NetCDF4")
setfileoption("nc","CompressionLevel",1)

outdir="/global/cscratch1/sd/czarzyck/"
system("mkdir -v -p "+outdir)
fileoutput=outdir+"/tgw_"+thisdate+"_00_00_00.nc"
print("Writing file: "+fileoutput)
system("/bin/rm -v -f "+fileoutput)   ; remove any pre-existing file
ncdf = addfile(fileoutput ,"c")  ; open output netCDF file

ntim  = dimsizes(xtime)
klev  = 32
kilev = 33
nlat  = 299
nlon  = 424
nstr  = 19

setfileoption(ncdf,"DefineMode",True)

;===================================================================
; create global attributes of the file
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@source_file   = basename
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; predefine the coordinate variables and their dimensionality
; Note: to get an UNLIMITED record dimension, we set the dimensionality
; to -1 (or the actual size) and set the dimension name to True.
;===================================================================
dimNames = (/"Time", "bottom_top_stag", "south_north", "west_east", "bottom_top", "DateStrLen"/)
dimSizes = (/ -1   ,  kilev, nlat, nlon, klev, nstr /)
dimUnlim = (/ True , False, False, False, False, False/)
filedimdef(ncdf,dimNames,dimSizes,dimUnlim)

;===================================================================
; predefine the the dimensionality of the variables to be written out
;===================================================================
filevardef(ncdf, "Times"  ,typeof(times),getvardims(times))
filevardef(ncdf, "XLAT"   ,typeof(xlat),getvardims(xlat) )
filevardef(ncdf, "XLONG"  ,typeof(xlong),getvardims(xlong))
filevardef(ncdf, "XTIME"  ,typeof(xtime),getvardims(xtime))
filevardef(ncdf, "PSFC"   ,typeof(psfc),getvardims(psfc))
filevardef(ncdf, "PMID"   ,typeof(pmid),getvardims(pmid))
filevardef(ncdf, "PINT"   ,typeof(pint),getvardims(pint))
filevardef(ncdf, "ZMID"   ,typeof(pmid),getvardims(zmid))
filevardef(ncdf, "ZINT"   ,typeof(pint),getvardims(zint))
filevardef(ncdf, "TEMP"   ,typeof(temp),getvardims(temp))
filevardef(ncdf, "QVAPOR" ,typeof(qvapor),getvardims(qvapor))

;===================================================================
; Copy attributes associated with each variable to the file
; All attributes associated with each variable will be copied.
;====================================================================
;filevarattdef(ncdf,"Times" ,times)
filevarattdef(ncdf,"XLAT"  ,xlat)
filevarattdef(ncdf,"XLONG"  ,xlong)
filevarattdef(ncdf,"XTIME"  ,xtime)
filevarattdef(ncdf,"PSFC",psfc)
filevarattdef(ncdf,"PMID",pmid)
filevarattdef(ncdf,"PINT",pint)
filevarattdef(ncdf,"ZMID",pmid)
filevarattdef(ncdf,"ZINT",pint)
filevarattdef(ncdf,"TEMP",temp)
filevarattdef(ncdf,"QVAPOR",qvapor)

;===================================================================
; explicitly exit file definition mode. **NOT REQUIRED**
;===================================================================
setfileoption(ncdf,"DefineMode",False)

;===================================================================
; output only the data values since the dimensionality and such have
; been predefined. The "(/", "/)" syntax tells NCL to only output the
; data values to the predefined locations on the file.
;====================================================================
ncdf->Times  = (/times/)
ncdf->XLAT   = (/xlat/)
ncdf->XLONG  = (/xlong/)
ncdf->XTIME  = (/xtime/)
ncdf->PSFC   = (/psfc/)
ncdf->PMID   = (/pmid/)
ncdf->PINT   = (/pint/)
ncdf->ZMID   = (/zmid/)
ncdf->ZINT   = (/zint/)
ncdf->TEMP   = (/temp/)
ncdf->QVAPOR = (/qvapor/)

print("done writing...")

; compress?
;print("... compressing")
;systemcall="ncks -4 -L 1 -O "+fileoutput+" "+fileoutput
;print(" "+systemcall)
;system(systemcall)
;print("... success!")

end