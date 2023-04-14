begin

; 1029  FILES=`find /global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/ -name "*nc" | sort -n`
; 1030  for f in $FILES; do echo $f; done
;find /global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/ -name "*nc"

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

;ix1=20
;ix2=15
;print(pmid(:,ix1,ix2)+"")
;print("--")
;print(pint(:,ix1,ix2)+"")
;printVarSummary(pint)

print("*** writing file")

setfileoption("nc","Format","LargeFile")

outdir="/global/cscratch1/sd/czarzyck/"
system("mkdir -v -p "+outdir)
fileoutput=outdir+"/tgw_"+thisdate+"_00_00_00.nc"
print("Writing file: "+fileoutput)
system("/bin/rm -v -f "+fileoutput)   ; remove any pre-existing file
ncdf = addfile(fileoutput ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@source_file   = basename
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"Time",-1,True)

; write state arrays
print("...ZINT")
ncdf->ZINT  = zint
print("...PMID")
ncdf->PMID  = pmid
;print("...THETA")
;ncdf->THETA  = theta
print("...QVAPOR")
ncdf->QVAPOR = qvapor
print("...TEMP")
ncdf->TEMP = temp
print("...PSFC")
ncdf->PSFC = psfc
print("...PINT")
ncdf->PINT = pint
print("...ZMID")
ncdf->ZMID = zmid

; write coordinate arrays
print("...XLAT")
ncdf->XLAT = xlat
print("...XLONG")
ncdf->XLONG = xlong
print("...Times")
ncdf->Times = times

;https://mailman.ucar.edu/pipermail/wrf-users/2017/004602.html
;z = (PH+PHB)/g  where g is 9.81 m/s2

;https://wiki.openwfm.org/wiki/How_to_interpret_WRF_variables

; WRF user guide
;total geopotential PH + PHB
;total geopotential height in m ( PH + PHB ) / 9.81
;total potential temperature in K T + 300
;total pressure in mb ( P + PB ) * 0.01

; https://mailman.ucar.edu/pipermail/wrf-users/2010/001896.html
; pot. temp. = "normal" temp. * (p_0/p)^kappa
;
; From this: "normal" temp. = pot. temp. * (p/p_0)^kappa
;
; p_0 = 1000 mbar
; p is the pressure in mbar
;
; kappa is the Poisson constant (kappa = R/c_p), the ratio of the gas
; constant R to the specific heat at constant pressure c_p. For dry air
; kappa = 0.2854.


end