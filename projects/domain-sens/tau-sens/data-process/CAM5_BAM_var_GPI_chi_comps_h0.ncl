external pcmin_2013 "/glade/work/kareed/MPI_code/pcmin_2013_model_obs_comp.so"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"

begin
; ONLY THINGS THAT NEED TO BE CHANGED
;-----------------------
  diro = "/glade/scratch/zarzycki/"                     ; Output directory
  ;OUTSTRING="tau3600"

  filo = "GPI_"+OUTSTRING+".nc"

  files = systemfunc ("ls /glade/u/home/zarzycki/scratch/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+OUTSTRING+"/atm/hist/CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+OUTSTRING+".cam.h0.????-??.nc_regrid.nc")
;-----------------------
  f     = addfiles (files,"r")
  ListSetType(f,"cat")

  omega = 7.292115e-5
  pi    = 4.0*atan(1.0)

  ;Thermodynamic constants
  CPD    = 1005.7 ;J/kg/K ;heat capacity of dry air
  CPV    = 1870.0 ;J/kg/K heat capacity of water vapr
;      CL=4190.0 ;;J/kg/K ;heat capacity of liquid water
  CL     = 2500.0 ;kJ/kg ;this should be LV at 0 deg-C (???)
  CPVMCL = CPV-CL
  RV     = 461.5  ;J/kg/K, gas constant of water vapor
  RD     = 287.04 ;J/kg/K, gas constant of dry air
  EPS    = RD/RV
  ALV0   = 2.501e6 ;J/kg ;LV at 0 deg-C
  ;LV     = 2.26e6 ;J/kg ;should be a function
  LV     = 2.555e6 ;J/kg from Brian Tang's script citing Bryan (2008)

  P_m = 60000. ;Pa


  ;Common variables
  lev    = f[0]->lev
  lat    = f[0]->lat
  lon    = f[0]->lon
  hyam   = f[0]->hyam
  hybm   = f[0]->hybm

  ;Time dependent variables
  lnmask = f[:]->LANDFRAC
  PS     = f[:]->PS

  print("reading SST...")
  SST = f[:]->TS
  PSL = f[:]->PSL
  T   = f[:]->T(:,::-1,:,:)
  Q   = f[:]->Q(:,::-1,:,:)
  P   = pres_hybrid_ccm(PS,100000.,hyam,hybm)
  print(dimsizes(P))
  P   = P(:,::-1,:,:)
  time = f[:]->time
  print("time steps = "+dimsizes(time))

  PS@_FillValue = default_fillvalue("float")

; Calculate GPI from Emanuel 2010

  print("Components of GPI...")

  print("Saturation deficit...")

  T_h  = f[:]->T
  Q_h  = f[:]->Q
  RH_h = f[:]->RELHUM
  PS1  = f[:]->PS

  T_m  = vinth2p(T_h,hyam,hybm,(/600./),PS1,1,1000.,1,True)
  Q_m  = vinth2p(Q_h,hyam,hybm,(/600./),PS1,1,1000.,1,True)
  RH_m = vinth2p(RH_h,hyam,hybm,(/600./),PS1,1,1000.,1,True)

  P_d_m = P_m*(EPS/(EPS+Q_m))

  ;s_m = CPD*log(T_m)-RD*log(P_m)+LV*Q_m/T_m-RV*Q_m*log(RH_m)
  tmp_s_m = CPD*log(T_m)-RD*log(P_d_m)+LV*Q_m/T_m-RV*Q_m*log(RH_m)
  s_m     = tmp_s_m(:, 0, :, :)

  Q_m_sat   = Q_m/(RH_m/100.)
  P_d_m_sat = P_m*(EPS/(EPS+Q_m_sat))
  ;s_m_sat = CPD*log(T_m)-RD*log(P_m)+LV*Q_m_sat/T_m
  tmp_s_m_sat = CPD*log(T_m)-RD*log(P_d_m_sat)+LV*Q_m_sat/T_m
  s_m_sat = tmp_s_m_sat(:, 0, :, :)

  ;printVarSummary(Q_m_sat)
  ;tmp_var = Q_m_sat/T_m
  ;printVarSummary(tmp_var)
  ;exit

  Q_0_sat = 1000.*EPS*satvpr_temp_fao56(SST, (/1,2/))/PS ;note unit of PS
  ;P_0_sat = PS*(EPS/(EPS+Q_0_sat))
  P_0_sat = PS*(EPS/(where((EPS+Q_0_sat) .gt. 0., (EPS+Q_0_sat), default_fillvalue("float"))))
  s_0_sat = CPD*log(SST)-RD*log(P_0_sat)+LV*Q_0_sat/SST

  ;printVarSummary(s_0_sat)
  ;printVarSummary(s_m_sat)
  chi_m_nom   = s_m_sat - s_m
  chi_m_denom = s_0_sat - s_m_sat
  chi_m       = chi_m_nom/where(chi_m_denom .gt. 0., chi_m_denom, default_fillvalue("float"))

  ;printVarSummary(chi_m)
  ;printMinMax(chi_m, False)
  ;exit

  S_m = PS
  S_m = S_m@_FillValue
  S_m@long_name = "Entropy, 600hPa"
  S_m@units     = ""
  S_m           = tofloat(s_m)

  S_b = PS
  S_b = S_b@_FillValue
  S_b@long_name = "Saturation entropy, 600hPa"
  S_b@units     = ""
  S_b           = tofloat(s_m_sat)

  S_0 = PS
  S_0 = S_0@_FillValue
  S_0@long_name = "Saturation entropy, surface"
  S_0@units     = ""
  S_0           = tofloat(s_0_sat)

  Chi_m = PS
  Chi_m = Chi_m@_FillValue
  Chi_m@long_name = "Saturation entropy deficit"
  Chi_m@units     = ""
  Chi_m           = tofloat(chi_m)

  Chi_m_nom = PS
  Chi_m_nom = Chi_m_nom@_FillValue
  Chi_m_nom@long_name = "Saturation entropy deficit, 600hPa"
  Chi_m_nom@units     = ""
  Chi_m_nom           = tofloat(chi_m_nom)

  Chi_m_denom = PS
  Chi_m_denom = Chi_m_denom@_FillValue
  Chi_m_denom@long_name = "Saturation entropy deficit, surface"
  Chi_m_denom@units     = ""
  Chi_m_denom           = tofloat(chi_m_denom)

  S_m          = where(lnmask .eq. 0, S_m, S_m@_FillValue)
  S_b          = where(lnmask .eq. 0, S_b, S_b@_FillValue)
  S_0          = where(lnmask .eq. 0, S_0, S_0@_FillValue)
  Chi_m        = where(lnmask .eq. 0, Chi_m, Chi_m@_FillValue)
  Chi_m_nom    = where(lnmask .eq. 0, Chi_m_nom, Chi_m_nom@_FillValue)
  Chi_m_denom  = where(lnmask .eq. 0, Chi_m_denom, Chi_m_denom@_FillValue)

  print("Vort...")

  Uh = f[:]->U
  Vh = f[:]->V

  U = vinth2p(Uh,hyam,hybm,(/850.,250./),PS1,1,1000.,1,True)
  V = vinth2p(Vh,hyam,hybm,(/850.,250./),PS1,1,1000.,1,True)

  fcor = PS
  do i=0,dimsizes(time)-1
  do k=0,dimsizes(lon)-1
  fcor(i,:,k) = 2.0*omega*sin(dble2flt(lat(:))*pi/180.0)
  end do
  end do

  vort_r = PS
  vort_r = vort_r@_FillValue
  vort_r@long_name = "Relative Vorticity"
  vort_r@units     = "1/s"
  vort_r = uv2vr_cfd(U(:,0,:,:),V(:,0,:,:),lat,lon,1)

  vort_abs = PS
  vort_abs = vort_abs@_FillValue
  vort_abs@long_name = "Absolute Vorticity"
  vort_abs@units     = "1/s"
  vort_abs = vort_r+fcor

  print("VWS...")

  shear = PS
  shear = shear@_FillValue
  shear@long_name = "Vertical Wind Shear"
  shear@units     = "m/s"
  M = sqrt(U*U+V*V)
  shear = abs(M(:,0,:,:)-M(:,1,:,:))

  vort_r   = where(lnmask .eq. 0, vort_r, vort_r@_FillValue)
  vort_abs = where(lnmask .eq. 0, vort_abs, vort_abs@_FillValue)
  shear    = where(lnmask .eq. 0, shear, shear@_FillValue)


  ; Calculate MPI using Emanuel code
  ; ftp://texmex.mit.edu/pub/emanuel/TCMAX/pcmin_2013.f
  ; Some modifications to get input variables in the correct units for pcmin_2013
    NA  = dimsizes(lev)
    N   = NA
    SST = SST-273.15
    T   = T-273.15
    PSL = PSL/100.
    P   = P/100.
    Q   = Q*1000.

    SST@_FillValue = default_fillvalue("float")
    PMIN = SST
    PMIN = PMIN@_FillValue
    VMAX = SST
    VMAX = VMAX@_FillValue
    VMAX@units = "m/s"
    VMAX@long_name = "Maximum Potential Intensity"
    IFL = floattointeger(SST)
    IFL  = 1

    do i=0,dimsizes(time)-1
    print("... time "+(i+1)+" of "+dimsizes(time))
    do j=0,dimsizes(lat)-1
    ;do j=dimsizes(lat)/4,dimsizes(lat)*3/4
    do k=0,dimsizes(lon)-1
    if (lnmask(0,j,k) .eq. 0) then
    pcmin_2013::PCMIN(SST(i,j,k),PSL(i,j,k),P(i,:,j,k),T(i,:,j,k),Q(i,:,j,k),NA,N,PMIN(i,j,k),VMAX(i,j,k),IFL(i,j,k))
    end if
    end do
    end do
    end do

    print("IFL "+min(IFL))

    ;uniform reduction for 64m
    reduc_coef = (1. + log(10./64.)/log(64./0.0002))
    VMAX       = VMAX*reduc_coef

  MPI = VMAX

  part1 = PS
  part1 = part1@_FillValue
  part2 = PS
  part2 = part2@_FillValue
  part3 = PS
  part3 = part3@_FillValue
  part4 = PS
  part4 = part4@_FillValue
  GPI = PS
  GPI = GPI@_FillValue
  GPI@units = ""
  GPI@long_name = "Genesis Potential Index"

;emanuel 2010 10.3894/JAMES.2010.2.1
  part1 = (abs(vort_abs))^3
  part2 = Chi_m^(-4./3.)
  part3 = (where(MPI .ge. 35., MPI-35., MPI@_FillValue))^2
  part4 = 1./(25.+shear)^4

  GPI = part1*part2*part3*part4

  print(max(MPI))
  print(min(MPI))
  print(max(GPI))
  print(min(GPI))
  print(max(part1))
  print(min(part1))
  print(max(part2))
  print(min(part2))
  print(max(part3))
  print(min(part3))
  print(max(part4))
  print(min(part4))

;===================================================================
; Writing out MPI and GPI to netcdf for analysis
;===================================================================
  ntim  = dimsizes(time)                 ; get dimension sizes
	nlev  = dimsizes(lev)
	nlat  = dimsizes(lat)
	nlon  = dimsizes(lon)

	system("/bin/rm -f " + diro + "/" + filo)    ; remove if exists
	fout  = addfile (diro + filo, "c")  ; open output file

;===================================================================
; explicitly declare file definition mode. Improve efficiency.
;===================================================================
  setfileoption(fout,"DefineMode",True)

;===================================================================
; create global attributes of the file
;===================================================================
  fAtt               = True            ; assign file attributes
	fAtt@title         = "GPI components from monthly averages for AMIP runs"
	fAtt@source_file   = "bam_h0.nc"
	fAtt@Conventions   = "None"
  fAtt@creation_date = systemfunc ("date")
	;fAtt@creation_date = "Wed Jan 17 20:25:48 MST 2018"
	fileattdef( fout, fAtt )            ; copy file attributes

;===================================================================
; predefine the coordinate variables and their dimensionality
; Note: to get an UNLIMITED record dimension, we set the dimensionality
; to -1 (or the actual size) and set the dimension name to True.
;===================================================================
  dimNames = (/"time", "lat", "lon", "lev"/)
	dimSizes = (/ -1   ,  nlat,  nlon, nlev /)
	dimUnlim = (/ True , False, False, False/)
	filedimdef(fout,dimNames,dimSizes,dimUnlim)

;===================================================================
; predefine the the dimensionality of the variables to be written out
;===================================================================
; Here we are using NCL functions to facilitate defining
; each variable's dimension name(s) and type.
; The following could be replaced with explicit, user defined dimension
; names different from those associated with the variable in memory.
; Say, PS(time,lat,lon) in the NCL script. They could be redefined for the file via:
; filevardef(fout, "PS"   ,typeof(PS) ,(/"TIME","latitude","longitude"/))
;===================================================================
   filevardef(fout, "time" ,typeof(time),getvardims(time))
   filevardef(fout, "lev"  ,typeof(lev),getvardims(lev) )
   filevardef(fout, "lat"  ,typeof(lat),getvardims(lat))
   filevardef(fout, "lon"  ,typeof(lon),getvardims(lon))
   filevardef(fout, "GPI"  ,typeof(GPI),getvardims(GPI))
   filevardef(fout, "MPI"  ,typeof(MPI),getvardims(MPI))
   filevardef(fout, "vort_r"  ,typeof(vort_r),getvardims(vort_r))
   filevardef(fout, "vort_abs"  ,typeof(vort_abs),getvardims(vort_abs))
   filevardef(fout, "shear"  ,typeof(shear),getvardims(shear))
   filevardef(fout, "S_m"  ,typeof(S_m),getvardims(S_m))
   filevardef(fout, "S_b"  ,typeof(S_b),getvardims(S_b))
   filevardef(fout, "S_0"  ,typeof(S_0),getvardims(S_0))
   filevardef(fout, "Chi_m",typeof(Chi_m),getvardims(Chi_m))
   filevardef(fout, "Chi_m_nom",typeof(Chi_m_nom),getvardims(Chi_m_nom))
   filevardef(fout, "Chi_m_denom",typeof(Chi_m_denom),getvardims(Chi_m_denom))

;===================================================================
; Copy attributes associated with each variable to the file
; All attributes associated with each variable will be copied.
;====================================================================
   filevarattdef(fout,"time" ,time)                ; copy time attributes
   filevarattdef(fout,"lev"  ,lev)                 ; copy lev attributes
   filevarattdef(fout,"lat"  ,lat)                 ; copy lat attributes
   filevarattdef(fout,"lon"  ,lon)                 ; copy lon attributes
   filevarattdef(fout,"GPI",GPI)                   ; copy GPI attributes
   filevarattdef(fout,"MPI",MPI)                   ; copy MPI attributes
   filevarattdef(fout,"vort_r",vort_r)                   ; copy GPI attributes
   filevarattdef(fout,"vort_abs",vort_abs)                   ; copy GPI attributes
   filevarattdef(fout,"shear",shear)                   ; copy GPI attributes
   filevarattdef(fout,"S_m"  ,S_m)                   ; copy GPI attributes
   filevarattdef(fout,"S_b"  ,S_b)                   ; copy GPI attributes
   filevarattdef(fout,"S_0"  ,S_0)                   ; copy GPI attributes
   filevarattdef(fout,"Chi_m",Chi_m)                   ; copy GPI attributes
   filevarattdef(fout,"Chi_m_nom",Chi_m_nom)                   ; copy GPI attributes
   filevarattdef(fout,"Chi_m_denom",Chi_m_denom)                   ; copy GPI attributes

;===================================================================
; explicitly exit file definition mode. **NOT REQUIRED**
;===================================================================
   setfileoption(fout,"DefineMode",False)

;===================================================================
; output only the data values since the dimensionality and such have
; been predefined. The "(/", "/)" syntax tells NCL to only output the
; data values to the predefined locations on the file.
;====================================================================
   fout->time         = (/time/)
   fout->lev          = (/lev/)
   fout->lat          = (/lat/)
   fout->lon          = (/lon/)
   fout->GPI          = (/GPI/)
   fout->MPI          = (/MPI/)
   fout->vort_r       = (/vort_r/)
   fout->vort_abs     = (/vort_abs/)
   fout->shear        = (/shear/)
   fout->S_m          = (/S_m/)
   fout->S_b          = (/S_b/)
   fout->S_0          = (/S_0/)
   fout->Chi_m        = (/Chi_m/)
   fout->Chi_m_nom    = (/Chi_m_nom/)
   fout->Chi_m_denom  = (/Chi_m_denom/)

   print("Done!")

end

