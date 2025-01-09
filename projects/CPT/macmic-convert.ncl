begin

diri = "./"
fili = systemfunc("cd "+diri+" ; ls b1850.054.Lscale.cam.h1.0001-01-0[1-2]-00000.nc")

f = addfiles (fili, "r")

macmic_steps = 3

mainvars = (/"UPWPSFC","VPWPSFC","WINDBOT","UBOT","VBOT"/)

do zz = 0,dimsizes(mainvars)-1

  mainvar = mainvars(zz)

  do ii = 1,macmic_steps
    getvar = mainvar+"_MACMIC_"+sprinti("%0.2i", ii)
    print(""+getvar)
    var = f[:]->$getvar$
    if (ii .eq. 1) then
      lat = f[0]->lat
      lon = f[0]->lon
      time = f[:]->time
      nlat = dimsizes(lat)
      nlon = dimsizes(lon)
      ntime = dimsizes(time)

      dtime = time(1) - time(0)
      subdtime = dtime / macmic_steps

      start_time = time(0)
      end_time = max(time) + (dtime - subdtime)


      print("start time "+start_time)
      print("end time "+end_time)

      subtime = fspan(start_time,end_time,ntime*macmic_steps)
      copy_VarAtts(time,subtime)
      print(subtime)
      nsubtime = dimsizes(subtime)

      hold_var = new((/ntime*macmic_steps,nlat,nlon/),typeof(var))

      hold_var!0 = "time"
      hold_var!1 = "lat"
      hold_var!2 = "lon"
      hold_var&time = subtime
      hold_var&lat = lat
      hold_var&lon = lon
    end if


    stix = ii-1
    enix = nsubtime-1-(macmic_steps-ii)
    stride = macmic_steps

    print(stix+" "+enix)

    hold_var(stix:enix:stride,:,:) = (/var/)

  end do

  if (zz .eq. 0) then

    system("/bin/rm -f simple.nc")   ; remove any pre-existing file
    ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

    fAtt               = True            ; assign file attributes
    fAtt@title         = "NCL Simple Approach to netCDF Creation"
    fAtt@source_file   =  "original-file.nc"
    fAtt@Conventions   = "None"
    fAtt@creation_date = systemfunc ("date")
    fileattdef( ncdf, fAtt )            ; copy file attributes

    filedimdef(ncdf,"time",-1,True)

  end if

  outvar=mainvar+"_MACMIC"
  ncdf->$outvar$ = hold_var

end do

end
