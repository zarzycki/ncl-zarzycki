configs=(/"dtime1800","dtime900","tau3600","tau900","dtime450tau1800","tau3600_lowdmpdz2"/)
nconfig=dimsizes(configs)

varlist=(/"PRECT","PRECC","PRECL","OMEGA500","SHFLX","LHFLX","TMQ","GPI","Chi_m","vort_r","MPI","shear"/)
nvars = dimsizes(varlist)

plotMinLatF             = 2.
plotMaxLatF             = 35.
plotMinLonF             = -100.
plotMaxLonF             = -12.

netcdf_name="climo_avgs.nc"

do zz = 0,nvars-1
  thisvar = varlist(zz) 

  do ii = 0,nconfig-1

    if (thisvar .eq. "PRECL" .or. thisvar .eq. "PRECC" .or. thisvar .eq. "PRECT" .or. thisvar .eq. "SHFLX" .or. thisvar .eq. "TMQ" .or. thisvar .eq. "LHFLX" .or. thisvar .eq. "OMEGA500") then
      fdir1:="/glade/scratch/zarzycki/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+configs(ii)+"/atm/hist/"
      fnampattern:="*cam.h0.19??-[0-1][890]*.nc"
      wgt_file:="/glade/u/home/zarzycki/work/maps/hyperion/map_ne0np4natlanticref.ne30x4_to_1.0x1.0_GLOB.nc"

      filelist := systemfunc ("find "+fdir1+" -name '"+fnampattern+"' | grep -v 1984- | grep -v 1994- | grep -v regrid.nc | sort -n")

      f := addfiles(filelist,"r")
      dsizes := getfiledimsizes(f[0])

      if (thisvar .eq. "PRECT") then
        tmp1:=f[:]->PRECC
        tmp2:=f[:]->PRECL
        PRECC=tmp1
        PRECC=tmp1+tmp2
      else if (thisvar .eq. "OMEGA500") then
        PRECC=f[:]->OMEGA(:,{500.},:)
      else
        PRECC=f[:]->$thisvar$
      end if
      end if

      MASK=f[:]->LANDFRAC
      PRECC=where(MASK .eq. 0, PRECC, PRECC@_FillValue)

      if (thisvar .eq. "PRECL" .or. thisvar .eq. "PRECC" .or. thisvar .eq. "PRECT") then
        PRECC=PRECC*8.64e7
        PRECC@units="mm/day"
      end if

      Opt         = True
      PRECC_rll = ESMF_regrid_with_weights(PRECC,wgt_file,Opt)
      PRECC_avg=dim_avg_n_Wrap(PRECC_rll(:,{plotMinLatF:plotMaxLatF},{plotMinLonF:plotMaxLonF}),0)

      delete(PRECC)
      delete(PRECC_rll)
      delete(Opt)
    else
      f := addfile("../MPI_GPI/GPI_"+configs(ii)+".nc_AVG.nc","r")
      PRECC_avg = f->$thisvar$(0,:,:)
      if (thisvar .eq. "GPI") then
        PRECC_avg = PRECC_avg*4.4e16
        PRECC_avg@units="storms/year"
      end if
      if (thisvar .eq. "vort_r" ) then
        PRECC_avg=PRECC_avg*10^5
        PRECC_avg@units="1e-5 1/s"
      end if
    end if

    if (ii .eq. 0) then
      nlat:=dimsizes(PRECC_avg&lat)
      nlon:=dimsizes(PRECC_avg&lon)
      varArray:=new((/nconfig,nlat,nlon/),typeof(PRECC_avg))
    end if

    varArray(ii,:,:) = PRECC_avg

    delete(PRECC_avg)
  end do

  if (zz .eq. 0) then
    system("/bin/rm -f "+netcdf_name)   ; remove any pre-existing file
    ncdf = addfile(netcdf_name ,"c")  ; open output netCDF file

    fAtt               = True            ; assign file attributes
    fAtt@creation_date = systemfunc ("date")
    fileattdef( ncdf, fAtt )            ; copy file attributes

    configschar=tochar(configs)
    configschar!0="config"
    configschar!1="character"
    ncdf->configs = configschar
    delete(configschar)
  else
    ncdf = addfile(netcdf_name,"w")
  end if

  printVarSummary(varArray(:,{plotMinLatF:plotMaxLatF},{plotMinLonF:plotMaxLonF}))
  varArray!0="config"
  ncdf->$thisvar$  = varArray(:,{plotMinLatF:plotMaxLatF},{plotMinLonF:plotMaxLonF})

end do


