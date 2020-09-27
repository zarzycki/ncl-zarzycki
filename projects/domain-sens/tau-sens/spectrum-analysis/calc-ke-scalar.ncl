load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;
;  Colin Zarzycki 6/1/17
;  read u,v files, compute KE spectra
;  save data to spectrum.nc for easy plotting later
;  note: U/V must be 2-D (or processed to 2-D on the same level) slices
;  code will read ntimes (left-most dimension) and loop over them.

begin

; Default options =============================================================================
;anlconfig="dtime1800"
;UVARNAME="OMEGA500_MASKI_F"

anlfilename="/glade/scratch/zarzycki/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+anlconfig+"/atm/hist/CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+anlconfig+".cam.h3."+DATE+"-00000.nc_regrid.nc"
specfilename="./spectrum_"+UVARNAME+"_"+anlconfig+".nc"     ;output filename
only_positive=True
overwrite_out=False
;==============================================================================================

; Regrid options =============================================================================
do_regrid=False
regrid_wgts="/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_0.25x0.25_TROPNATL.nc"
;==============================================================================================

; Regional options =============================================================================
do_regional=True     ; if grid is not global (i.e., limited area model or regional subset)
deldeg=0.25           ; horizontal grid spacing in degrees (for wavenumber truncation)
cenLat=20.             ; latitude of center of region -- roughly for scaling wavenumber with cos(lat)

minlat=5.
maxlat=25.
minlon=-70.
maxlon=-10.
;==============================================================================================

; check regional
latRange = maxlat-minlat
lonRange = maxlon-minlon
if (lonRange .lt. 2*latRange) then
  print("lonRange: "+lonRange+" degrees")
  print("latRange: "+latRange+" degrees")
  print("lonRange must be 2x latRange, exiting...")
  exit
end if

; Load lat/lon arrays and get dimension sizes
print(anlfilename+"")
fps = addfile(anlfilename,"r")    ;input file, needs to have time dimension (can be 1)
if (do_regrid)
  tmp = fps->$UVARNAME$
  Opt = True
  tmpregrid = ESMF_regrid_with_weights(tmp,regrid_wgts,Opt)
  printVarSummary(tmpregrid)
  lat = tmpregrid&lat
  lon = tmpregrid&lon
  delete(tmp)
  delete(tmpregrid)
else ; already on lat-lon grid
  lat = fps->lat({minlat:maxlat})
  lon = fps->lon({minlon:maxlon})
end if
nlat = dimsizes(lat)
nlon = dimsizes(lon)
ntimes = dimsizes(fps->time)
print ("ntimes="+ntimes+" nlat x nlon "+nlat+"x"+nlon)

; ==== Allocate new arrays
spc = new ( (/nlat/), "double", 1d-99 )
spc = spc@_FillValue
spc_c=spc
x=spc
n_avg = 0        

spc_vd = new ( (/nlat/), "double", 1d-99 )
spc_vd = spc_vd@_FillValue

spc_uv = new ( (/nlat/), "double", 1d-99 )
spc_uv = spc_uv@_FillValue

spc_save = new ( (/ntimes,nlat/), "double", 1d-99 )
x_save=spc_save
k_save=spc_save

; Loop over all time indices on file to calculate KE spectra
do timeix = 0,ntimes-1
  if (do_regrid)
    utmp = fps->$UVARNAME$(timeix,:)
    Opt = True
    u = ESMF_regrid_with_weights(utmp,regrid_wgts,Opt)
    delete(utmp)
  else
    u = fps->$UVARNAME$(timeix,{minlat:maxlat},{minlon:maxlon})
  end if
  if (only_positive) then
    u = where(u.gt.0.0,u,0.0)
  end if
  print ("dimsizes(u)")
  print (dimsizes(u))

  ;-------------------------------------

  if (do_regional)
    ; Errico 1985 technique
    utmp=u
    var_full=u

    s_j = new ( (/nlat/), typeof(u), 1d-99 )
    s_i = new ( (/nlon/), typeof(u), 1d-99 )

    ; do j dir -> u
    do jj = 1,nlat
      s_j(jj-1) = (u(jj-1,nlon-1) - u(jj-1,0)) / (nlon - 1)
      do ii = 1,nlon
        utmp(jj-1,ii-1) = u(jj-1,ii-1) - 0.5*(2*ii - nlon - 1)*s_j(jj-1)
      end do
    end do

    ; do i dir -> u
    do ii = 1,nlon
      s_i(ii-1) = (utmp(nlat-1,ii-1) - utmp(0,ii-1)) / (nlat - 1)
      do jj = 1,nlat
        var_full(jj-1,ii-1) = utmp(jj-1,ii-1) - 0.5*(2*jj - nlat - 1)*s_i(ii-1)
      end do
    end do

    var=var_full(0:nlat-2,0:nlon-2)
  else
    var  = u
  end if

  print ("u min/max = "+min(var(:,:))+", "+max(var(:,:)) )

  print ("computing vector spherical harmonic transform..")
  ab = shaeC(var(:,:));  ; for equally spaced grid, including both poles
       ; ab = vhagC(var(0,:,:),var2(0,:,:));   ; GAuss grid
  print ("... done. ")
  print (dimsizes(ab))
  ; ab is a 2 x nlat-1 x nlat-1 var
;N = minimum(nlat, (nlon+2)/2) if nlon is even
;N = minimum(nlat, (nlon+1)/2) if nlon is odd 

  cr = ab(0,:,:)                ; real coef  (nlat,nlat)
  ci = ab(1,:,:)                ; imaginary  (nlat,nlat)
  pwr = (cr^2 + ci^2)/2.        ; (nlat,nlat)  array
  ab=0
  printVarSummary(pwr)
  ; power is nlat-1 x nlat-1

  if (do_regional) then
    latminix=2
  else
    latminix=1
  end if

  ; 2d averaging
  do n1=0,nlat-latminix
    spc(n1) = pwr(n1,0)
    do m=1,n1
      ;print(n1+" "+m)
      spc(n1) = spc(n1) + 2.*pwr(n1,m)
    end do
    spc(n1) = 0.5*spc(n1)
    x(n1) = n1
  end do

  pi=3.14159

  if (do_regional)
    ; need to "convert" wavenumbers based on regional lat scaling
    circEarth=40040000. ;m
    dellat=circEarth/(360./deldeg)
    dellon=circEarth/(360./deldeg)*cos(cenLat*pi/180)
    print(dellat+" "+dellon)
    plat=(2*pi/dellat)/(nlat-1)
    plon=(2*pi/dellon)/(nlon-1)
    print(plat+" "+plon)
    if (plat .le. plon) then
      delk=plat
      trunc_n=nlat
    else
      delk=plon
      trunc_n=nlon
    end if
    ;delk=min((/plat,plon/))
    print(delk)
    k = x
    k = x*delk
    maxk = delk*trunc_n/2.
    spc = where(k.ge.maxk,spc@_FillValue,spc)
    ;k = k*1000. ; convert to km
  else
    ; no special processing for k since data already global
  end if

  ; save this timesteps x, spc, k
  x_save(timeix,:) = x
  spc_save(timeix,:) = spc
  if (do_regional) then
    k_save(timeix,:) = k
  end if

  delete(utmp)
end do

; metadata cleanup
x_save!0="time"
x_save!1="band"
copy_VarMeta(x_save,spc_save)
if (do_regional) then
  copy_VarMeta(x_save,k_save)
end if

;-------------------------------------------------------------------------------

doesfileexist=fileexists(specfilename)
if (overwrite_out .eq. True .or. doesfileexist .eq. False) then
  print("Writing new file")
  ;save spectrum data
  system("/bin/rm "+specfilename)           ; remove any pre-existing file
  ncdf     = addfile(specfilename ,"c")  ; open output netCDF file
  ; make time and UNLIMITED dimension      ; recommended  for most applications
  filedimdef(ncdf,"time",-1,True) 
  ncdf->x = x_save
  ncdf->spc = spc_save
  if (do_regional) then
    ncdf->k = k_save
  end if
else  ; we are appending...
  ncdf = addfile(specfilename ,"w")  ; open output netCDF file
  ndims=dimsizes(ncdf->x)
  nfiletimes=ndims(0)
  print ("Append data at new time step.")
  stix=nfiletimes
  enix=(nfiletimes+ntimes-1)
  ncdf->x(stix:enix,:) = (/ x_save(0:(ntimes-1),:) /) 
  ncdf->spc(stix:enix,:) = (/ spc_save(0:(ntimes-1),:) /) 
  if (do_regional) then
    ncdf->k(stix:enix,:) = (/ k_save(0:(ntimes-1),:) /) 
  end if
end if

end
