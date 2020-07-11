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
anlfilename="/glade/scratch/zarzycki/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900tau900/atm/hist/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900tau900.cam.h3.1986-01-20-00000.nc"
specfilename="./spectrum_HV.nc"     ;output filename
UVARNAME="U850"
VVARNAME="V850"
overwrite_out=True
;==============================================================================================

; Regrid options =============================================================================
do_regrid=True
regrid_wgts="/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_0.25x0.25_NATL.nc"
;==============================================================================================

; Regional options =============================================================================
do_regional=True     ; if grid is not global (i.e., limited area model or regional subset)
deldeg=0.25           ; horizontal grid spacing in degrees (for wavenumber truncation)
cenLat=25.             ; latitude of center of region -- roughly for scaling wavenumber with cos(lat)
;==============================================================================================

; Load lat/lon arrays and get dimension sizes
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
  lat = fps->lat
  lon = fps->lon
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
    vtmp = fps->$UVARNAME$(timeix,:)
    Opt = True
    u = ESMF_regrid_with_weights(utmp,regrid_wgts,Opt)
    v = ESMF_regrid_with_weights(vtmp,regrid_wgts,Opt)
    delete(utmp)
    delete(vtmp)
  else
    u = fps->$UVARNAME$(timeix,:,:)
    v = fps->$VVARNAME$(timeix,:,:)
  end if
  print ("dimsizes(u)")
  print (dimsizes(u))

  ;-------------------------------------

  if (do_regional)
    ; Errico 1985 technique
    utmp=u
    vtmp=v
    var_full=u
    var2_full=v

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

    ; do j dir -> v
    do jj = 1,nlat
      s_j(jj-1) = (v(jj-1,nlon-1) - v(jj-1,0)) / (nlon - 1)
      do ii = 1,nlon
        vtmp(jj-1,ii-1) = v(jj-1,ii-1) - 0.5*(2*ii - nlon - 1)*s_j(jj-1)
      end do
    end do

    ; do i dir -> v
    do ii = 1,nlon
      s_i(ii-1) = (vtmp(nlat-1,ii-1) - vtmp(0,ii-1)) / (nlat - 1)
      do jj = 1,nlat
        var2_full(jj-1,ii-1) = vtmp(jj-1,ii-1) - 0.5*(2*jj - nlat - 1)*s_i(ii-1)
      end do
    end do

    var=var_full(0:nlat-2,0:nlon-2)
    var2=var2_full(0:nlat-2,0:nlon-2)
  else
    var  = u
    var2 = v
  end if

  print ("u min/max = "+min(var(:,:))+", "+max(var(:,:)) )
  print ("v min/max = "+min(var2(:,:))+", "+max(var2(:,:)) )

  print ("computing vector spherical harmonic transform..")
  ab = vhaeC(var(:,:),var2(:,:));  ; for equally spaced grid, including both poles
       ; ab = vhagC(var(0,:,:),var2(0,:,:));   ; GAuss grid
  print ("... done. ")
  print (dimsizes(ab))

  cr = ab(0,:,:)                ; real coef  (nlat,nlat)
  ci = ab(1,:,:)                ; imaginary  (nlat,nlat)
  pwr = (cr^2 + ci^2)/2.        ; (nlat,nlat)  array
  cr = ab(2,:,:)                ; real coef  (nlat,nlat)
  ci = ab(3,:,:)                ; imaginary  (nlat,nlat)
  pwr = pwr + (cr^2 + ci^2)/2.        ; (nlat,nlat)  array
  ab=0

  if (do_regional) then
    latminix=2
  else
    latminix=1
  end if

  do n1=0,nlat-latminix
    spc(n1) = pwr(n1,0)
    do m=1,n1
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
    ;spc = where(k.ge.maxk,spc@_FillValue,spc)
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
  delete(vtmp)
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