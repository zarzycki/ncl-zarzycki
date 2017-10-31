load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

climoFile=addfile("/glade/p/cesmdata/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029.nc","r")
sstFile=addfile("/glade/u/home/zarzycki/work/NOAAOI/sst.day.mean.2013.v2.nc","r")

minlat=5.5
maxlat=23.5
minlon=302.5
maxlon=345

SST=short2flt(sstFile->sst)
ndims = dimsizes(SST)
ntim = ndims(0)
nlat = ndims(1)
nlon = ndims(2)

if (ntim .eq. 366) then
daysInMonth=(/31,29,31,30,31,30,31,31,30,31,30,31/)
else
daysInMonth=(/31,28,31,30,31,30,31,31,30,31,30,31/)
end if
;print(sum(daysInMonth))

;printVarSummary(SST)

monthlyAvg = new((/12,nlat,nlon/),"float")

stday=0
do i = 0,11
  ndays = daysInMonth(i)
  enday = stday+ndays-1
  monthVar = SST(stday:enday,:,:)
  monthlyAvg(i,:,:) = dim_avg_n_Wrap(monthVar,0)
  stday = enday+1
  delete(monthVar)
end do

;printVarSummary(monthlyAvg)

climoSST = climoFile->SST_cpl
printVarSummary(climoSST)
climoSSTregrid = area_conserve_remap_Wrap (climoSST&lon,climoSST&lat,climoSST,SST&lon,SST&lat,False)
printVarSummary(climoSSTregrid)

subOBS=monthlyAvg(:,{minlat:maxlat},{minlon:maxlon})
subCLIMO=climoSSTregrid(:,{minlat:maxlat},{minlon:maxlon})

TNAobs = dim_avg_n_Wrap(dim_avg_n_Wrap(subOBS,1),1)
TNAclimo = dim_avg_n_Wrap(dim_avg_n_Wrap(subCLIMO,1),1)

print(TNAobs)
print(TNAclimo)
print("----------------------")
print(TNAobs-TNAclimo)

;=================================================================

system("/bin/rm -f /glade/scratch/zarzycki/monthlyNOAAOIsst.nc")   ; remove any pre-existing file
ncdf = addfile("/glade/scratch/zarzycki/monthlyNOAAOIsst.nc" ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->SST  = monthlyAvg                          ; 4D  
ncdf->CLIMO =      climoSSTregrid        

end
