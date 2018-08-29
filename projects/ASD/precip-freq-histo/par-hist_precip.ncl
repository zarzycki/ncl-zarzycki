;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/snow-tracking/tracking/fcns-extract-storm.ncl"
; ================================================;
begin
;=================================================;
; open file and read in data
;=================================================;

; if alltimes is true, script will just read all times on data file(s)
; if false, timestart and timestop specify the DIRECT indices in the input[:]
; array we want to extract
alltimes=True
timestart=0
timestop=3
; Pick region for indexing -- for global domain, input:
; -90 -> 90 and 0 -> 360
minlat=24.
maxlat=50.
minlon=234.
maxlon=290.

out_format = "pdf"

; Only turn on for debugging purposes (puts print statements in if debug
; logical checks)
debug = False

; if conserve_remap is true, NCL will re-bin values from native grid
; to a lat-lon grid of uniform dx/dy spacing defined by gridsize
; Typically gridsize is 5.0 in Williamson papers, but can also be set to
; 2.0 or 1.0 for "higher-res" simulations
conserve_remap = True
gridsize = 2.0

variable = "PRECT"        ; variable name
xmin = (/0.0,0.0/)             ; x axis minimums
xmax = (/100.,400./)           ; x axis maximums
ymin = (/1e-7/)                ; y minimum (both panels)
ymax = (/1e0/)                 ; y maximum (both panels)
titles = (/" "," "/)           ; titles
axis_labels = (/"fraction"," "/)               ; y axis labels
colorAll = (/"red3","blue3","pink2","skyblue2"/)      ; line colors

gridlist = (/"mp15a-120a-US","mp120a"/)
physpkg = "CAM6"
nfiles = dimsizes(gridlist)
needs_regrid=True

panels1 = new(2,graphic)

; Input data --------------------------
print("Variable: "+variable)

do file_step=0,nfiles-1  ; dycore loop
print("      File "+file_step)

gridname = gridlist(file_step)
print("Doing grid: "+gridname)

if (gridname .eq. "conus_30_x8") then
  fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp211/atm/hist/"
  wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"
else if (gridname .eq. "ne30") then
  fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16.exp212/atm/hist/"
  wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1reg_patch.nc"
else if (gridname .eq. "mp15a-120a-US") then
  fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp213/atm/hist/"
  wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"
else if (gridname .eq. "mp120a") then
  fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp214/atm/hist/"
  wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp120a_to_1x1reg_patch.nc"
else
  print("Uh, don't have a grid for that!")
  exit
end if
end if
end if
end if

fnam1 = fdir1+"/*.cam.h2.*nc"

;files1 = systemfunc("ls "+fnam1)
;input = addfiles(files1,"r")
;ListSetType(input,"cat")

;-------------lookup table------------------------------

; Here we build a "lookup" table to find what times are on what files...
; get list of h3 files
filelist = systemfunc ("ls "+fnam1)
timeArr=buildTimeLookup(filelist)
timeArr1D=ndtooned(timeArr)
igood = ind(.not.ismissing(timeArr1D))
onedtime = timeArr1D(igood)

if (alltimes) then
  timestart = 0
  timestop = dimsizes(onedtime)-1
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
    vartmp  = f1->$variable$(trackindex,:,:)
  end if
  
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
    var_in = new((/timestop+1,nlat,nlon/),"float")
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

var = var_in*86400000          ; convert to mm/day
var_reshape = ndtooned(var)    ; reshape to 1D
if (debug) then
  nor   = random_normal(200., 30., dimsizes(var_reshape))  ; normal(10, 100)
  delete(var_reshape)
  var_reshape = nor
  delete(nor)
end if
hist_size = floattointeger(ceil(max(var_reshape)))  ; find max bin size 
printMinMax(var_reshape,True)
print("Number of samples: "+dimsizes(var_reshape))
print("Histsize is "+hist_size)
hist = new(hist_size,float)
hist10 = new(floattointeger(ceil(hist_size/10.)),float)

; set initial histogram values to zero
do i = 0,dimsizes(hist) - 1
  hist(i) = 0.0
end do
do i = 0,dimsizes(hist10) - 1
  hist10(i) = 0.0
end do

; bin precipitation data, excluding negative values
do i = 0,dimsizes(var_reshape)-1
  tmp = floattointeger(floor(var_reshape(i)))
  tmp10 = floattointeger(floor(var_reshape(i)/10))
  if (tmp .ge. 0.0) then
      ;if mod(i,10) .eq. 0 then
      ;  print(" "+tmp+"  "+tmp10)
      ;end if
      hist(tmp) = hist(tmp) + 1
      hist10(tmp10) = hist10(tmp10) + 1
;;; Uncomment out the below to stick negative and zero values in first
;;; histogram box
;      else
;          hist(0) = hist(0) + 1
  end if
end do

;printVarSummary(hist)
;printVarSummary(hist10)
;   do i = 0,dimsizes(hist)-10,10
;      if (i+10 .lt. dimsizes(hist)) then
;      do j = i,i+10
;         hist10(i/10) = hist10(i/10) + hist(j)
;      end do
;      else
;      do j = i,dimsizes(hist)-1
;         hist10(i/10) = hist10(i/10) + hist(j)
;      end do
;      end if
;   end do

print(sum(hist))
;print("  ")
print(sum(hist10))

hist2 = new(2*dimsizes(hist)-2,float)
hist210 = new(floattointeger(ceil(2*(dimsizes(hist10)))),float)
xval = new(dimsizes(hist2),integer)
xval10 = new(dimsizes(hist210),integer)

; create arrays for plotting
tmp = 0
do i = 0,dimsizes(hist2)-2,2
  hist2(i) = hist(i/2)
  hist2(i+1) = hist(i/2)
  xval(i) = tmp
  xval(i+1) = tmp+1
  tmp = tmp + 1
end do

tmp = 0
do i = 0,dimsizes(hist210)-2,2
  hist210(i) = hist10(i/2)
  hist210(i+1) = hist10(i/2)
  xval10(i) = tmp*10
  xval10(i+1) = (tmp+1)*10
  tmp = tmp + 1
end do

; reset all zeros to fill value
do j = 0,dimsizes(hist2)-1
  if (hist2(j) .eq. 0) then
    hist2(j) = hist2@_FillValue
  end if
end do
do j = 0,dimsizes(hist210)-1
  if (hist210(j) .eq. 0) then
    hist210(j) = hist210@_FillValue
  end if
end do

print(xval+" "+(hist2/sum(hist)))
print(xval10+" "+(hist210/sum(hist)))

; Debug output netcdf
ncdfname="OUT_"+gridname+".nc"
system("/bin/rm -f "+ncdfname)   ; remove any pre-existing file
ncdf = addfile(ncdfname ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 
ncdf->$variable$  = var_in

hvar_small  = hist2/sum(hist)
hvar_large  = hist210/sum(hist)
xval_small  = xval
xval_large  = xval10
xval_small!0="bin_sm"
xval_large!0="bin_lg"
xval_small&bin_sm=xval_small
xval_large&bin_lg=xval_large
copy_VarMeta(xval_small,hvar_small)
copy_VarMeta(xval_large,hvar_large)
hvar_small@_FillValue=hist2@_FillValue
hvar_large@_FillValue=hist210@_FillValue


ncdf->hvar_small  = hvar_small
ncdf->hvar_large  = hvar_large
ncdf->xval_small  = xval_small
ncdf->xval_large  = xval_large

delete([/hvar_small,hvar_large,xval_small,xval_large/])

delete([/filelist,timeArr,onedtime,f1,var_in,var,var_reshape,hist,hist10,hist2,hist210,xval,xval10/])

end do   ; dycore loop

end
