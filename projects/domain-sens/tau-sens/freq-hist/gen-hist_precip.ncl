;================================================;
load "~/snow-tracking/functions/fcns-extract-storm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/namelist_extract.ncl"
; ================================================;
begin
;*****************************************************************************************************************
;*****************************************************************************************************************

; Pick region for indexing -- for global domain, input:
; -90 -> 90 and 0 -> 360
minlat=5.
maxlat=25.
minlon=-70.
maxlon=-15.
;minlat=-90.
;maxlat=90.
;minlon=-180.
;maxlon=360.

; if conserve_remap is true, NCL will re-bin values from native grid to a lat-lon grid of uniform
; dx/dy spacing defined by gridsize. Typically gridsize is 5.0 in Williamson papers, but can also
; be set to 2.0 or 1.0 for "higher-res" simulations
conserve_remap = False
gridsize = 2.0

nbins=100
nbins10=20

;nlfile="./nl.precip.mp120a"

;*****************************************************************************************************************
;*****************************************************************************************************************

variable = namelist_extract( nlfile, "variable", "string")
scale = namelist_extract( nlfile, "scale", "float")
offset = namelist_extract( nlfile, "offset", "float")
bin_min = namelist_extract( nlfile, "bin_min", "float")
bin_max = namelist_extract( nlfile, "bin_max", "float")
gridname = namelist_extract( nlfile, "gridname", "string")
needs_regrid = namelist_extract( nlfile, "needs_regrid", "logical")
fdir1 = namelist_extract( nlfile, "fdir1", "string")
fnampattern = namelist_extract( nlfile, "fnampattern", "string")
wgt_file = namelist_extract( nlfile, "wgt_file", "string")

fdir1 = str_sub_str(fdir1,"_GRIDNAME",gridname)

print("Variable: "+variable)
print("Doing grid: "+gridname)

;-------------lookup table------------------------------
; Here we build a "lookup" table to find what times are on what files...
;filelist = systemfunc ("find "+fdir1+" -name '"+fnampattern+"' | grep -E '.20(0[3-9]|1[0-2])' | sort -n")
;filelist = systemfunc ("find "+fdir1+" -name '"+fnampattern+"' | sort -n")
filelist = systemfunc ("find "+fdir1+" -name '"+fnampattern+"' | grep -v 1984 | grep -v 1994 | sort -n")

print("Files....")
print(filelist)
timeArr=buildTimeLookup(filelist)
timeArr1D=ndtooned(timeArr)
igood = ind(.not.ismissing(timeArr1D))
onedtime = timeArr1D(igood)

; DEBUG
; if alltimes is true, script will just read all times on data file(s)
; if false, timestart and timestop specify the DIRECT indices in the input[:]
; array we want to extract
alltimes=True
if (alltimes) then
  timestart = 0
  timestop = dimsizes(onedtime)-1
else
  timestart=0
  timestop=3
end if

print("Using grid: "+gridname+"      minlon="+minlon+" maxlon="+maxlon)

loaded_file=""
do ii = 0,timestop
  thisTime=onedtime(ii)
  retlist=getFileAndTimeFromLookup(timeArr,thisTime)
  needed_file=retlist[0]
  trackindex=retlist[1]
  delete(retlist)

  print("Doing index: "+ii+" of "+timestop)
  if (needed_file .ne. loaded_file) then
    ; need to load file
    print("Currently loading... "+needed_file)
    f1 = addfile(needed_file,"r")
    loaded_file=needed_file
  else
    print("existing loaded file... "+loaded_file)
  end if  
  
  ; loop over all times in data
  if (needs_regrid .eq. True) then
    var_se = f1->$variable$(trackindex,:)
    Opt         = True
    vartmp  = ESMF_regrid_with_weights(var_se,wgt_file,Opt)
    delete(var_se)
  else
    tmplat=f1->lat
    if (tmplat(0) .gt. tmplat(dimsizes(tmplat)-1))
      print("lats oriented N->S, need to reverse")
      vartmp  = f1->$variable$(trackindex,::-1,:)
    else
      vartmp  = f1->$variable$(trackindex,:,:)
    end if
  end if

  ;if (any(ismissing(vartmp))) then
  ;  print("WARNING: missing values in input array, being set to zero")
  ;  vartmp = where(ismissing(vartmp),0.,vartmp)
  ;end if

  ; if conserve remap, remap vartmp to new grid, otherwise save RLL grid in array
  if (conserve_remap) then
    if (ii .eq. 0) then
      dlat =  gridsize
      dlon =  gridsize
      latS = -90.
      latN =  90.
      lonW = 0.
      lonE = 360.
      nlat = toint((latN-latS)/dlat) + 1
      nlon = toint((lonE-lonW)/dlon)
      outlat  = fspan(latS, latN, nlat)
      outlon  = fspan(lonW, lonE-dlon, nlon)
      print(outlon)
      outlat@units = "degrees_north"
      outlon@units = "degrees_east"
    end if
    fo = area_conserve_remap_Wrap(vartmp&lon,vartmp&lat,vartmp,outlon,outlat,False)
    fo!0="lat"
    fo!1="lon"
    delete(vartmp)
    vartmp = fo
    delete(fo)
  end if
  
  if (ii .eq. 0) then
    print("SETUP")
    subvar=vartmp({minlat:maxlat},{minlon:maxlon})
    finlat=subvar&lat
    finlon=subvar&lon
    nlat=dimsizes(finlat)
    nlon=dimsizes(finlon)
    var_in = new((/timestop+1,nlat,nlon/),typeof(subvar))
    var_in!0="time"
    var_in!1="lat"
    var_in!2="lon"
    var_in&lat=finlat
    var_in&lon=finlon
    delete([/nlat,nlon,finlat,finlon,subvar/])
  end if   ; end init arrays
  
  var_in(ii,:,:) = (/ vartmp({minlat:maxlat},{minlon:maxlon}) /)
  delete(vartmp)
end do

var = var_in*scale+offset          ; scale and offset
var_reshape = ndtooned(var)    ; reshape to 1D
if (0 .eq. 1) then
  nor   = random_normal(200., 30., dimsizes(var_reshape))  ; normal(10, 100)
  delete(var_reshape)
  var_reshape = nor
  delete(nor)
end if

print("max: "+max(var_reshape)+"   min: "+min(var_reshape))

opt = True
opt@PrintStat = True
statb = stat_dispersion(var_reshape, opt )
print(statb)

opt=True
opt@bin_min=bin_min
opt@bin_max=bin_max
hist   = pdfx(var_reshape, nbins, opt)   ; default is 25
hist10 = pdfx(var_reshape, nbins10, opt)   ; default is 25
hist10!0="x10"

printVarSummary(hist)
printVarSummary(hist10)

; Debug output netcdf
ncdfname="OUT_"+gridname+"_"+variable+".nc"
system("/bin/rm -f "+ncdfname)   ; remove any pre-existing file
ncdf = addfile(ncdfname ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 
;ncdf->$variable$  = var_in

ncdf->hvar_small  = hist
ncdf->hvar_large  = hist10
ncdf->xval_small  = hist@bin_center
ncdf->xval_large  = hist10@bin_center
ncdf->stats = statb

exit

;delete([/hvar_small,hvar_large,xval_small,xval_large/])

;delete([/filelist,timeArr,onedtime,f1,var_in,var,var_reshape,hist,hist10,hist2,hist210,xval,xval10/])

end
